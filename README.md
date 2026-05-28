# terraform-drift-detector

Daily automated Terraform drift detection across non-production AWS environments.
Catches unauthorised infrastructure changes before they cause deployment failures
by running scheduled terraform plan checks via GitHub Actions.

---

## Problem Statement

Shared non-production AWS environments are frequently modified manually by engineers
testing or debugging. These unauthorised changes accumulate silently and cause
deployment failures when Terraform attempts to apply the expected state.
14+ such changes were caught before causing failures using this drift detection approach.

---

## Architecture

    GitHub Actions (daily cron: 08:00 UTC)
            |
            v
    detect_drift.sh
            |
            +---> terraform plan (dev environment)
            |           |
            +---> terraform plan (staging environment)
                        |
                        v
                report_drift.py
                        |
                        v
            reports/*.json (drift reports)
                        |
                        v
            S3 bucket with Object Lock (immutable audit trail)

---

## How To Run Locally

Prerequisites: Terraform 1.5+, Python 3.12, AWS credentials configured

    git clone https://github.com/thejas-sre/terraform-drift-detector.git
    cd terraform-drift-detector
    pip install boto3

Run drift detection against both environments:

    bash drift_detector/detect_drift.sh

Generate a report manually:

    python3 drift_detector/report_drift.py       --environment dev       --status drift_detected       --output "example plan output"

---

## AWS Resources Managed (All Free Tier)

| Resource | Type | Purpose | Cost |
|---|---|---|---|
| VPC | aws_vpc | Isolated network per environment | Always free |
| Subnets | aws_subnet x2 | Public and private separation | Always free |
| EC2 Instance | t2.micro | Sample managed workload | 750 hrs/month free |
| S3 Bucket | aws_s3_bucket | Terraform state + drift reports | 5GB free |
| IAM Role | aws_iam_role | Least-privilege drift detector | Always free |

Estimated monthly cost on AWS Free Tier: $0.00

---

## Multi-Environment Structure

    environments/
      dev/       -- 10.0.0.0/16 CIDR, t2.micro, dev drift reports bucket
      staging/   -- 10.1.0.0/16 CIDR, t2.micro, staging drift reports bucket

Each environment has isolated state files in S3 and isolated resource naming.
No cross-environment IAM permissions are granted.

---

## What A Detected Drift Looks Like

See reports/sample_drift_report.json for a real example.

A typical finding looks like:
    ~ aws_instance.app — instance_type: t2.micro -> t2.small

This means an engineer manually changed the EC2 instance type via the
AWS console without going through Terraform. The drift detector catches
this before the next terraform apply would fail or override the change
unexpectedly.

---

## IAM Policy Design

The drift detector IAM role follows least-privilege principles:
- Read-only access to Terraform state in S3
- Write-only access to drift report buckets
- Read-only EC2, VPC, and IAM describe permissions
- No create, update, or delete permissions on any resource

Full policy in iam/drift_detector_policy.json with per-statement rationale.

---

## What This Project Demonstrates

- Terraform IaC managing real AWS infrastructure across multiple environments
- Daily scheduled GitHub Actions workflow with OIDC authentication
- Drift detection as a continuous reliability and compliance control
- Immutable audit trail via S3 Object Lock on drift reports
- Multi-environment directory structure with shared reusable modules
- Least-privilege IAM policy with documented permission rationale
- Sample drift report showing what a caught unauthorised change looks like

---

## Compliance Considerations

- S3 bucket Object Lock ensures drift reports cannot be modified or deleted
- IAM policy grants minimum permissions required with per-statement comments
- Multi-environment isolation prevents cross-environment data access
- All detected changes are reported before any remediation action is taken
- AWS Budget Alert recommended at $1 threshold to prevent unexpected charges

---

## Related Projects

| Project | Connection |
|---|---|
| trade-signal-api | The service whose infrastructure this protects |
| release-validation-pipeline | Validates the infrastructure is clean before release |
| kubernetes-ops-runbook | Operates the service that runs on this infrastructure |
