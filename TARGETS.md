# Benchmark Target Models

Models to be evaluated on the MAGE four-agent pipeline against the
full VerilogEval-V2 set (156 problems).

| Model | Size | Class | Architecture | Reasoning |
|---|---|---|---|---|
| Qwen2.5-Coder-7B | 7B | dense | dense | no |
| CodeV-R1-RL-Qwen-7B | 7B | dense | dense | yes |
| Qwen3.6-27B | 27B | dense | dense | yes |
| Gemma-4-26B-A4B-it | 26B (4B active) | MoE | MoE | yes |
| Qwen3-Coder-30B-A3B | 30B (3.3B active) | MoE | MoE | no |
| Gemma-4-E4B-it | 8B (4.5B eff) | dense PLE | dense PLE | configurable |
