"""
T22b shard runner — google/gemma-4-26B-A4B-it Full VerilogEval-V2.

Env-parametric: reads SHARD_FILTER and SHARD_ID from environment.
Identical canonical config to test_t22b_gemma4_26b_full.py, only the
filter_instance and run_identifier vary per shard.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from test_top_agent import run_round  # noqa: E402

from mage.gen_config import get_llm, set_exp_setting  # noqa: E402


SHARD_FILTER = os.environ["SHARD_FILTER"]   # e.g. ^Prob(00[1-9]|0[1-3][0-9])_.*$
SHARD_ID = os.environ["SHARD_ID"]           # e.g. shard1

args_dict = {
    "provider": "vllm",
    "model": "google/gemma-4-26B-A4B-it",
    "filter_instance": SHARD_FILTER,
    "type_benchmark": "verilog_eval_v2",
    "path_benchmark": "./verilog-eval",
    "run_identifier": f"t22b_gemma4_26b_{SHARD_ID}",
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
