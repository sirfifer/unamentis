//! Rotary Position Embeddings (RoPE)

use candle_core::{Device, Result, Tensor};

/// Rotary Position Embedding
#[derive(Debug, Clone)]
pub struct RotaryEmbedding {
    cos_cache: Tensor,
    sin_cache: Tensor,
    dim: usize,
    max_seq_len: usize,
}

impl RotaryEmbedding {
    pub fn new(dim: usize, max_seq_len: usize, base: f32, device: &Device) -> Result<Self> {
        let inv_freq = Self::compute_inv_freq(dim, base, device)?;
        let (cos_cache, sin_cache) = Self::compute_cache(&inv_freq, max_seq_len)?;

        Ok(Self {
            cos_cache,
            sin_cache,
            dim,
            max_seq_len,
        })
    }

    fn compute_inv_freq(dim: usize, base: f32, device: &Device) -> Result<Tensor> {
        let half_dim = dim / 2;
        let inv_freq: Vec<f32> = (0..half_dim)
            .map(|i| 1.0 / base.powf(2.0 * i as f32 / dim as f32))
            .collect();

        Tensor::from_vec(inv_freq, (half_dim,), device)
    }

    fn compute_cache(inv_freq: &Tensor, max_seq_len: usize) -> Result<(Tensor, Tensor)> {
        let device = inv_freq.device();
        let positions: Vec<f32> = (0..max_seq_len).map(|i| i as f32).collect();
        let positions = Tensor::from_vec(positions, (max_seq_len, 1), device)?;

        // Outer product: positions @ inv_freq.T -> [max_seq_len, half_dim]
        let freqs = positions.matmul(&inv_freq.unsqueeze(0)?)?;

        // cos/sin have shape [seq, half_dim] - NOT doubled
        let cos_cache = freqs.cos()?;
        let sin_cache = freqs.sin()?;

        Ok((cos_cache, sin_cache))
    }

    /// Apply rotary embeddings to query and key tensors
    /// Input shape: [batch, seq, num_heads, head_dim]
    pub fn forward(&self, q: &Tensor, k: &Tensor, offset: usize) -> Result<(Tensor, Tensor)> {
        let seq_len = q.dim(1)?;
        let end = offset + seq_len;

        if end > self.max_seq_len {
            return Err(candle_core::Error::Msg(format!(
                "Sequence length {} exceeds max {}",
                end, self.max_seq_len
            )));
        }

        // cos/sin have shape [seq, half_dim]
        let cos = self.cos_cache.narrow(0, offset, seq_len)?;
        let sin = self.sin_cache.narrow(0, offset, seq_len)?;

        let q_rotated = self.apply_rotary(q, &cos, &sin)?;
        let k_rotated = self.apply_rotary(k, &cos, &sin)?;

        Ok((q_rotated, k_rotated))
    }

    fn apply_rotary(&self, x: &Tensor, cos: &Tensor, sin: &Tensor) -> Result<Tensor> {
        let half_dim = self.dim / 2;

        // x has shape [batch, seq, heads, head_dim]
        // Split into two halves along last dimension
        let x1 = x.narrow(candle_core::D::Minus1, 0, half_dim)?;
        let x2 = x.narrow(candle_core::D::Minus1, half_dim, half_dim)?;

        // cos/sin have shape [seq, half_dim]
        // Reshape to [1, seq, 1, half_dim] for broadcasting with [batch, seq, heads, half_dim]
        let cos = cos.unsqueeze(0)?.unsqueeze(2)?;
        let sin = sin.unsqueeze(0)?.unsqueeze(2)?;

        // Rotate: [x1, x2] -> [x1*cos - x2*sin, x1*sin + x2*cos]
        let rotated_x1 = (x1.broadcast_mul(&cos)? - x2.broadcast_mul(&sin)?)?;
        let rotated_x2 = (x1.broadcast_mul(&sin)? + x2.broadcast_mul(&cos)?)?;

        Tensor::cat(&[&rotated_x1, &rotated_x2], candle_core::D::Minus1)
    }
}
