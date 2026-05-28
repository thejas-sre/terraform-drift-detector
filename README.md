# terraform-drift-detector

Daily automated Terraform drift detection across non-production AWS environments.
Catches unauthorised infrastructure changes before they cause deployment failures
by running scheduled terraform plan checks via GitHub Actions.

## Status

> Work in progress — full implementation coming shortly.

## What This Project Demonstrates

- Terraform IaC managing real AWS infrastructure (VPC, EC2, S3, IAM)
- Daily scheduled GitHub Actions workflow with OIDC authentication
- Drift detection as a continuous reliability and compliance control
- Immutable audit trail — drift reports written to S3 with Object Lock enabled
- Multi-environment structure — dev and staging with shared modules
- Least-privilege IAM policy with documented permission rationale

## Infrastructure (AWS Free Tier)

| Resource | Purpose |
|---|---|
| VPC + Subnets | Isolated non-prod network |
| t2.micro EC2 | Sample managed workload |
| S3 + Object Lock | Remote state + immutable drift reports |
| IAM Role | Least-privilege drift detector credentials |

## Stack

Terraform · AWS · GitHub Actions · Python · Bash
