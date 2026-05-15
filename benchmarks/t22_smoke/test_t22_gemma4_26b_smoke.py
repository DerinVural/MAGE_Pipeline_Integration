"""
T22 smoke runner — google/gemma-4-26B-A4B-it via vLLM (10 problems).

Mirrors T17A M5 setup: 5 easy + 5 hard.
Pipeline config preserves T19 baseline params except provider=vllm.
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
    "base_url": os.environ.get("VLLM_BASE_URL", "http://localhost:8000/v1"),
    "filter_instance": (
        "^(Prob001_zero|Prob002_m2014_q4i|Prob003_step_one|Prob004_vector2|"
        "Prob005_notgate|Prob119_fsm3|Prob121_2014_q3bfsm|Prob124_rule110|"
        "Prob127_lemmings1|Prob128_fsm_ps2)$"
    ),
    "type_benchmark": "verilog_eval_v2",
    "path_benchmark": "./verilog-eval",
    "run_identifier": "t22_gemma4_26b_smoke",
    "n": 1,
    "temperature": 0.85,
    "top_p": 0.95,
    "max_token": 4096,
    "use_golden_tb_in_mage": True,
    "bypass_tb_gen": True,
    "golden_tb_format": True,
    "key_cfg_path": None,
}


def main():
    args = argparse.Namespace(**args_dict)
    llm = get_llm(
        model=args.model,
        cfg_path=args.key_cfg_path,
        max_token=args.max_token,
        provider=args.provider,
        base_url=args.base_url,
    )
    set_exp_setting(temperature=args.temperature, top_p=args.top_p)
    identifier_head = args.run_identifier
    for i in range(args.n):
        print(f"Round {i+1}/{args.n}")
        args.run_identifier = f"{identifier_head}_{i}"
        run_round(args, llm)


if __name__ == "__main__":
    main()
