# UnaMentis Server Infrastructure Guide

**Purpose:** Document the model serving infrastructure, resource requirements, and deployment options for UnaMentis backend services.

**Last Updated:** December 2025

---

## Table of Contents

1. [Current Production Setup](#1-current-production-setup)
2. [Model Resource Requirements](#2-model-resource-requirements)
3. [Hardware Compatibility Matrix](#3-hardware-compatibility-matrix)
4. [Deployment Configurations](#4-deployment-configurations)
5. [Cloud Deployment Options](#5-cloud-deployment-options)
6. [Network Architecture](#6-network-architecture)
7. [Performance Benchmarks](#7-performance-benchmarks)
8. [Cost Analysis](#8-cost-analysis)

---

## 1. Current Production Setup

### 1.1 Running Services

| Service | Port | Model | Purpose |
|---------|------|-------|---------|
| **Ollama** | 11434 | mistral:7b (primary) | LLM inference |
| **VibeVoice** | 8880 | microsoft/VibeVoice-Realtime-0.5B | Text-to-Speech |
| **Piper** | 11402 | en_US-amy-medium | Backup TTS |
| **Management Console** | 8766 | - | Curriculum, admin |
| **Operations Console** | 3000 | - | DevOps monitoring |

### 1.2 Current Host: MacBook Pro M4 Max

| Specification | Value |
|---------------|-------|
| **CPU** | Apple M4 Max (14-core) |
| **GPU** | 40-core integrated |
| **Unified Memory** | 128 GB |
| **Memory Bandwidth** | ~400 GB/s |
| **Storage** | 1+ TB NVMe |

**Advantages:**
- Unified memory allows running very large models (70B+)
- Metal acceleration for both LLM and TTS
- Low power consumption
- Silent operation

**Disadvantages:**
- Not always-on (laptop)
- Expensive hardware
- Single point of failure

---

## 2. Model Resource Requirements

### 2.1 Currently Deployed Models

| Model | Type | Disk Size | VRAM (GPU) | RAM (CPU) | Notes |
|-------|------|-----------|------------|-----------|-------|
| **mistral:7b** | LLM | 4.4 GB | ~5-6 GB | ~8 GB | Primary tutoring model |
| **VibeVoice-Realtime-0.5B** | TTS | 1.9 GB | ~2-3 GB | ~4 GB | Microsoft streaming TTS |
| **llama3.2:3b** | LLM | 2.0 GB | ~3 GB | ~4 GB | Fast/simple tasks |
| **qwen2.5:32b** | LLM | 19.9 GB | ~22-24 GB | ~26 GB | High-quality option |

### 2.2 Planned/Evaluated Models

| Model | Type | Disk Size | VRAM (GPU) | RAM (CPU) | Status |
|-------|------|-----------|------------|-----------|--------|
| **GLM-ASR-Nano-2512** | STT | ~3 GB (FP16) | ~4.5 GB | ~6 GB | Evaluation |
| **qwen2.5:14b** | LLM | ~9 GB | ~11 GB | ~14 GB | Available |
| **qwen2.5:7b** | LLM | ~4.5 GB | ~5-6 GB | ~8 GB | Available |
| **Piper voices** | TTS | ~50 MB each | minimal | minimal | Backup |

### 2.3 Minimum Production Stack

For basic UnaMentis functionality:

| Component | Model | VRAM Required |
|-----------|-------|---------------|
| LLM | mistral:7b | ~5-6 GB |
| TTS | VibeVoice-0.5B | ~2-3 GB |
| **Total** | | **~8-9 GB** |

---

## 3. Hardware Compatibility Matrix

### 3.1 NVIDIA Consumer GPUs

| GPU | VRAM | mistral:7b | VibeVoice | Both Together | Larger Models |
|-----|------|------------|-----------|---------------|---------------|
| RTX 3060 8GB | 8 GB | Yes | Yes | Tight | No |
| RTX 3060 12GB | 12 GB | Yes | Yes | **Yes** | qwen2.5:7b |
| RTX 3070 | 8 GB | Yes | Yes | Tight | No |
| RTX 3080 | 10 GB | Yes | Yes | Yes | qwen2.5:7b |
| RTX 3090 | 24 GB | Yes | Yes | Yes | qwen2.5:14b |
| RTX 4060 | 8 GB | Yes | Yes | Tight | No |
| RTX 4060 Ti | 8/16 GB | Yes | Yes | Yes (16GB) | qwen2.5:14b (16GB) |
| RTX 4070 | 12 GB | Yes | Yes | Yes | qwen2.5:7b |
| RTX 4080 | 16 GB | Yes | Yes | Yes | qwen2.5:14b |
| RTX 4090 | 24 GB | Yes | Yes | Yes | qwen2.5:32b (tight) |
| RTX 5060 Ti | 16 GB | Yes | Yes | **Yes** | qwen2.5:14b |
| RTX 5070 | 12 GB | Yes | Yes | Yes | qwen2.5:7b |
| RTX 5080 | 16 GB | Yes | Yes | Yes | qwen2.5:14b |
| RTX 5090 | 32 GB | Yes | Yes | Yes | qwen2.5:32b |

### 3.2 NVIDIA Data Center GPUs

| GPU | VRAM | Use Case | Monthly Cost (Cloud) |
|-----|------|----------|---------------------|
| T4 | 16 GB | Budget production | ~$150-300 |
| L4 | 24 GB | Balanced | ~$300-500 |
| A10G | 24 GB | AWS standard | ~$400-600 |
| A100 40GB | 40 GB | High-end | ~$1,500+ |
| A100 80GB | 80 GB | Large models | ~$2,500+ |
| H100 | 80 GB | Ultra performance | ~$3,000+ |

### 3.3 Apple Silicon

| Chip | Unified Memory | Model Capacity | Notes |
|------|----------------|----------------|-------|
| M1 | 8-16 GB | mistral:7b | Slow |
| M1 Pro/Max | 32-64 GB | qwen2.5:32b | Good |
| M2 | 8-24 GB | mistral:7b | Moderate |
| M2 Pro/Max | 32-96 GB | qwen2.5:32b+ | Good |
| M3 | 8-24 GB | mistral:7b | Moderate |
| M3 Pro/Max | 36-128 GB | 70B models | Very good |
| M4 | 16-32 GB | qwen2.5:14b | Good |
| **M4 Pro/Max** | 48-128 GB | **70B+ models** | **Excellent** |

### 3.4 CPU-Only (No GPU)

For servers without GPU acceleration:

| Model | RAM Required | Speed (tokens/s) | Viable? |
|-------|--------------|------------------|---------|
| llama3.2:3b | ~4 GB | 15-25 | Yes |
| mistral:7b | ~8 GB | 5-10 | Marginal |
| qwen2.5:7b | ~8 GB | 5-10 | Marginal |
| Larger models | 16+ GB | <5 | Not recommended |

**Recommendation:** CPU-only is not recommended for production. Use for development/testing only.

---

## 4. Deployment Configurations

### 4.1 Configuration A: Single Windows PC (Recommended for Home)

**Hardware:** Windows PC with RTX 3060 12GB or RTX 5060 Ti 16GB

```
┌─────────────────────────────────────────────────────────────┐
│                     Windows PC                               │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ Ollama          │  │ VibeVoice       │                   │
│  │ mistral:7b      │  │ 0.5B            │                   │
│  │ Port 11434      │  │ Port 8880       │                   │
│  └─────────────────┘  └─────────────────┘                   │
│                                                              │
│  GPU: RTX 3060 12GB / RTX 5060 Ti 16GB                      │
│  RAM: 16-32 GB                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                     iPhone App (LAN)
```

**Pros:**
- Single machine to manage
- Lower power consumption than multiple machines
- Can run 24/7

**Cons:**
- Limited to models that fit in VRAM
- No redundancy

**Setup Steps:**
1. Install NVIDIA drivers
2. Install Ollama for Windows
3. Pull mistral:7b: `ollama pull mistral:7b`
4. Clone and run VibeVoice server
5. Configure firewall for LAN access

### 4.2 Configuration B: Mac + Windows Hybrid

**Hardware:** MacBook M4 Max (primary) + Windows PC (always-on fallback)

```
┌─────────────────────────────────────────────────────────────┐
│  MacBook Pro M4 Max (Primary - when available)              │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ Ollama          │  │ VibeVoice       │                   │
│  │ qwen2.5:32b     │  │ 0.5B            │                   │
│  │ mistral:7b      │  │                 │                   │
│  └─────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │         Failover              │
              ▼                               ▼
┌─────────────────────────────────────────────────────────────┐
│  Windows PC (Fallback - always on)                          │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ Ollama          │  │ VibeVoice       │                   │
│  │ mistral:7b      │  │ 0.5B            │                   │
│  └─────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                     iPhone App (LAN)
```

**Pros:**
- Best quality when Mac available (larger models)
- Always-on fallback
- Redundancy

**Cons:**
- Two machines to maintain
- More complex routing

### 4.3 Configuration C: Dedicated Server (Proxmox/Linux)

**Hardware:** Linux server with NVIDIA GPU

```
┌─────────────────────────────────────────────────────────────┐
│  Proxmox / Ubuntu Server                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Docker Compose                                       │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │   │
│  │  │ Ollama   │  │VibeVoice │  │ Piper    │          │   │
│  │  │ :11434   │  │ :8880    │  │ :11402   │          │   │
│  │  └──────────┘  └──────────┘  └──────────┘          │   │
│  │                                                      │   │
│  │  ┌──────────┐  ┌──────────┐                         │   │
│  │  │ Mgmt     │  │ Ops      │                         │   │
│  │  │ :8766    │  │ :3000    │                         │   │
│  │  └──────────┘  └──────────┘                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  GPU: RTX 3090 / 4090 / A10                                 │
│  RAM: 32-64 GB                                               │
└─────────────────────────────────────────────────────────────┘
```

**Pros:**
- Dedicated, always-on
- Can run multiple VMs/containers
- Enterprise-grade

**Cons:**
- Higher power consumption
- More complex setup
- Hardware cost

---

## 5. Cloud Deployment Options

### 5.1 GPU Cloud Providers

| Provider | GPU Options | Hourly Cost | Monthly (24/7) | Best For |
|----------|-------------|-------------|----------------|----------|
| **RunPod** | T4, A10, A100 | $0.20-2.00 | $144-1,440 | Budget GPU |
| **Vast.ai** | Consumer GPUs | $0.10-0.50 | $72-360 | Cheapest |
| **Lambda Labs** | A10, A100, H100 | $0.50-3.00 | $360-2,160 | ML-focused |
| **AWS EC2** | T4, A10G, A100 | $0.50-4.00 | $360-2,880 | Enterprise |
| **GCP** | T4, L4, A100 | $0.35-3.00 | $252-2,160 | Enterprise |
| **Azure** | T4, A10, A100 | $0.50-4.00 | $360-2,880 | Enterprise |

### 5.2 Serverless/Pay-Per-Use

| Provider | Pricing Model | Cost Estimate | Best For |
|----------|---------------|---------------|----------|
| **Modal** | Per-second compute | ~$0.10/min active | Bursty workloads |
| **Replicate** | Per-prediction | Varies by model | Simple deployment |
| **Banana.dev** | Per-second GPU | ~$0.10/min active | Custom models |
| **Together.ai** | Per-token API | ~$0.20/1M tokens | API-only |

### 5.3 Recommended Cloud Configuration

**For Development/Testing:**
- RunPod or Vast.ai with T4 16GB
- ~$150/month for 24/7

**For Production (Low Scale):**
- AWS g5.xlarge (A10G) spot instances
- ~$200-300/month with spot pricing

**For Production (Scale):**
- Multiple A10G instances behind load balancer
- Auto-scaling based on demand

---

## 6. Network Architecture

### 6.1 LAN Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                      Home Network                            │
│                                                              │
│   ┌─────────────┐        ┌─────────────┐                    │
│   │   Router    │────────│   Server    │                    │
│   │ 192.168.1.1 │        │192.168.1.100│                    │
│   └─────────────┘        └─────────────┘                    │
│         │                      │                             │
│         │                      ├── Ollama :11434            │
│         │                      ├── VibeVoice :8880          │
│         │                      ├── Management :8766         │
│         │                      └── Operations :3000         │
│         │                                                    │
│   ┌─────────────┐                                           │
│   │   iPhone    │                                           │
│   │ WiFi Client │                                           │
│   └─────────────┘                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Firewall Rules:**
- Allow TCP 11434 (Ollama) from LAN
- Allow TCP 8880 (VibeVoice) from LAN
- Allow TCP 8766 (Management) from LAN
- Allow TCP 3000 (Operations) from LAN

### 6.2 Remote Access (VPN)

For accessing home server from outside:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   iPhone    │────▶│  WireGuard  │────▶│   Server    │
│ (Cellular)  │     │    VPN      │     │   (Home)    │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Options:**
- WireGuard (recommended)
- Tailscale (easiest)
- OpenVPN

### 6.3 Cloud with CDN

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   iPhone    │────▶│ Cloudflare  │────▶│ Cloud GPU   │
│             │     │   Tunnel    │     │   Server    │
└─────────────┘     └─────────────┘     └─────────────┘
```

---

## 7. Performance Benchmarks

### 7.1 LLM Inference Speed

| Hardware | Model | Tokens/sec | TTFT | Notes |
|----------|-------|------------|------|-------|
| M4 Max 128GB | mistral:7b | 80-100 | ~50ms | Metal acceleration |
| M4 Max 128GB | qwen2.5:32b | 25-35 | ~150ms | Metal acceleration |
| RTX 3060 12GB | mistral:7b | 40-60 | ~80ms | CUDA |
| RTX 4090 24GB | mistral:7b | 100-120 | ~30ms | CUDA |
| RTX 4090 24GB | qwen2.5:32b | 30-40 | ~100ms | CUDA |
| T4 16GB | mistral:7b | 30-45 | ~100ms | Cloud GPU |
| A10G 24GB | mistral:7b | 50-70 | ~60ms | Cloud GPU |

### 7.2 TTS Latency (VibeVoice)

| Hardware | TTFB | Full Sentence | Notes |
|----------|------|---------------|-------|
| M4 Max | ~100ms | ~300ms | Metal |
| RTX 3060 | ~150ms | ~400ms | CUDA |
| RTX 4090 | ~80ms | ~250ms | CUDA |
| T4 | ~200ms | ~500ms | Cloud |

### 7.3 End-to-End Latency Target

| Component | Target | Acceptable |
|-----------|--------|------------|
| STT | <300ms | <500ms |
| LLM (TTFT) | <200ms | <500ms |
| TTS (TTFB) | <200ms | <400ms |
| **Total E2E** | **<500ms** | **<1000ms** |

---

## 8. Cost Analysis

### 8.1 Self-Hosted vs Cloud

| Scenario | Self-Hosted | Cloud (24/7) | Cloud (On-Demand) |
|----------|-------------|--------------|-------------------|
| Hardware | $500-2000 one-time | $0 | $0 |
| Monthly (power) | ~$20-50 | $0 | $0 |
| Monthly (compute) | $0 | $150-500 | $50-200 |
| **Year 1 Total** | $740-2,600 | $1,800-6,000 | $600-2,400 |
| **Year 2+ Total** | $240-600/yr | $1,800-6,000/yr | $600-2,400/yr |

### 8.2 Break-Even Analysis

**Self-hosted becomes cheaper than cloud after:**
- vs. RunPod T4 ($144/mo): ~4-14 months
- vs. AWS g5.xlarge ($400/mo): ~1-5 months
- vs. On-demand cloud: ~6-24 months (depends on usage)

### 8.3 Usage-Based Cost Comparison

| Monthly Usage | Deepgram STT | Self-Hosted STT | Savings |
|---------------|--------------|-----------------|---------|
| 10 hours | $2.60 | ~$0 | 100% |
| 100 hours | $26 | ~$0 | 100% |
| 500 hours | $130 | ~$20 (power) | 85% |
| 1000 hours | $260 | ~$30 (power) | 88% |

---

## Appendix A: Installation Guides

### A.1 Windows + Ollama + VibeVoice

```powershell
# 1. Install Ollama
winget install Ollama.Ollama

# 2. Pull models
ollama pull mistral:7b

# 3. Clone VibeVoice
git clone https://github.com/user/vibevoice-realtime-openai-api
cd vibevoice-realtime-openai-api

# 4. Create virtual environment
python -m venv .venv
.venv\Scripts\activate

# 5. Install dependencies
pip install -r requirements.txt

# 6. Run VibeVoice
python vibevoice_realtime_openai_api.py --port 8880 --device cuda
```

### A.2 Linux/Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  vibevoice:
    build: ./vibevoice
    ports:
      - "8880:8880"
    environment:
      - DEVICE=cuda
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

volumes:
  ollama_data:
```

---

## Appendix B: Troubleshooting

### B.1 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| CUDA out of memory | Model too large | Use smaller model or quantization |
| Slow inference | CPU fallback | Check GPU drivers, CUDA installation |
| Connection refused | Firewall | Open ports, check binding address |
| High latency | Network | Use LAN, check WiFi signal |

### B.2 Monitoring Commands

```bash
# Check GPU memory usage (NVIDIA)
nvidia-smi

# Check Ollama status
curl http://localhost:11434/api/tags

# Check VibeVoice health
curl http://localhost:8880/health

# Monitor GPU continuously
watch -n 1 nvidia-smi
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | December 2025 | Claude | Initial document |
