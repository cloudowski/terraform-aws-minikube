output "ssh_private_key" {
  description = "SSH private key generated for the instance"
  value       = tls_private_key.this.private_key_pem
}

output "public_ip" {
  description = "Public IP name of the instance"
  value       = module.node.public_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = module.node.public_dns
}

output "kubeconfig" {
  description = "Kubeconfig content"
  value       = sshcommand_command.get_kubeconfig.result
}
