"""
T22c multi-model shard runner — full MAGE pipeline benchmark on multiple
open-weight models via vLLM, identical canonical config to T22b.

Env-parametric: reads MODEL_NAME, SHARD_FILTER, SHARD_ID, RUN_ID_PREFIX from env.
Per-model max_token also overrideable via MAX_TOKEN (default 8192).

Identical pipeline behavior to T22b (canonical):
  bypass_tb_gen=False, golden_tb_format=False, use_golden_tb_in_mage=True
  n=1, temperature=0.85, top_p=0.95
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from test_top_agent import run_round  # noqa: E402

from mage.gen_config import get_llm, set_exp_setting  # noqa: E402


MODEL_NAME = os.environ["MODEL_NAME"]               # HF/served name
SHARD_FILTER = os.environ["SHARD_FILTER"]           # regex
SHARD_ID = os.environ["SHARD_ID"]                   # shard1..4
RUN_ID_PREFIX = os.environ["RUN_ID_PREFIX"]         # e.g. t22c_qwen25coder7b
MAX_TOKEN = int(os.environ.get("MAX_TOKEN", 8192))


args_dict = {
    "provider": "vllm",
    "model": MODEL_NAME,
    "filter_instance": SHARD_FILTER,
    "type_benchmark": "verilog_eval_v2",
    "path_benchmark": "./verilog-eval",
    "run_identifier": f"{RUN_ID_PREFIX}_{SHARD_ID}",
    "n": 1,
    "temperature": 0.85,
    "top_p": 0.95,
    "max_token": MAX_TOKEN,
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
