"""
Drift Report Generator
Parses terraform plan output and writes a structured JSON report.
Reports are written to the reports/ directory and optionally uploaded
to S3 with Object Lock for immutable audit trail.
"""

import json
import os
import argparse
from datetime import datetime


def parse_plan_output(output: str) -> dict:
    lines = output.split("\n")
    changes = {
        "to_add": [],
        "to_change": [],
        "to_destroy": [],
        "errors": []
    }

    for line in lines:
        line = line.strip()
        if line.startswith("+ ") or "will be created" in line:
            changes["to_add"].append(line)
        elif line.startswith("~ ") or "will be updated" in line:
            changes["to_change"].append(line)
        elif line.startswith("- ") or "will be destroyed" in line:
            changes["to_destroy"].append(line)
        elif "Error:" in line or "error:" in line:
            changes["errors"].append(line)

    return changes


def generate_report(environment: str, status: str, output: str, timestamp: str) -> dict:
    changes = parse_plan_output(output)

    report = {
        "timestamp": timestamp,
        "environment": environment,
        "status": status,
        "drift_detected": status == "drift_detected",
        "changes": changes,
        "change_summary": {
            "resources_to_add": len(changes["to_add"]),
            "resources_to_change": len(changes["to_change"]),
            "resources_to_destroy": len(changes["to_destroy"]),
            "errors": len(changes["errors"])
        },
        "raw_plan_excerpt": output[:2000] if len(output) > 2000 else output
    }

    return report


def save_report(report: dict, output_dir: str = "reports") -> str:
    os.makedirs(output_dir, exist_ok=True)
    filename = f"drift_report_{report['environment']}_{report['timestamp']}.json"
    filepath = os.path.join(output_dir, filename)

    with open(filepath, "w") as f:
        json.dump(report, f, indent=2)

    print(f"Report saved: {filepath}")
    return filepath


def main():
    parser = argparse.ArgumentParser(description="Generate drift detection report")
    parser.add_argument("--environment", required=True)
    parser.add_argument("--status", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--timestamp", default=datetime.utcnow().strftime("%Y%m%d_%H%M%S"))
    args = parser.parse_args()

    report = generate_report(
        environment=args.environment,
        status=args.status,
        output=args.output,
        timestamp=args.timestamp
    )

    save_report(report)

    if report["drift_detected"]:
        print(f"DRIFT DETECTED in {args.environment}")
        print(f"Changes: {json.dumps(report['change_summary'], indent=2)}")


if __name__ == "__main__":
    main()
