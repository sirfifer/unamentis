//! Mimi VAE Decoder
//!
//! Neural audio codec decoder that converts quantized latents
//! to high-quality 24kHz audio.

use candle_core::{Result, Tensor};
use candle_nn::{Module, VarBuilder};

use super::seanet::{SEANetConfig, SEANetDecoder};

/// Mimi decoder configuration
#[derive(Debug, Clone)]
pub struct MimiConfig {
    pub latent_dim: usize,
    pub mimi_dim: usize,
    pub sample_rate: usize,
    pub frame_rate: f32,
    pub seanet_config: SEANetConfig,
}

impl Default for MimiConfig {
    fn default() -> Self {
        Self {
            latent_dim: 32,
            mimi_dim: 512,
            sample_rate: 24000,
            frame_rate: 12.5,
            seanet_config: SEANetConfig::default(),
        }
    }
}

/// Mimi VAE Decoder
///
/// Converts low-dimensional latents from FlowLM to audio waveforms.
/// Uses a learned projection followed by SEANet for upsampling.
#[derive(Debug)]
pub struct MimiDecoder {
    config: MimiConfig,
    latent_proj: candle_nn::Linear,
    seanet: SEANetDecoder,
}

impl MimiDecoder {
    pub fn new(config: MimiConfig, vb: VarBuilder) -> Result<Self> {
        // Project from FlowLM latent dim to Mimi internal dim
        let latent_proj = candle_nn::linear(
            config.latent_dim,
            config.mimi_dim,
            vb.pp("latent_proj"),
        )?;

        // SEANet decoder for waveform generation
        let mut seanet_config = config.seanet_config.clone();
        seanet_config.latent_dim = config.mimi_dim;
        let seanet = SEANetDecoder::new(seanet_config, vb.pp("decoder"))?;

        Ok(Self {
            config,
            latent_proj,
            seanet,
        })
    }

    /// Decode latents to audio waveform
    ///
    /// Input: [batch, seq, latent_dim] latent representations
    /// Output: [batch, samples] audio waveform
    pub fn forward(&self, latents: &Tensor) -> Result<Tensor> {
        // Project to Mimi dimension
        let projected = self.latent_proj.forward(latents)?;

        // Decode to waveform
        self.seanet.forward(&projected)
    }

    /// Decode with overlap-add for streaming
    ///
    /// Used for low-latency streaming synthesis where we process
    /// chunks and blend them together.
    pub fn decode_streaming(
        &self,
        latents: &Tensor,
        overlap_samples: usize,
        previous_tail: Option<&Tensor>,
    ) -> Result<(Tensor, Tensor)> {
        // Decode full chunk
        let audio = self.forward(latents)?;

        let total_samples = audio.dim(1)?;

        if let Some(prev) = previous_tail {
            // Crossfade with previous chunk
            let prev_len = prev.dim(0)?;
            let fade_len = overlap_samples.min(prev_len).min(total_samples);

            if fade_len > 0 {
                // Create fade curves
                let fade_out: Vec<f32> = (0..fade_len)
                    .map(|i| 1.0 - (i as f32 / fade_len as f32))
                    .collect();
                let fade_in: Vec<f32> = (0..fade_len)
                    .map(|i| i as f32 / fade_len as f32)
                    .collect();

                let fade_out = Tensor::from_vec(fade_out, (fade_len,), audio.device())?;
                let fade_in = Tensor::from_vec(fade_in, (fade_len,), audio.device())?;

                // Apply crossfade
                let prev_overlap = prev.narrow(0, prev_len - fade_len, fade_len)?;
                let curr_overlap = audio.narrow(1, 0, fade_len)?.squeeze(0)?;

                let blended = (prev_overlap.broadcast_mul(&fade_out)?
                    + curr_overlap.broadcast_mul(&fade_in)?)?;

                // Construct output: blended + rest of current
                let rest = audio.narrow(1, fade_len, total_samples - fade_len)?;
                let output = Tensor::cat(&[&blended.unsqueeze(0)?, &rest], 1)?;

                // Save tail for next chunk
                let tail_start = total_samples.saturating_sub(overlap_samples);
                let tail = audio.narrow(1, tail_start, total_samples - tail_start)?.squeeze(0)?;

                Ok((output, tail))
            } else {
                let tail = audio.narrow(1, total_samples - overlap_samples, overlap_samples)?.squeeze(0)?;
                Ok((audio, tail))
            }
        } else {
            // First chunk, just save tail
            let tail_start = total_samples.saturating_sub(overlap_samples);
            let tail = audio.narrow(1, tail_start, total_samples - tail_start)?.squeeze(0)?;
            Ok((audio, tail))
        }
    }

    /// Get samples per latent frame
    pub fn samples_per_frame(&self) -> usize {
        (self.config.sample_rate as f32 / self.config.frame_rate) as usize
    }

    pub fn config(&self) -> &MimiConfig {
        &self.config
    }

    pub fn sample_rate(&self) -> usize {
        self.config.sample_rate
    }
}
