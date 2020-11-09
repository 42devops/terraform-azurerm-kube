variable "resource_group_name" {
  description = "Specifies the name of the Resource Group in which the Virtual Machine should exist."
}

variable "location" {
  description = "Specifies the Azure Region where the Virtual Machine exists."
}

## VM variables

variable "vnet_subnet_id" {
  description = "The subnet id of the virtual network where the virtual machines will reside."
}

variable "hostname_prefix" {
  description = "Prefix of local name of the VM"
}

variable "admin_username" {
  description = "Specifies the name of the local administrator account."
  default     = "azureuser"
}

variable "admin_password" {
  description = "The password associated with the local administrator account."
}

## K8S variables

variable "kube_master_lb_enabled" {
  description = "Specifies if Azure Load Balancer is enabled in front of Kubernetes master nodes"
  default     = false
}

variable "kube_master_lb_name" {
  description = "Specifies the name of the Load Balancer in front of Kubernetes master nodes."
  default     = "kubernetes-lb"
}

variable "kube_master_count" {
  description = "Specifies the count of Kubernetes master nodes"
  default     = 1
}

variable "kube_master_ssd_enabled" {
  description = "Specifies if SSD data disk is enabled on Kubernetes master nodes"
  default     = false
}

variable "kube_master_disk_size" {
  description = "Specifies the size of the data disk in gigabytes for Kubernetes master nodes"
  default     = 64
}

variable "kube_master_size" {
  description = "Specifies the size of the Virtual Machine that running Kubernetes master nodes."
}

variable "kube_minion_count" {
  description = "Specifies the count of Kubernetes minion nodes"
  default     = 2
}

variable "kube_minion_ssd_enabled" {
  description = "Specifies if SSD data disk is enabled on Kubernetes minion nodes"
  default     = true
}

variable "kube_minion_disk_size" {
  description = "Specifies the size of the data disk in gigabytes for Kubernetes minion nodes"
  default     = 128
}

variable "kube_minion_size" {
  description = "Specifies the size of the Virtual Machine that running Kubernetes minion nodes."
}

variable "ssh_key" {
  description = "The public key to be used for ssh access to the VM."
}

variable "tags" {
  type        = map
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}
