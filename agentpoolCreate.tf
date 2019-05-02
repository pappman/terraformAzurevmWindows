resource "azurerm_resource_group" "rgterraformautomation" {
    name     = "rgterraform"
    location = "eastus"

    tags {
        environment = "terraform"
    }
}

resource "azurerm_virtual_network" "terraformnetwork" {
    name                = "terraformnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.rgterraformautomation.name}"

    tags {
        environment = "terraform"
    }
}

resource "azurerm_subnet" "terraformsubnet" {
    name                 = "terraformsubnet"
    resource_group_name  = "${azurerm_resource_group.rgterraformautomation.name}"
    virtual_network_name = "${azurerm_virtual_network.terraformnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "terraformpublicip" {
    name                         = "terraformpublicip"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.rgterraformautomation.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "terraform"
    }
}

resource "azurerm_network_interface" "terraformnic" {
    name                = "terraformnic"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.rgterraformautomation.name}"
    network_security_group_id = "${azurerm_network_security_group.terraformnsg.id}"

    ip_configuration {
        name                          = "terraformNicConfiguration"
        subnet_id                     = "${azurerm_subnet.terraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.terraformpublicip.id}"
    }

    tags {
        environment = "terraform"
    }
}

resource "azurerm_network_security_group" "terraformnsg" {
    name                = "terraformnsg"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.rgterraformautomation.name}"

    security_rule {
        name                       = "RDP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "terraform"
    }
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.rgterraformautomation.name}"
    }

    byte_length = 8
}

resource "azurerm_storage_account" "terraformstorageaccount" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.rgterraformautomation.name}"
    location            = "eastus"
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags {
        environment = "terraform"
    }
}

resource "azurerm_virtual_machine" "jmetervm" {
    name                  = "jmetervm"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.rgterraformautomation.name}"
    network_interface_ids = ["${azurerm_network_interface.terraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "OsDiskJmeter"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsDesktop"
        offer     = "Windows-10"
        sku       = "rs4-pro"
        version   = "latest"
    }

    os_profile {
        computer_name  = "jmetervm"
        admin_username = "pdvcloud"
        admin_password = "pdvcloud@2018"
    }

    os_profile_windows_config {
        enable_automatic_upgrades = false
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.terraformstorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "terraform"
    }
}