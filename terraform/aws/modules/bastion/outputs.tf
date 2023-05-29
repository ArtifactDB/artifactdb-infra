output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "The private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "bastion_security_group_id" {
  description = "The security group ID of the bastion host"
  value       = aws_security_group.bastion_sg.id
}

output "bastion_private_key" {
  description = "The private key for the bastion host"
  value       = var.private_key
  sensitive   = true
}

output "bastion_ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ${local_sensitive_file.bastion_private_key.filename} ubuntu@${aws_instance.bastion.private_ip}"
}