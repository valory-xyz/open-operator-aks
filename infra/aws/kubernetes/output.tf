output "instance_id" {
  description = "module.aws_cluster.worker_security_groups"
  value       = module.aws_cluster.worker_security_groups
}

output "instance_public_ip" {
  description = "module.aws_cluster.worker_target_group_http"
  value       = module.aws_cluster.worker_target_group_http
}
