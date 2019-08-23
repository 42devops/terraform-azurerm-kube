output "kube_masters_lb_private_ip" {
  description = "private ip addresses of Load Balancer in front of kubernetes master nodes"
  value       = azurerm_lb.kubernetes_lb.*.private_ip_address
}

output "kube_masters_private_ip" {
  description = "private ip addresses of kubernetes master nodes"
  value       = slice(azurerm_network_interface.kubernetes_network_interface.*.private_ip_address, 0, var.kube_master_count)
}

output "kube_minions_private_ip" {
  description = "private ip addresses of kubernetes minion nodes"
  value       = slice(azurerm_network_interface.kubernetes_network_interface.*.private_ip_address, var.kube_master_count, var.kube_master_count + var.kube_minion_count)
}
