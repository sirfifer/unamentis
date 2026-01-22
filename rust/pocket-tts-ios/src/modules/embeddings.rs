//! Embedding modules for text and voice

use candle_core::{DType, Device, Result, Tensor};
use candle_nn::{Embedding, Module, VarBuilder};

/// Text token embeddings
#[derive(Debug)]
pub struct TextEmbedding {
    embedding: Embedding,
    hidden_size: usize,
}

impl TextEmbedding {
    pub fn new(vocab_size: usize, hidden_size: usize, vb: VarBuilder) -> Result<Self> {
        let embedding = candle_nn::embedding(vocab_size, hidden_size, vb)?;
        Ok(Self { embedding, hidden_size })
    }

    pub fn forward(&self, token_ids: &Tensor) -> Result<Tensor> {
        self.embedding.forward(token_ids)
    }

    pub fn hidden_size(&self) -> usize {
        self.hidden_size
    }
}

/// Voice embedding (speaker identity)
#[derive(Debug, Clone)]
pub struct VoiceEmbedding {
    embedding: Tensor,
    voice_dim: usize,
}

impl VoiceEmbedding {
    /// Load voice embedding from safetensors file
    pub fn from_file(path: &std::path::Path, device: &Device) -> Result<Self> {
        let data = std::fs::read(path)?;
        Self::from_bytes(&data, device)
    }

    /// Load voice embedding from bytes
    pub fn from_bytes(data: &[u8], device: &Device) -> Result<Self> {
        let tensors = safetensors::SafeTensors::deserialize(data)?;

        // Find the embedding tensor (usually named "embedding" or "voice")
        let embedding_data = tensors
            .tensor("embedding")
            .or_else(|_| tensors.tensor("voice"))
            .or_else(|_| tensors.tensor("speaker"))
            .map_err(|e| candle_core::Error::Msg(format!("Voice embedding not found: {}", e)))?;

        let shape = embedding_data.shape();
        let voice_dim = shape.last().copied().unwrap_or(512);

        let candle_dtype = convert_safetensors_dtype(embedding_data.dtype())?;
        let embedding = Tensor::from_raw_buffer(
            embedding_data.data(),
            candle_dtype,
            shape,
            device,
        )?;

        Ok(Self { embedding, voice_dim })
    }

    /// Create voice embedding from raw tensor
    pub fn from_tensor(embedding: Tensor) -> Result<Self> {
        let voice_dim = embedding.dim(candle_core::D::Minus1)?;
        Ok(Self { embedding, voice_dim })
    }

    /// Get the embedding tensor
    pub fn embedding(&self) -> &Tensor {
        &self.embedding
    }

    /// Get voice dimension
    pub fn voice_dim(&self) -> usize {
        self.voice_dim
    }

    /// Expand embedding to match sequence length
    pub fn expand_to_seq(&self, batch_size: usize, seq_len: usize) -> Result<Tensor> {
        // Reshape from [voice_dim] to [1, 1, voice_dim]
        let expanded = self.embedding
            .unsqueeze(0)?
            .unsqueeze(0)?;

        // Expand to [batch_size, seq_len, voice_dim]
        expanded.expand(&[batch_size, seq_len, self.voice_dim])
    }
}

/// Voice embedding bank (all 8 built-in voices)
#[derive(Debug)]
pub struct VoiceBank {
    voices: Vec<VoiceEmbedding>,
    voice_dim: usize,
}

impl VoiceBank {
    pub fn new(voice_dim: usize) -> Self {
        Self {
            voices: Vec::with_capacity(8),
            voice_dim,
        }
    }

    /// Load all voices from a directory
    pub fn load_from_dir(dir: &std::path::Path, device: &Device) -> Result<Self> {
        let voice_names = [
            "alba", "marius", "javert", "jean",
            "fantine", "cosette", "eponine", "azelma",
        ];

        let mut voices = Vec::with_capacity(8);
        let mut voice_dim = 512; // Default

        for name in &voice_names {
            let path = dir.join(format!("{}.safetensors", name));
            if path.exists() {
                let voice = VoiceEmbedding::from_file(&path, device)?;
                voice_dim = voice.voice_dim();
                voices.push(voice);
            }
        }

        Ok(Self { voices, voice_dim })
    }

    /// Get voice by index
    pub fn get(&self, index: usize) -> Option<&VoiceEmbedding> {
        self.voices.get(index)
    }

    /// Number of loaded voices
    pub fn len(&self) -> usize {
        self.voices.len()
    }

    pub fn is_empty(&self) -> bool {
        self.voices.is_empty()
    }

    pub fn voice_dim(&self) -> usize {
        self.voice_dim
    }
}

/// Convert safetensors dtype to candle dtype
fn convert_safetensors_dtype(dtype: safetensors::Dtype) -> Result<DType> {
    match dtype {
        safetensors::Dtype::F32 => Ok(DType::F32),
        safetensors::Dtype::F16 => Ok(DType::F16),
        safetensors::Dtype::BF16 => Ok(DType::BF16),
        safetensors::Dtype::I64 => Ok(DType::I64),
        safetensors::Dtype::U32 => Ok(DType::U32),
        safetensors::Dtype::U8 => Ok(DType::U8),
        _ => Err(candle_core::Error::Msg(format!("Unsupported dtype: {:?}", dtype))),
    }
}
