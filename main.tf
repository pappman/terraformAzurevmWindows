provider "azurerm" {
  version = "=1.20.0"
}

terraform {
    backend "azurerm" {
        storage_account_name = "stterraformtfstate"
        container_name       = "terraformtfstate"
        key                  = "terraform.tfstate"
        resource_group_name  = "rgterraformtfstate"
    }
}