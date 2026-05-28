#!/bin/bash
# Terraform Drift Detection Script
# Runs terraform plan across all environments and captures any detected changes.
# Exit code 0 = no drift detected
# Exit code 1 = drift detected or error

set -e

ENVIRONMENTS=("dev" "staging")
DRIFT_DETECTED=0
REPORT_DIR="reports"
TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S")

mkdir -p "$REPORT_DIR"

echo "Starting drift detection — $(date -u)"
echo "Environments: ${ENVIRONMENTS[*]}"
echo ""

for ENV in "${ENVIRONMENTS[@]}"; do
    echo "=========================================="
    echo "Checking environment: $ENV"
    echo "=========================================="

    ENV_DIR="environments/$ENV"

    if [ ! -d "$ENV_DIR" ]; then
        echo "WARNING: Environment directory $ENV_DIR not found — skipping"
        continue
    fi

    cd "$ENV_DIR"

    echo "Initialising Terraform..."
    terraform init -backend=false -input=false -no-color 2>&1 | tail -3

    echo "Running terraform plan..."
    PLAN_OUTPUT=$(terraform plan -detailed-exitcode -no-color -input=false 2>&1 || true)
    PLAN_EXIT=$?

    cd - > /dev/null

    # Exit codes: 0=no changes, 1=error, 2=changes detected
    if [ $PLAN_EXIT -eq 0 ]; then
        echo "CLEAN: No drift detected in $ENV"
        STATUS="clean"
    elif [ $PLAN_EXIT -eq 2 ]; then
        echo "DRIFT DETECTED in $ENV"
        echo "$PLAN_OUTPUT" | grep -E "^  [+~-]|will be|must be" | head -20
        STATUS="drift_detected"
        DRIFT_DETECTED=1
    else
        echo "ERROR running terraform plan in $ENV"
        STATUS="error"
        DRIFT_DETECTED=1
    fi

    python3 drift_detector/report_drift.py \
        --environment "$ENV" \
        --status "$STATUS" \
        --output "$PLAN_OUTPUT" \
        --timestamp "$TIMESTAMP"

    echo ""
done

if [ $DRIFT_DETECTED -eq 1 ]; then
    echo "RESULT: Drift or errors detected — see reports/ for details"
    exit 1
else
    echo "RESULT: All environments clean — no drift detected"
    exit 0
fi
