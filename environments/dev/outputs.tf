output "vpc_id" {
  description = "Dev VPC ID"
  value       = module.vpc.vpc_id
}

output "instance_id" {
  description = "Dev EC2 instance ID"
  value       = module.compute.instance_id
}

output "drift_reports_bucket" {
  description = "S3 bucket for drift reports"
  value       = aws_s3_bucket.drift_reports.bucket
}
