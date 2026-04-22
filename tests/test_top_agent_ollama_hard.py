import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from test_top_agent import run_round  # noqa: E402

from mage.gen_config import get_llm, set_exp_setting  # noqa: E402

args_dict = {
    "provider": "ollama",
    "model": "qwen2.5-coder:32b",
    "filter_instance": "^(Prob121_2014_q3bfsm|Prob124_rule110|Prob127_lemmings1|Prob128_fsm_ps2|Prob119_fsm3)$",
    "type_benchmark": "verilog_eval_v2",
    "path_benchmark": "./verilog-eval",
    "run_identifier": "ollama_32b_hard",
    "n": 1,
    "temperature": 0.85,
    "top_p": 0.95,
    "max_token": 4096,
    "use_golden_tb_in_mage": True,
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
