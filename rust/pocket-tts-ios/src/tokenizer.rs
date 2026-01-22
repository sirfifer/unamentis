//! SentencePiece tokenizer for Pocket TTS

use std::path::Path;
use tokenizers::Tokenizer;

use crate::error::PocketTTSError;

/// Wrapper for the SentencePiece tokenizer
pub struct PocketTokenizer {
    tokenizer: Tokenizer,
}

impl PocketTokenizer {
    /// Load tokenizer from file path
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self, PocketTTSError> {
        // Note: tokenizers crate can load SentencePiece models
        let tokenizer = Tokenizer::from_file(path.as_ref())
            .map_err(|e| PocketTTSError::TokenizationFailed(e.to_string()))?;

        Ok(Self { tokenizer })
    }

    /// Load tokenizer from bytes (for bundled models)
    pub fn from_bytes(data: &[u8]) -> Result<Self, PocketTTSError> {
        let tokenizer = Tokenizer::from_bytes(data)
            .map_err(|e| PocketTTSError::TokenizationFailed(e.to_string()))?;

        Ok(Self { tokenizer })
    }

    /// Encode text to token IDs
    pub fn encode(&self, text: &str) -> Result<Vec<u32>, PocketTTSError> {
        let encoding = self.tokenizer
            .encode(text, false)
            .map_err(|e| PocketTTSError::TokenizationFailed(e.to_string()))?;

        Ok(encoding.get_ids().to_vec())
    }

    /// Decode token IDs back to text
    pub fn decode(&self, ids: &[u32]) -> Result<String, PocketTTSError> {
        self.tokenizer
            .decode(ids, true)
            .map_err(|e| PocketTTSError::TokenizationFailed(e.to_string()))
    }

    /// Get vocabulary size
    pub fn vocab_size(&self) -> usize {
        self.tokenizer.get_vocab_size(true)
    }

    /// Get special token IDs
    pub fn bos_token_id(&self) -> Option<u32> {
        self.tokenizer.token_to_id("<s>")
    }

    pub fn eos_token_id(&self) -> Option<u32> {
        self.tokenizer.token_to_id("</s>")
    }

    pub fn pad_token_id(&self) -> Option<u32> {
        self.tokenizer.token_to_id("<pad>")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tokenizer_creation() {
        // This test would need an actual tokenizer file
        // For now, just verify the struct compiles
    }
}
