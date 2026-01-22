//! Tokenizer for Pocket TTS
//!
//! Pure Rust implementation for iOS cross-compilation compatibility.
//! Supports loading vocabulary from JSON and basic BPE-style tokenization.

use std::collections::HashMap;
use std::path::Path;

use crate::error::PocketTTSError;

/// Wrapper for the tokenizer
pub struct PocketTokenizer {
    token_to_id: HashMap<String, u32>,
    id_to_token: Vec<String>,
    bos_id: Option<u32>,
    eos_id: Option<u32>,
    pad_id: Option<u32>,
    unk_id: u32,
}

impl PocketTokenizer {
    /// Load tokenizer from file path (JSON vocab file)
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self, PocketTTSError> {
        let content = std::fs::read_to_string(path.as_ref())
            .map_err(|e| PocketTTSError::TokenizationFailed(format!("Failed to read vocab: {}", e)))?;

        Self::from_json(&content)
    }

    /// Load tokenizer from bytes (for bundled models)
    pub fn from_bytes(data: &[u8]) -> Result<Self, PocketTTSError> {
        let content = std::str::from_utf8(data)
            .map_err(|e| PocketTTSError::TokenizationFailed(format!("Invalid UTF-8: {}", e)))?;

        Self::from_json(content)
    }

    /// Load tokenizer from JSON string
    fn from_json(content: &str) -> Result<Self, PocketTTSError> {
        // Parse JSON vocabulary: {"<unk>": 0, "<s>": 1, "</s>": 2, ...}
        let vocab: HashMap<String, u32> = serde_json::from_str(content)
            .map_err(|e| PocketTTSError::TokenizationFailed(format!("Invalid vocab JSON: {}", e)))?;

        // Build reverse mapping
        let mut id_to_token: Vec<String> = vec![String::new(); vocab.len()];
        for (token, &id) in &vocab {
            if (id as usize) < id_to_token.len() {
                id_to_token[id as usize] = token.clone();
            }
        }

        // Find special tokens
        let bos_id = vocab.get("<s>").copied();
        let eos_id = vocab.get("</s>").copied();
        let pad_id = vocab.get("<pad>").copied();
        let unk_id = vocab.get("<unk>").copied().unwrap_or(0);

        Ok(Self {
            token_to_id: vocab,
            id_to_token,
            bos_id,
            eos_id,
            pad_id,
            unk_id,
        })
    }

    /// Create a minimal tokenizer with default vocabulary
    /// (For testing when no vocab file is available)
    pub fn minimal() -> Self {
        let mut token_to_id = HashMap::new();
        token_to_id.insert("<unk>".to_string(), 0);
        token_to_id.insert("<s>".to_string(), 1);
        token_to_id.insert("</s>".to_string(), 2);
        token_to_id.insert("<pad>".to_string(), 3);
        token_to_id.insert(" ".to_string(), 4);

        // Add basic ASCII characters
        for (i, c) in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?".chars().enumerate() {
            token_to_id.insert(c.to_string(), (5 + i) as u32);
        }

        let mut id_to_token: Vec<String> = vec![String::new(); token_to_id.len()];
        for (token, &id) in &token_to_id {
            if (id as usize) < id_to_token.len() {
                id_to_token[id as usize] = token.clone();
            }
        }

        Self {
            token_to_id,
            id_to_token,
            bos_id: Some(1),
            eos_id: Some(2),
            pad_id: Some(3),
            unk_id: 0,
        }
    }

    /// Encode text to token IDs
    /// Uses character-level fallback for unknown tokens
    pub fn encode(&self, text: &str) -> Result<Vec<u32>, PocketTTSError> {
        let mut tokens = Vec::new();

        // Add BOS token if configured
        if let Some(bos) = self.bos_id {
            tokens.push(bos);
        }

        // Simple character-level tokenization with longest match
        let mut i = 0;
        let chars: Vec<char> = text.chars().collect();

        while i < chars.len() {
            let mut found = false;
            let mut end = chars.len().min(i + 10); // Max token length 10

            // Try longest match first
            while end > i {
                let substr: String = chars[i..end].iter().collect();
                if let Some(&id) = self.token_to_id.get(&substr) {
                    tokens.push(id);
                    i = end;
                    found = true;
                    break;
                }
                end -= 1;
            }

            // Fall back to single character or UNK
            if !found {
                let c = chars[i].to_string();
                let id = self.token_to_id.get(&c).copied().unwrap_or(self.unk_id);
                tokens.push(id);
                i += 1;
            }
        }

        // Add EOS token if configured
        if let Some(eos) = self.eos_id {
            tokens.push(eos);
        }

        Ok(tokens)
    }

    /// Decode token IDs back to text
    pub fn decode(&self, ids: &[u32]) -> Result<String, PocketTTSError> {
        let mut text = String::new();

        for &id in ids {
            // Skip special tokens
            if Some(id) == self.bos_id || Some(id) == self.eos_id || Some(id) == self.pad_id {
                continue;
            }

            if let Some(token) = self.id_to_token.get(id as usize) {
                text.push_str(token);
            } else {
                text.push('\u{FFFD}'); // Replacement character
            }
        }

        Ok(text)
    }

    /// Get vocabulary size
    pub fn vocab_size(&self) -> usize {
        self.token_to_id.len()
    }

    /// Get special token IDs
    pub fn bos_token_id(&self) -> Option<u32> {
        self.bos_id
    }

    pub fn eos_token_id(&self) -> Option<u32> {
        self.eos_id
    }

    pub fn pad_token_id(&self) -> Option<u32> {
        self.pad_id
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tokenizer_creation() {
        let _: fn() -> Option<PocketTokenizer> = || None;
    }

    #[test]
    fn test_minimal_tokenizer() {
        let tokenizer = PocketTokenizer::minimal();
        assert!(tokenizer.vocab_size() > 0);
        assert!(tokenizer.bos_token_id().is_some());
        assert!(tokenizer.eos_token_id().is_some());
    }

    #[test]
    fn test_encode_decode() {
        let tokenizer = PocketTokenizer::minimal();
        let text = "hello";
        let tokens = tokenizer.encode(text).unwrap();
        assert!(!tokens.is_empty());

        let decoded = tokenizer.decode(&tokens).unwrap();
        assert_eq!(decoded.to_lowercase(), text);
    }

    #[test]
    fn test_from_json() {
        let json = r#"{"<unk>": 0, "<s>": 1, "</s>": 2, "hello": 3, " ": 4, "world": 5}"#;
        let tokenizer = PocketTokenizer::from_json(json).unwrap();
        assert_eq!(tokenizer.vocab_size(), 6);

        let tokens = tokenizer.encode("hello world").unwrap();
        // Should be: <s> hello <space> world </s>
        assert_eq!(tokens[0], 1); // <s>
        assert_eq!(tokens[1], 3); // hello
        assert_eq!(tokens[2], 4); // space
        assert_eq!(tokens[3], 5); // world
        assert_eq!(tokens[4], 2); // </s>
    }
}
