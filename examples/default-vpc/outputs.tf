output "ssh_private_key" {
  value = module.cluster.ssh_private_key
}

output "public_dns" {
  value = module.cluster.public_dns[0]
}
