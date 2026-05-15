"""
T22b — google/gemma-4-26B-A4B-it Full VerilogEval-V2 (canonical MAGE pipeline).

Identical to test_top_agent_gemma4_e4b_bf16_full.py (T19 runner) except:
  - provider: ollama -> vllm
  - model: gemma4:e4b-it-bf16 -> google/gemma-4-26B-A4B-it
  - max_token: 16384 -> 8192          (matches README T22 canonical)
  - run_identifier: t22b_gemma4_26b_full

All other args are upstream/paper defaults so the pipeline is bit-for-bit
equivalent to stable-lab/MAGE. Only the LLM backend differs.

Notably:
  - bypass_tb_gen=False                (TbGenerator runs - upstream behavior)
  - golden_tb_format=False             (upstream pass detection)
  - use_golden_tb_in_mage=True         (paper default - TbGen sees golden TB)
  - n=1, temperature=0.85, top_p=0.95  (paper defaults)
  - AGENT_SAMPLING_OVERRIDES={}        (no per-agent overrides — default)

vLLM endpoint resolved from $VLLM_BASE_URL or http://localhost:8000/v1.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from test_top_agent import run_round  # noqa: E402

from mage.gen_config import get_llm, set_exp_setting  # noqa: E402


args_dict = {
    "provider": "vllm",
    "model": "google/gemma-4-26B-A4B-it",
    "filter_instance": "^Prob.*$",
    "type_benchmark": "verilog_eval_v2",
    "path_benchmark": "./verilog-eval",
    "run_identifier": "t22b_gemma4_26b_full",
    "n": 1,
    "temperature": 0.85,
    "top_p": 0.95,
    "max_token": 8192,
    "use_golden_tb_in_mage": True,
    "bypass_tb_gen": False,
    "golden_tb_format": False,
    "key_cfg_path": None,
}


def main():
    args = argparse.Namespace(**args_dict)
    llm = get_llm(
        model=args.model,
        cfg_path=args.key_cfg_path,
        max_token=args.max_token,
        provider=args.provider,
    )
    set_exp_setting(temperature=args.temperature, top_p=args.top_p)
    identifier_head = args.run_identifier
    for i in range(args.n):
        print(f"Round {i+1}/{args.n}")
        args.run_identifier = f"{identifier_head}_{i}"
        run_round(args, llm)


if __name__ == "__main__":
    main()
