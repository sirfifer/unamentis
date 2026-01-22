//! Model implementations for Pocket TTS
//!
//! Architecture:
//! - FlowLM: 6-layer transformer backbone (~70M params)
//! - MLPSampler: Consistency sampler (~10M params)
//! - MimiDecoder: VAE decoder for waveform generation (~20M params)

pub mod flowlm;
pub mod mimi;
pub mod seanet;
pub mod pocket_tts;

pub use flowlm::FlowLM;
pub use mimi::MimiDecoder;
pub use seanet::SEANetDecoder;
pub use pocket_tts::PocketTTSModel;
