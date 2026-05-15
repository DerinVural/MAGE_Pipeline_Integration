#!/bin/bash
#SBATCH -A proj68
#SBATCH -p kolyoz-cuda
#SBATCH --qos=normal
#SBATCH -J t22c
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=16
#SBATCH --time=23:59:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -uo pipefail

# Required env (set via sbatch --export):
#   MODEL_NAME       HF model identifier (e.g. Qwen/Qwen2.5-Coder-7B-Instruct)
#   MODEL_PATH       Local path to model weights ($WS/models/<dir>)
#   SHARD_FILTER     regex for filter_instance
#   SHARD_ID         shard1..4
#   RUN_ID_PREFIX    e.g. t22c_qwen25coder7b
#   MAX_TOKEN        (optional, default 8192)
#   VLLM_PORT        unique per shard
: "${MODEL_NAME:?required}"
: "${MODEL_PATH:?required}"
: "${SHARD_FILTER:?required}"
: "${SHARD_ID:?required}"
: "${RUN_ID_PREFIX:?required}"
: "${VLLM_PORT:?required}"
MAX_TOKEN=${MAX_TOKEN:-8192}

echo "=========================================="
echo "JOB:     $SLURM_JOB_ID  ($SLURM_JOB_NAME / $SHARD_ID)"
echo "NODE:    $(hostname)"
echo "GPU:     $CUDA_VISIBLE_DEVICES"
echo "MODEL:   $MODEL_NAME"
echo "PATH:    $MODEL_PATH"
echo "FILTER:  $SHARD_FILTER"
echo "VLLM_PORT: $VLLM_PORT  MAX_TOKEN: $MAX_TOKEN"
echo "START:   $(date -Is)"
echo "=========================================="

# Environment
source /etc/profile.d/modules.sh
module purge
module load apps/truba-ai/gpu-2024.0
WS=/arf/scratch/merdal/mage_bench
source $WS/venv/bin/activate
export PATH=$WS/iverilog_env/bin:$PATH
export PYTHONPATH=$WS/repo/src:${PYTHONPATH:-}

# Offline HF (models pre-downloaded)
export HF_HOME=$WS/hf_cache
export TRANSFORMERS_OFFLINE=1
export HF_HUB_OFFLINE=1

# Unique caches per job
export VLLM_CACHE_ROOT=$WS/.vllm_cache_${RUN_ID_PREFIX}_${SHARD_ID}
mkdir -p $VLLM_CACHE_ROOT
export TMPDIR=$WS/.tmp_${RUN_ID_PREFIX}_${SHARD_ID}
mkdir -p $TMPDIR

echo "--- env check ---"
which python
python -c "import vllm; print('vllm', vllm.__version__)"
iverilog -V | head -1

# Run dir
RUN_DIR=$WS/runs/${RUN_ID_PREFIX}_${SHARD_ID}
mkdir -p $RUN_DIR
cd $RUN_DIR

ln -snf $WS/repo/verilog-eval verilog-eval
cp -f $WS/repo/tests/test_top_agent.py .
cp -f $WS/test_t22c_multi_shard.py .

# vLLM serve (background)
echo "=== Starting vLLM server ($MODEL_NAME on port $VLLM_PORT) ==="
nohup vllm serve $MODEL_PATH \
  --served-model-name $MODEL_NAME \
  --port $VLLM_PORT \
  --dtype bfloat16 \
  --max-model-len 32768 \
  --enforce-eager \
  --enable-prefix-caching \
  --max-num-seqs 256 \
  --gdn-prefill-backend triton \
  --reasoning-parser qwen3 \
  > vllm_serve.log 2>&1 &
VLLM_PID=$!
echo "vLLM PID: $VLLM_PID"

# Wait for ready (up to 15 min — large models slow cold start under contention)
echo "=== Waiting for vLLM ready ==="
for i in $(seq 1 180); do
  if curl -fsS http://localhost:$VLLM_PORT/v1/models > /dev/null 2>&1; then
    echo "vLLM ready after $((i*5))s"
    break
  fi
  if ! kill -0 $VLLM_PID 2>/dev/null; then
    echo "ERROR: vLLM process died before ready"
    tail -50 vllm_serve.log
    exit 1
  fi
  sleep 5
done

curl -s http://localhost:$VLLM_PORT/v1/models | python3 -m json.tool | head -5

# Run shard
echo "=== Running shard ==="
export VLLM_BASE_URL=http://localhost:$VLLM_PORT/v1
export MODEL_NAME SHARD_FILTER SHARD_ID RUN_ID_PREFIX MAX_TOKEN
python test_t22c_multi_shard.py
EXIT_CODE=$?

# Cleanup
echo "=== Cleanup ==="
kill $VLLM_PID 2>/dev/null
wait $VLLM_PID 2>/dev/null
echo "=== END $(date -Is) exit=$EXIT_CODE ==="
exit $EXIT_CODE
