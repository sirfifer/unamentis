//! FlowLM Transformer for Pocket TTS
//!
//! 6-layer transformer backbone that generates latent representations
//! from text tokens and voice embeddings.

use candle_core::{Device, Result, Tensor};
use candle_nn::{Module, VarBuilder};

use crate::modules::{
    attention::{KVCache, MultiHeadAttention},
    embeddings::{TextEmbedding, VoiceEmbedding},
    layer_norm::RMSNorm,
    mlp::GatedMLP,
    rotary::RotaryEmbedding,
};

/// FlowLM configuration
#[derive(Debug, Clone)]
pub struct FlowLMConfig {
    pub vocab_size: usize,
    pub hidden_size: usize,
    pub intermediate_size: usize,
    pub num_layers: usize,
    pub num_heads: usize,
    pub max_seq_len: usize,
    pub rope_base: f32,
    pub rms_norm_eps: f64,
    pub latent_dim: usize,
}

impl Default for FlowLMConfig {
    fn default() -> Self {
        Self {
            vocab_size: 32000,
            hidden_size: 1024,
            intermediate_size: 4096,
            num_layers: 6,
            num_heads: 16,
            max_seq_len: 2048,
            rope_base: 10000.0,
            rms_norm_eps: 1e-6,
            latent_dim: 32,
        }
    }
}

/// Single transformer layer
#[derive(Debug)]
struct TransformerLayer {
    attn: MultiHeadAttention,
    mlp: GatedMLP,
    input_norm: RMSNorm,
    post_attn_norm: RMSNorm,
}

impl TransformerLayer {
    fn new(config: &FlowLMConfig, vb: VarBuilder) -> Result<Self> {
        let attn = MultiHeadAttention::new(
            config.hidden_size,
            config.num_heads,
            vb.pp("self_attn"),
        )?;

        let mlp = GatedMLP::new(
            config.hidden_size,
            config.intermediate_size,
            vb.pp("mlp"),
        )?;

        let input_norm = RMSNorm::new(
            config.hidden_size,
            config.rms_norm_eps,
            vb.pp("input_layernorm"),
        )?;

        let post_attn_norm = RMSNorm::new(
            config.hidden_size,
            config.rms_norm_eps,
            vb.pp("post_attention_layernorm"),
        )?;

        Ok(Self {
            attn,
            mlp,
            input_norm,
            post_attn_norm,
        })
    }

    fn forward(
        &self,
        x: &Tensor,
        rotary: &RotaryEmbedding,
        kv_cache: Option<&mut KVCache>,
    ) -> Result<Tensor> {
        // Pre-norm attention
        let residual = x;
        let x = self.input_norm.forward(x)?;
        let x = self.attn.forward(&x, Some(rotary), kv_cache, true)?;
        let x = (residual + x)?;

        // Pre-norm MLP
        let residual = &x;
        let x = self.post_attn_norm.forward(&x)?;
        let x = self.mlp.forward(&x)?;
        residual + x
    }
}

/// FlowLM Transformer
#[derive(Debug)]
pub struct FlowLM {
    config: FlowLMConfig,
    text_embedding: TextEmbedding,
    layers: Vec<TransformerLayer>,
    final_norm: RMSNorm,
    latent_proj: candle_nn::Linear,
    rotary: RotaryEmbedding,
    kv_caches: Vec<KVCache>,
}

impl FlowLM {
    pub fn new(config: FlowLMConfig, vb: VarBuilder, device: &Device) -> Result<Self> {
        let text_embedding = TextEmbedding::new(
            config.vocab_size,
            config.hidden_size,
            vb.pp("embed_tokens"),
        )?;

        let mut layers = Vec::with_capacity(config.num_layers);
        for i in 0..config.num_layers {
            layers.push(TransformerLayer::new(&config, vb.pp(format!("layers.{}", i)))?);
        }

        let final_norm = RMSNorm::new(
            config.hidden_size,
            config.rms_norm_eps,
            vb.pp("norm"),
        )?;

        let latent_proj = candle_nn::linear(
            config.hidden_size,
            config.latent_dim,
            vb.pp("latent_proj"),
        )?;

        let head_dim = config.hidden_size / config.num_heads;
        let rotary = RotaryEmbedding::new(
            head_dim,
            config.max_seq_len,
            config.rope_base,
            device,
        )?;

        let kv_caches = (0..config.num_layers).map(|_| KVCache::new()).collect();

        Ok(Self {
            config,
            text_embedding,
            layers,
            final_norm,
            latent_proj,
            rotary,
            kv_caches,
        })
    }

    /// Forward pass with optional voice conditioning
    pub fn forward(
        &mut self,
        token_ids: &Tensor,
        voice_embedding: Option<&VoiceEmbedding>,
        use_cache: bool,
    ) -> Result<Tensor> {
        // Get text embeddings
        let mut hidden = self.text_embedding.forward(token_ids)?;

        // Add voice conditioning if provided
        if let Some(voice) = voice_embedding {
            let (batch_size, seq_len, _) = hidden.dims3()?;
            let voice_expanded = voice.expand_to_seq(batch_size, seq_len)?;
            hidden = (hidden + voice_expanded)?;
        }

        // Pass through transformer layers
        for (i, layer) in self.layers.iter().enumerate() {
            let cache = if use_cache {
                Some(&mut self.kv_caches[i])
            } else {
                None
            };
            hidden = layer.forward(&hidden, &self.rotary, cache)?;
        }

        // Final norm and project to latent space
        let hidden = self.final_norm.forward(&hidden)?;
        self.latent_proj.forward(&hidden)
    }

    /// Reset KV caches for new sequence
    pub fn reset_cache(&mut self) {
        for cache in &mut self.kv_caches {
            cache.clear();
        }
    }

    /// Get current cache sequence length
    pub fn cache_seq_len(&self) -> usize {
        self.kv_caches.first().map(|c| c.seq_len()).unwrap_or(0)
    }

    pub fn config(&self) -> &FlowLMConfig {
        &self.config
    }
}
