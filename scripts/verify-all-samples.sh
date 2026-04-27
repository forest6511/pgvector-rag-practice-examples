#!/usr/bin/env bash
# scripts/verify-all-samples.sh
# 公開リポのサンプル全体検証エントリポイント。
#
# Tier 1 (API キー不要) + Tier 2 (API キー必要) を順次実行し、
# 章別の動作確認結果を一画面に集約する。
#
# 使い方:
#   bash scripts/verify-all-samples.sh                # Tier1 + Tier2
#   bash scripts/verify-all-samples.sh --tier 1       # Tier1 のみ
#   bash scripts/verify-all-samples.sh --tier 2       # Tier2 のみ
#   bash scripts/verify-all-samples.sh --no-api       # Tier1 のみ (alias)
#   bash scripts/verify-all-samples.sh --skip-e5      # e5 DL をスキップ
#   bash scripts/verify-all-samples.sh --skip-build   # Docker build をスキップ
#
# 終了コード: 0 (全 PASS / 必須は PASS) / 1 (1 つでも FAIL)
#
# Tier 3 (フレームワーク起動 / Grafana / pgvectorscale 実機) は
# docs/manual-verification.md を参照して手動で実施する。

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$ROOT"

# ---------- options ----------
TIER="all"
PASS_THROUGH=()
for arg in "$@"; do
  case "$arg" in
    --tier=1|--tier=2|--tier=all) TIER="${arg#--tier=}" ;;
    --tier)                       shift; TIER="${1:-all}" ;;
    --no-api)                     TIER="1" ;;
    --skip-e5|--skip-build)       PASS_THROUGH+=("$arg") ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
  esac
done

echo "════════════════════════════════════════════════════════"
echo " pgvector-rag-practice-examples — verify-all-samples"
echo "════════════════════════════════════════════════════════"
echo " Tier:  $TIER"
echo " Date:  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo " Repo:  $ROOT"
echo "════════════════════════════════════════════════════════"

T1_RC=0
T2_RC=0

if [[ "$TIER" == "1" || "$TIER" == "all" ]]; then
  bash "$SCRIPT_DIR/verify-tier1.sh" "${PASS_THROUGH[@]}" || T1_RC=$?
fi

if [[ "$TIER" == "2" || "$TIER" == "all" ]]; then
  if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo ""
    echo "════════════════════════════════════════"
    echo "  Tier 2 SKIPPED: OPENAI_API_KEY not set"
    echo "════════════════════════════════════════"
    if [[ "$TIER" == "2" ]]; then T2_RC=2; fi
  else
    bash "$SCRIPT_DIR/verify-tier2.sh" "${PASS_THROUGH[@]}" || T2_RC=$?
  fi
fi

echo ""
echo "════════════════════════════════════════"
echo " Final"
echo "════════════════════════════════════════"
printf " Tier 1: %s\n" "$([[ $T1_RC -eq 0 ]] && echo PASS || echo "FAIL ($T1_RC)")"
printf " Tier 2: %s\n" "$([[ $T2_RC -eq 0 ]] && echo PASS || echo "FAIL ($T2_RC)")"

if [[ $T1_RC -ne 0 || $T2_RC -ne 0 ]]; then exit 1; fi
exit 0
