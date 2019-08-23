# terraform-azurerm-kube
Terraform module for provisioning Kubernetes Cluster on Azure


## Example

```
resource "azurerm_resource_group" "rg" {
    name     = "kubernetes-rg"
    location = "China North 2"
}

module "kubernetes" {
  source              = "git::https://github.com/42devops/terraform-azurerm-kube.git"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnet_id      = data.terraform_remote_state.vnet.outputs.subnets.app-subnet.id
  hostname_prefix     = "k8svm"

  admin_username = "azureuser"
  admin_password = "password"
  ssh_key        = file("~/.ssh/id_rsa.pub")

  kube_master_lb_enabled = false
  kube_master_count      = 1
  kube_master_size       = "Standard_D2s_v3"
  kube_minion_count      = 3
  kube_minion_size       = "Standard_D4s_v3"

  tags = {
    environment = "dev"
  }
}
```
