#!/bin/bash
#SBATCH -A proj68
#SBATCH -p kolyoz-cuda
#SBATCH --qos=normal
#SBATCH -J t22b
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=16
#SBATCH --time=23:59:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -uo pipefail

# Env vars expected (set by sbatch --export or environment):
#   SHARD_FILTER      regex for filter_instance
#   SHARD_ID          short name (shard1..4)
: "${SHARD_FILTER:?SHARD_FILTER env var required}"
: "${SHARD_ID:?SHARD_ID env var required}"

echo "=========================================="
echo "JOB:    $SLURM_JOB_ID  ($SLURM_JOB_NAME / $SHARD_ID)"
echo "NODE:   $(hostname)"
echo "GPUS:   $CUDA_VISIBLE_DEVICES"
echo "FILTER: $SHARD_FILTER"
echo "START:  $(date -Is)"
echo "=========================================="

# Environment
source /etc/profile.d/modules.sh
module purge
module load apps/truba-ai/gpu-2024.0
WS=/arf/scratch/merdal/mage_bench
source $WS/venv/bin/activate
export PATH=$WS/iverilog_env/bin:$PATH
export PYTHONPATH=$WS/repo/src:${PYTHONPATH:-}

# Offline HF
export HF_HOME=$WS/hf_cache
export TRANSFORMERS_OFFLINE=1
export HF_HUB_OFFLINE=1

# vLLM cache to scratch
export VLLM_CACHE_ROOT=$WS/.vllm_cache_$SHARD_ID
mkdir -p $VLLM_CACHE_ROOT
export TMPDIR=$WS/.tmp_$SHARD_ID
mkdir -p $TMPDIR

echo "--- iverilog ---"; iverilog -V | head -2
echo "--- python ---"; which python; python -c "import vllm, torch; print('vllm', vllm.__version__, 'torch', torch.__version__)"

# Run dir (shard-specific)
RUN_DIR=$WS/runs/t22b_${SHARD_ID}
mkdir -p $RUN_DIR
cd $RUN_DIR

ln -snf $WS/repo/verilog-eval verilog-eval
cp -f $WS/repo/tests/test_top_agent.py .
cp -f $WS/test_t22b_gemma4_26b_shard.py .

MODEL_PATH=$WS/models/gemma-4-26B-A4B-it

# Each shard uses a UNIQUE port so they don't collide if scheduled on same node
case "$SHARD_ID" in
  shard1) VLLM_PORT=8001 ;;
  shard2) VLLM_PORT=8002 ;;
  shard3) VLLM_PORT=8003 ;;
  shard4) VLLM_PORT=8004 ;;
  *) VLLM_PORT=8000 ;;
esac
echo "vLLM port: $VLLM_PORT"

# vLLM server (background)
echo "=== Starting vLLM server ==="
nohup vllm serve $MODEL_PATH \
  --served-model-name google/gemma-4-26B-A4B-it \
  --port $VLLM_PORT \
  --dtype bfloat16 \
  --max-model-len 32768 \
  --enforce-eager \
  --enable-prefix-caching \
  > vllm_serve.log 2>&1 &
VLLM_PID=$!
echo "vLLM PID: $VLLM_PID"

# Wait for ready
echo "=== Waiting for vLLM ready ==="
for i in $(seq 1 120); do
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

# Sanity show
curl -s http://localhost:$VLLM_PORT/v1/models | python3 -m json.tool | head -5

# Run shard
echo "=== Running shard $SHARD_ID ==="
export VLLM_BASE_URL=http://localhost:$VLLM_PORT/v1
export SHARD_FILTER SHARD_ID
python test_t22b_gemma4_26b_shard.py
EXIT_CODE=$?

# Cleanup
echo "=== Cleanup ==="
kill $VLLM_PID 2>/dev/null
wait $VLLM_PID 2>/dev/null
echo "=== END $(date -Is) ==="
echo "Exit code: $EXIT_CODE"
exit $EXIT_CODE
