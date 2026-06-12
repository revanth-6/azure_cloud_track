terraform {
  backend "azurerm" {
    resource_group_name  = "rg-medishift-tfstate"
    storage_account_name = "stmedishifttfstate"
    container_name       = "tfstate"
    key                  = "medishift.terraform.tfstate"
  }
}
