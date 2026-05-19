terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.71.0"
    }
  }
}

provider "azurerm" {
    features {}
  # Configuration options
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources" 
  location = "Central India"
}
