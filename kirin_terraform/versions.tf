# =============================================================================
# Terraform / プロバイダーのバージョン指定
# Day2 Lab 0: Azure AI Foundry 環境構築
# =============================================================================
terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.38"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.5"
    }
  }
}
