//! Multi-head attention modules
//!
//! Portions of this file derived from:
//! https://github.com/babybirdprd/pocket-tts
//! Licensed under MIT

use candle_core::{Device, Result, Tensor};
use candle_nn::{Linear, Module, VarBuilder};

use super::rotary::RotaryEmbedding;

/// Multi-Head Attention with optional KV caching
#[derive(Debug)]
pub struct MultiHeadAttention {
    q_proj: Linear,
    k_proj: Linear,
    v_proj: Linear,
    o_proj: Linear,
    num_heads: usize,
    head_dim: usize,
    scale: f32,
}

impl MultiHeadAttention {
    pub fn new(
        hidden_size: usize,
        num_heads: usize,
        vb: VarBuilder,
    ) -> Result<Self> {
        let head_dim = hidden_size / num_heads;

        let q_proj = candle_nn::linear(hidden_size, hidden_size, vb.pp("q_proj"))?;
        let k_proj = candle_nn::linear(hidden_size, hidden_size, vb.pp("k_proj"))?;
        let v_proj = candle_nn::linear(hidden_size, hidden_size, vb.pp("v_proj"))?;
        let o_proj = candle_nn::linear(hidden_size, hidden_size, vb.pp("o_proj"))?;

        Ok(Self {
            q_proj,
            k_proj,
            v_proj,
            o_proj,
            num_heads,
            head_dim,
            scale: 1.0 / (head_dim as f32).sqrt(),
        })
    }

    pub fn forward(
        &self,
        x: &Tensor,
        rotary: Option<&RotaryEmbedding>,
        kv_cache: Option<&mut KVCache>,
        causal_mask: bool,
    ) -> Result<Tensor> {
        let (batch_size, seq_len, _) = x.dims3()?;

        // Project to Q, K, V
        let q = self.q_proj.forward(x)?;
        let k = self.k_proj.forward(x)?;
        let v = self.v_proj.forward(x)?;

        // Reshape to multi-head format: [batch, seq, num_heads, head_dim]
        let q = q.reshape((batch_size, seq_len, self.num_heads, self.head_dim))?;
        let k = k.reshape((batch_size, seq_len, self.num_heads, self.head_dim))?;
        let v = v.reshape((batch_size, seq_len, self.num_heads, self.head_dim))?;

        // Transpose to [batch, num_heads, seq, head_dim]
        let q = q.transpose(1, 2)?;
        let k = k.transpose(1, 2)?;
        let v = v.transpose(1, 2)?;

        // Apply rotary embeddings if provided
        let (q, k) = if let Some(rope) = rotary {
            let offset = kv_cache.as_ref().map(|c| c.seq_len()).unwrap_or(0);
            rope.forward(&q, &k, offset)?
        } else {
            (q, k)
        };

        // Update KV cache if provided
        let (k, v) = if let Some(cache) = kv_cache {
            cache.update(k, v)?
        } else {
            (k, v)
        };

        // Attention scores: Q @ K^T
        let attn_weights = q.matmul(&k.transpose(2, 3)?)?;
        let attn_weights = (attn_weights * self.scale as f64)?;

        // Apply causal mask if needed
        let attn_weights = if causal_mask {
            let mask = self.create_causal_mask(seq_len, k.dim(2)?, x.device())?;
            attn_weights.broadcast_add(&mask)?
        } else {
            attn_weights
        };

        // Softmax
        let attn_weights = candle_nn::ops::softmax(&attn_weights, candle_core::D::Minus1)?;

        // Weighted sum of values
        let attn_output = attn_weights.matmul(&v)?;

        // Reshape back: [batch, num_heads, seq, head_dim] -> [batch, seq, hidden]
        let attn_output = attn_output
            .transpose(1, 2)?
            .reshape((batch_size, seq_len, self.num_heads * self.head_dim))?;

        // Output projection
        self.o_proj.forward(&attn_output)
    }

    fn create_causal_mask(&self, q_len: usize, kv_len: usize, device: &Device) -> Result<Tensor> {
        let mask: Vec<f32> = (0..q_len)
            .flat_map(|i| {
                (0..kv_len).map(move |j| {
                    if j <= i + (kv_len - q_len) {
                        0.0
                    } else {
                        f32::NEG_INFINITY
                    }
                })
            })
            .collect();

        Tensor::from_vec(mask, (1, 1, q_len, kv_len), device)
    }
}

/// KV Cache for efficient autoregressive generation
#[derive(Debug)]
pub struct KVCache {
    k_cache: Option<Tensor>,
    v_cache: Option<Tensor>,
}

impl KVCache {
    pub fn new() -> Self {
        Self {
            k_cache: None,
            v_cache: None,
        }
    }

    pub fn seq_len(&self) -> usize {
        self.k_cache.as_ref().map(|k| k.dim(2).unwrap_or(0)).unwrap_or(0)
    }

    pub fn update(&mut self, k: Tensor, v: Tensor) -> Result<(Tensor, Tensor)> {
        let (k_out, v_out) = match (&self.k_cache, &self.v_cache) {
            (Some(k_cache), Some(v_cache)) => {
                let k_new = Tensor::cat(&[k_cache, &k], 2)?;
                let v_new = Tensor::cat(&[v_cache, &v], 2)?;
                (k_new, v_new)
            }
            _ => (k, v),
        };

        self.k_cache = Some(k_out.clone());
        self.v_cache = Some(v_out.clone());

        Ok((k_out, v_out))
    }

    pub fn clear(&mut self) {
        self.k_cache = None;
        self.v_cache = None;
    }
}

impl Default for KVCache {
    fn default() -> Self {
        Self::new()
    }
}

/// Causal Self-Attention (convenience wrapper)
pub type CausalSelfAttention = MultiHeadAttention;
