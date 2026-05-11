import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from test_top_agent import run_round  # noqa: E402

from mage.gen_config import get_llm, set_exp_setting  # noqa: E402

args_dict = {
    "provider": "ollama",
    "model": "gemma4:e4b-it-bf16",
    "filter_instance": "^Prob.*$",
    "type_benchmark": "verilog_eval_v2",
    "path_benchmark": "./verilog-eval",
    "run_identifier": "t19_gemma4_e4b_bf16_full",
    "n": 1,
    "temperature": 0.85,
    "top_p": 0.95,
    "max_token": 16384,
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
