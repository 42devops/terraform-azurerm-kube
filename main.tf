provider "azurerm" {
  version = ">=1.25.0"
}

resource "azurerm_availability_set" "k8s_master_as" {
  name                         = "kubernetes-master-as"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  managed                      = true
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5

  tags = "${var.tags}"
}

resource "azurerm_availability_set" "k8s_minion_as" {
  name                         = "kubernetes-minion-as"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  managed                      = true
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5

  tags = "${var.tags}"
}

resource "azurerm_network_interface" "kubernetes_network_interface" {
  count = "${var.kube_master_count + var.kube_minion_count}"

  name                = "${format("%s%02d-nc01", var.hostname_prefix, count.index + 1)}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "${format("%s%02d-nc01-ipcfg", var.hostname_prefix, count.index + 1)}"
    subnet_id                     = "${var.vnet_subnet_id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags = "${var.tags}"
}

resource "azurerm_managed_disk" "kubernetes_master_managed_disk" {
  count                = "${var.kube_master_count}"
  name                 = "${format("%s%02d-data-disk", var.hostname_prefix, count.index + 1)}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  create_option        = "Empty"
  disk_size_gb         = "${var.kube_master_disk_size}"
  storage_account_type = "${var.kube_master_ssd_enabled ? "Premium_LRS" : "Standard_LRS"}"

  tags = "${var.tags}"
}

resource "azurerm_virtual_machine" "kubernetes_master" {
  count                 = "${var.kube_master_count}"
  name                  = "${format("%s%02d", var.hostname_prefix, count.index + 1)}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.kubernetes_network_interface.*.id, count.index)}"]
  vm_size               = "${var.kube_master_size}"
  availability_set_id   = "${azurerm_availability_set.k8s_master_as.id}"

  storage_image_reference {
    publisher = "SUSE"
    offer     = "SLES"
    sku       = "12-SP4"
    version   = "2019.05.20"
  }

  storage_os_disk {
    name              = "${format("%s%02d-os-disk", var.hostname_prefix, count.index + 1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = 30
    managed_disk_type = "Premium_LRS"
    os_type           = "Linux"
  }

  storage_data_disk {
    name                 = "${format("%s%02d-data-disk", var.hostname_prefix, count.index + 1)}"
    caching              = "None"
    create_option        = "Attach"
    disk_size_gb         = "${var.kube_master_disk_size}"
    storage_account_type = "${var.kube_master_ssd_enabled ? "Premium_LRS" : "Standard_LRS"}"
    managed_disk_id      = "${element(azurerm_managed_disk.kubernetes_master_managed_disk.*.id, count.index)}"
    lun                  = 0
  }

  os_profile {
    computer_name  = "${format("%s%02d", var.hostname_prefix, count.index + 1)}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("./data/ssh_key")}"
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${var.diagnostics_uri}"
  }

  tags = "${merge(var.tags, { "roles" = "etcd,kube-master" })}"
}

resource "azurerm_managed_disk" "kubernetes_minion_managed_disk" {
  count                = "${var.kube_minion_count}"
  name                 = "${format("%s%02d-data-disk", var.hostname_prefix, count.index + var.kube_master_count + 1)}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  create_option        = "Empty"
  disk_size_gb         = "${var.kube_minion_disk_size}"
  storage_account_type = "${var.kube_minion_ssd_enabled ? "Premium_LRS" : "Standard_LRS"}"

  tags = "${var.tags}"
}

resource "azurerm_virtual_machine" "kubernetes_minion" {
  count                 = "${var.kube_minion_count}"
  name                  = "${format("%s%02d", var.hostname_prefix, count.index + var.kube_master_count + 1)}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.kubernetes_network_interface.*.id, count.index + var.kube_master_count)}"]
  vm_size               = "${var.kube_minion_size}"
  availability_set_id   = "${azurerm_availability_set.k8s_minion_as.id}"

  storage_image_reference {
    publisher = "SUSE"
    offer     = "SLES"
    sku       = "12-SP4"
    version   = "2019.05.20"
  }

  storage_os_disk {
    name              = "${format("%s%02d-os-disk", var.hostname_prefix, count.index + var.kube_master_count + 1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = 30
    managed_disk_type = "Premium_LRS"
    os_type           = "Linux"
  }

  storage_data_disk {
    name                 = "${format("%s%02d-data-disk", var.hostname_prefix, count.index + var.kube_master_count + 1)}"
    caching              = "None"
    create_option        = "Attach"
    disk_size_gb         = "${var.kube_minion_disk_size}"
    storage_account_type = "${var.kube_minion_ssd_enabled ? "Premium_LRS" : "Standard_LRS"}"
    managed_disk_id      = "${element(azurerm_managed_disk.kubernetes_minion_managed_disk.*.id, count.index)}"
    lun                  = 0
  }

  os_profile {
    computer_name  = "${format("%s%02d", var.hostname_prefix, count.index + var.kube_master_count + 1)}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("./data/ssh_key")}"
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${var.diagnostics_uri}"
  }

  tags = "${merge(var.tags, { "roles" = "kube-minion" })}"
}

# Azure Load Balancer

resource "azurerm_lb" "kubernetes_lb" {
  count               = "${var.kube_master_lb_enabled}"
  name                = "${var.kube_master_lb_name}"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"

  frontend_ip_configuration {
    name                          = "${format("%s-frontend-ip", var.kube_master_lb_name)}"
    subnet_id                     = "${"${var.vnet_subnet_id}"}"
    private_ip_address_allocation = "Dynamic"
  }

  tags = "${var.tags}"
}

resource "azurerm_lb_backend_address_pool" "kubernetes_lb_backend" {
  count               = "${var.kube_master_lb_enabled}"
  name                = "${format("%s-backend", var.kube_master_lb_name)}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${element(azurerm_lb.kubernetes_lb.*.id, count.index)}"
}

resource "azurerm_lb_probe" "kubernetes_lb_http_probe" {
  count               = "${var.kube_master_lb_enabled}"
  name                = "${format("%s-http-probe", var.kube_master_lb_name)}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${element(azurerm_lb.kubernetes_lb.*.id, count.index)}"
  protocol            = "http"
  port                = "80"
  request_path        = "/healthz"
  interval_in_seconds = "300"
}

resource "azurerm_lb_rule" "kubernetes_lb_rule_with_http_probe" {
  count                          = "${var.kube_master_lb_enabled}"
  name                           = "${format("%s-rule", var.kube_master_lb_name)}"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${element(azurerm_lb.kubernetes_lb.*.id, count.index)}"
  protocol                       = "tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "${format("%s-frontend_ip", var.kube_master_lb_name)}"
  backend_address_pool_id        = "${element(azurerm_lb_backend_address_pool.kubernetes_lb_backend.*.id, count.index)}"
  probe_id                       = "${element(azurerm_lb_probe.kubernetes_lb_http_probe.*.id, count.index)}"
}

resource "azurerm_network_interface_backend_address_pool_association" "kubernetes_lb" {
  count                   = "${var.kube_master_lb_enabled ? var.kube_master_count : 0}"
  network_interface_id    = "${element(azurerm_network_interface.kubernetes_network_interface.*.id, count.index)}"
  ip_configuration_name   = "${format("%s%02d-nc01-ipcfg", var.hostname_prefix, count.index + 1)}"
  backend_address_pool_id = "${element(azurerm_lb_backend_address_pool.kubernetes_lb_backend.*.id, count.index)}"
}
