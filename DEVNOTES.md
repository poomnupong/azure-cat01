# Development notes

This document contains development backstory, reference to resources, reasons behind development decisions, and how did we get to this point.

## Azure Terraform provider use of environment variables

[Source: Terraform azurerm provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

The azurerm provider needs credential information to authenticate itself. These values can be set in azurerm provider configuration. In Github Actions, following shell environment variables are used to provide these values to Terraform runtime. Note that these environment variable names are hard-coded.

| Environment Variable | Content |
| --- | --- |
| ARM_CLIENT_ID | App ID (Client ID) of a service principal, accessible from "App Registration" menu on Entra ID of your tenant |
| ARM_CLIENT_SECRET | Client secret of a service principal |
| ARM_TENANT_ID | Your Azure AD / Entra ID tenant ID |
| ARM_SUBSCRIPTION_ID | Your Azure subscription ID |


This repository is using Azure Storage Account to store Terraform state. We are also passing these information as environment varilables. Name of these environment varilables are arbitrary.

| Environment Variable | Content |
| --- | --- |
| TFSTATE_RESOURCE_GROUP | Azure resource group containing the given storage account |
| TFSTATE_STORAGE_ACCOUNT | Name of the storage account being used to store state |
| TFSTATE_CONTAINER_NAME | Name of container in the givenstorage account |

