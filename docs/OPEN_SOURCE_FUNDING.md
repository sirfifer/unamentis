# Open Source Funding & Cloud Credits Guide

This document provides a comprehensive guide to obtaining cloud credits, grants, and funding for UnaMentis as an open source project.

## Executive Summary

As an open source educational AI project, UnaMentis qualifies for numerous credit programs across major cloud providers. This guide prioritizes options by ease of application and speed of approval, with a focus on programs that don't require external funding or venture capital.

**Total Potential Credits:** $50K-150K+ across providers

---

## Tier 1: Direct Apply, Fast Turnaround (Days)

These programs have established application processes with quick turnaround times. Apply directly without intermediaries.

### AWS Open Source Credits

| Attribute | Details |
|-----------|---------|
| **Credits Available** | Typically $5K-$25K |
| **Application** | Email form to awsopensourcecredits@amazon.com |
| **Turnaround** | Monthly review cycle |
| **Requirements** | OSI-approved license, active project |
| **Validity** | 12 months |
| **GPU Coverage** | Yes (g4dn, g5 instances) |
| **URL** | [aws.amazon.com/opensource](https://aws.amazon.com/blogs/opensource/aws-promotional-credits-open-source-projects/) |

**Why AWS First:**
- Established program since 2019, 200+ projects funded
- Supports foundation-owned and multi-maintainer projects
- Best GPU pricing with spot instances
- Credits work on all EC2 instance types

**Application Template:**

```
Subject: AWS Open Source Credits Application - UnaMentis

Project: UnaMentis
Website: https://github.com/[your-org]/unamentis
License: [MIT/Apache 2.0/etc.]

Description:
UnaMentis is an open source iOS voice AI tutoring application that
enables 60-90+ minute learning sessions with sub-500ms latency.
The project is developed with 100% AI assistance and serves as a
community resource for voice-based educational technology.

AWS Usage Plans:
- EC2 GPU instances (g4dn/g5) for LLM and TTS inference
- CI/CD testing and integration
- Performance benchmarking across instance types

Community Impact:
- Open source educational technology
- Reference implementation for voice AI applications
- [Add any community/educational partnerships]

Requested Credits: $[5,000-25,000] over 12 months

Contact: [your-email]
```

---

### DigitalOcean Open Source Credits

| Attribute | Details |
|-----------|---------|
| **Credits Available** | Varies by project tier |
| **Application** | Online form |
| **Turnaround** | 7-10 business days |
| **Requirements** | OSI-approved license required |
| **GPU Coverage** | Yes (new GPU Droplets available) |
| **URL** | [digitalocean.com/open-source](https://www.digitalocean.com/open-source/credits-for-projects) |

**Note:** This is separate from their Hatch startup program. The OSS program is specifically for open source projects regardless of commercial status.

---

### Microsoft Azure for Open Source

| Attribute | Details |
|-----------|---------|
| **Credits Available** | Varies |
| **Application** | Online application |
| **Turnaround** | ~2 weeks |
| **Requirements** | Active OSS project |
| **GPU Coverage** | Yes (NC-series VMs) |
| **URL** | [Azure OSS Program](https://cloudblogs.microsoft.com/opensource/2021/09/28/announcing-azure-credits-for-open-source-projects/) |

---

### Lambda Labs Research Grant

| Attribute | Details |
|-----------|---------|
| **Credits Available** | Up to $5,000 |
| **Application** | Online application |
| **Turnaround** | Rolling admissions |
| **Requirements** | Research or educational focus |
| **GPU Coverage** | Yes (A100, H100 available) |
| **URL** | [lambda.ai/research](https://lambda.ai/research) |

**Best for:** Additional GPU credits alongside primary cloud provider.

---

### RunPod Startup Program

| Attribute | Details |
|-----------|---------|
| **Credits Available** | Varies |
| **Application** | Email startups@runpod.io |
| **Turnaround** | 48 hours |
| **Requirements** | Early-stage project |
| **GPU Coverage** | Yes (consumer and enterprise GPUs) |
| **URL** | [runpod.io/startup-program](https://www.runpod.io/startup-program) |

**Fastest turnaround** of any program. Good for quick prototyping needs.

---

## Tier 2: Requires Affiliation or Qualification (1-4 Weeks)

These programs require additional qualification but offer larger credit amounts.

### NVIDIA Inception Program

| Attribute | Details |
|-----------|---------|
| **Credits Available** | Up to $100K (via partners) |
| **Application** | Online, free to join |
| **Turnaround** | ~1 week |
| **Requirements** | Incorporated startup, 1+ developer |
| **Direct Credits** | No (unlocks partner credits) |
| **URL** | [nvidia.com/startups](https://www.nvidia.com/en-us/startups/) |

**Why Join Inception:**
- Free to join, no cohort deadlines
- Opens access to $100K+ in partner credits:
  - Nebius AI Lift: $150K for Inception members
  - AWS Activate partnership
  - Scaleway credits
- Technical training included
- VC network access for future funding

**Recommended Strategy:**
1. Join NVIDIA Inception (immediate, free)
2. Apply for Nebius AI Lift ($150K credits)
3. Apply for AWS Activate (through Inception partnership)

---

### Google Cloud Startups

| Attribute | Details |
|-----------|---------|
| **Credits Available** | $2K-$350K |
| **Application** | Online application |
| **Turnaround** | 1-2 weeks |
| **Requirements** | Equity funding OR early-stage unfunded |
| **GPU Coverage** | Yes (T4, A100, TPU) |
| **URL** | [cloud.google.com/startup](https://cloud.google.com/startup) |

**Note:** Easier to qualify than it sounds. "Early-stage unfunded" includes open source projects with no revenue.

---

### DigitalOcean Hatch Program

| Attribute | Details |
|-----------|---------|
| **Credits Available** | Up to $100K + 3 months GPU |
| **Application** | Online application |
| **Turnaround** | 1-2 weeks |
| **Requirements** | Series A or less, new customer |
| **GPU Coverage** | Yes (included) |
| **URL** | [digitalocean.com/startups](https://www.digitalocean.com/startups) |

**Separate from OSS program.** If you qualify for both, apply to both.

---

### Modal Startup Program

| Attribute | Details |
|-----------|---------|
| **Credits Available** | $500-$25K |
| **Application** | Partner-gated |
| **Turnaround** | Varies |
| **Requirements** | Through accelerator/VC partner |
| **URL** | [modal.com/startups](https://modal.com/startups) |

**Best for:** If you're already affiliated with a startup accelerator.

---

## Tier 3: Free Tiers (No Application, Immediate)

These require no application and can be used immediately for development and testing.

### Groq Free Tier

| Attribute | Details |
|-----------|---------|
| **Free Limits** | 14,400 requests/day |
| **Models** | Whisper (STT), LLMs |
| **Latency** | ~50-100ms (fastest available) |
| **Credit Card** | Not required |
| **URL** | [console.groq.com](https://console.groq.com) |

**Best immediate action:** Sign up for Groq TODAY. Their Whisper API covers STT needs at no cost, removing one model from your GPU requirements.

**Daily Capacity:**
- 14,400 requests = 20-40 hours of tutoring usage
- Sufficient for development, testing, and personal use

---

### Hugging Face Free Credits

| Attribute | Details |
|-----------|---------|
| **Free Limits** | Monthly quota |
| **GPU Access** | ZeroGPU (queued) |
| **Models** | Any HF-hosted model |
| **URL** | [huggingface.co/pricing](https://huggingface.co/pricing) |

---

### Replicate Free Credits

| Attribute | Details |
|-----------|---------|
| **Free Limits** | Limited compute |
| **Models** | Hosted models only |
| **URL** | [replicate.com/pricing](https://replicate.com/pricing) |

---

### Google Colab / Kaggle

| Platform | GPU | Limits |
|----------|-----|--------|
| **Colab** | T4 16GB | 12hr sessions, throttled access |
| **Kaggle** | T4/P100 | 30 GPU-hours/week |

**Note:** These prohibit running servers and are suitable only for prototyping and testing.

---

## Recommended Action Plan

### Week 1: Immediate Actions

1. **Sign up for Groq** (console.groq.com)
   - Get Whisper API access immediately
   - Test integration with your server
   - This removes STT from your GPU requirements
   - **Time required:** 15 minutes

2. **Join NVIDIA Inception** (nvidia.com/startups)
   - Free, no commitment
   - Opens partner credit opportunities
   - Takes ~1 week to process
   - **Time required:** 30 minutes

3. **Prepare AWS OSS Application**
   - Ensure GitHub repo has clear open source license
   - Document project purpose and AWS usage plans
   - List multiple maintainers if possible
   - **Time required:** 1 hour

### Week 2: Submit Applications

4. **Submit AWS Open Source Credits Application**
   - Email awsopensourcecredits@amazon.com with completed form
   - Highlight: Educational AI, open source, multi-maintainer potential
   - **Time required:** 30 minutes

5. **Submit DigitalOcean OSS Application**
   - digitalocean.com/open-source/credits-for-projects
   - Backup option if AWS is slow
   - **Time required:** 30 minutes

6. **Apply for Lambda Labs Research Grant**
   - lambda.ai/research
   - Good for additional $5K GPU credits
   - **Time required:** 30 minutes

### Week 3-4: Follow Up & Expansion

7. **Apply for Additional Programs**
   - Google Cloud Startups (if you qualify as early-stage)
   - RunPod Startup Program (email: startups@runpod.io)
   - Nebius AI Lift (via Inception membership)
   - **Time required:** 2 hours total

8. **Track Applications**
   - Create spreadsheet of submitted applications
   - Set follow-up reminders for 2 weeks post-submission
   - Document approval/denial for future reference

---

## Priority Summary

| Priority | Action | Expected Result | Timeline | Effort |
|----------|--------|-----------------|----------|--------|
| 1 | Sign up for Groq | Free STT immediately | Today | 15 min |
| 2 | Join NVIDIA Inception | Partner credit access | 1 week | 30 min |
| 3 | Apply AWS OSS Credits | $5K-25K credits | 2-4 weeks | 1 hour |
| 4 | Apply DigitalOcean OSS | Backup credits | 1-2 weeks | 30 min |
| 5 | Apply Lambda Research | Additional $5K | 2-3 weeks | 30 min |
| 6 | Apply RunPod Startup | GPU credits | 48 hours | 15 min |

---

## Credit Optimization Strategies

### 1. Use Hibernation to Extend Credits

Credits are time-based. Your existing idle management system maximizes runway:

| Usage Pattern | Credit Multiplier |
|---------------|-------------------|
| 24/7 always-on | 1x (baseline) |
| 8 hours/day | 3x longer |
| 4 hours/day | 6x longer |

With $10K in AWS credits at $0.16/hr (spot g4dn.xlarge):
- 24/7: ~8 months
- 8hr/day: ~24 months
- 4hr/day: ~48 months

### 2. Offload STT to Free Tier

By using Groq's free Whisper API:
- Reduce VRAM requirements from 8-9GB to 6-7GB
- Use smaller/cheaper GPU instances
- STT always available (no cold start)

### 3. Stack Multiple Programs

Nothing prevents applying to multiple programs:
- AWS OSS Credits: Primary cloud
- Lambda Labs: Backup/testing
- Groq: STT (free)
- RunPod: Burst capacity

### 4. Consider Spot/Preemptible Instances

When using credits on AWS/GCP/Azure:
- Spot instances are 60-80% cheaper than on-demand
- Credits apply equally to spot pricing
- Perfect for development and testing workloads

---

## Application Best Practices

### What Reviewers Look For

1. **Active Development**
   - Recent commits in the last 30 days
   - Multiple contributors (if possible)
   - Clear project roadmap

2. **Community Impact**
   - Educational focus (strong for UnaMentis)
   - Open source license (OSI-approved)
   - Documentation and accessibility

3. **Realistic Usage Plans**
   - Specific instance types and regions
   - Estimated monthly usage
   - Clear connection between resources and project goals

4. **Long-term Viability**
   - Sustainability plan beyond credits
   - Community growth strategy
   - Potential for self-sustaining usage

### Common Mistakes to Avoid

- Requesting too little (underselling your needs)
- Requesting too much without justification
- Vague project descriptions
- Missing or unclear license information
- No visible recent activity

---

## Tracking Template

Use this template to track your applications:

| Provider | Program | Applied Date | Status | Amount | Expires | Notes |
|----------|---------|--------------|--------|--------|---------|-------|
| Groq | Free Tier | [date] | Active | N/A | N/A | 14,400 req/day |
| NVIDIA | Inception | [date] | Pending | N/A | N/A | Gateway to partner credits |
| AWS | OSS Credits | [date] | Pending | $10K requested | TBD | Monthly review cycle |
| DigitalOcean | OSS Credits | [date] | Pending | TBD | TBD | 7-10 day turnaround |
| Lambda Labs | Research | [date] | Pending | $5K | TBD | Rolling admission |
| RunPod | Startup | [date] | Pending | TBD | TBD | 48hr turnaround |

---

## Sources & Links

### Primary Programs
- [AWS Open Source Credits](https://aws.amazon.com/blogs/opensource/aws-promotional-credits-open-source-projects/)
- [DigitalOcean Open Source](https://www.digitalocean.com/open-source/credits-for-projects)
- [DigitalOcean Hatch](https://www.digitalocean.com/startups)
- [NVIDIA Inception](https://www.nvidia.com/en-us/startups/)
- [Lambda Labs Research](https://lambda.ai/research)
- [RunPod Startup Program](https://www.runpod.io/startup-program)
- [Google Cloud Startups](https://cloud.google.com/startup)
- [Microsoft Azure for OSS](https://cloudblogs.microsoft.com/opensource/2021/09/28/announcing-azure-credits-for-open-source-projects/)

### Free Tiers
- [Groq Console](https://console.groq.com)
- [Hugging Face](https://huggingface.co/pricing)
- [Replicate](https://replicate.com/pricing)
- [Modal](https://modal.com/startups)

### Additional Resources
- [GitHub Sponsors](https://github.com/sponsors) (for ongoing funding)
- [Open Collective](https://opencollective.com/) (fiscal sponsorship)
- [NumFOCUS](https://numfocus.org/) (for scientific computing projects)

---

## Appendix: UnaMentis Project Summary for Applications

Use this summary when applying to credit programs:

> **UnaMentis** is an open source iOS voice AI tutoring application that enables 60-90+ minute learning sessions with sub-500ms latency. Built with Swift 6.0/SwiftUI, it features:
>
> - Real-time voice-based tutoring conversations
> - On-device and cloud AI model support
> - Curriculum-based learning with progress tracking
> - 100% AI-assisted development as a reference implementation
>
> The project serves as both a practical educational tool and a reference implementation for voice-first AI applications. Our server infrastructure requires GPU compute for:
>
> - LLM inference (Mistral 7B / Ollama)
> - Real-time text-to-speech (VibeVoice)
> - Speech-to-text (Whisper)
>
> We seek cloud credits to support development, testing, and community access to the tutoring platform.
