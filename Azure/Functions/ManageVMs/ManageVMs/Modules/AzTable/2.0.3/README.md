
# AzureRmStorageTable
Repository for a sample module to manipulate Azure Storage Table rows/entities.
For a complete documentation with examples, troubleshooting guide, etc. , please refer to [this](./docs/README.md) link.

## Build Status per Branch

### staging
[![Build Status](https://dev.azure.com/paulomarquesc/AzureRmStorage/_apis/build/status/paulomarquesc.AzureRmStorageTable?branchName=staging)](https://dev.azure.com/paulomarquesc/AzureRmStorage/_build/latest?definitionId=4&branchName=staging)

### master
[![Build Status](https://dev.azure.com/paulomarquesc/AzureRmStorage/_apis/build/status/paulomarquesc.AzureRmStorageTable?branchName=staging)](https://dev.azure.com/paulomarquesc/AzureRmStorage/_build/latest?definitionId=4&branchName=master)

This module supports only *Azure Storage Tables*.

This module now works with PS 5.1, and PS 6 (core) on Windows and Linux.

## Requirements

Minimum requirements are (these are covered if you install the full Az module version 1.6 or greater):

* Az.Storage - 1.1.0 or greater
* Az.Resources - 1.2.0 or greater

> Note: The previous PowerShell module (AzureRM) is not supported on this newer version.

## Quick Setup
1. In a Windows Server 2016/Windows 10 execute the following cmdlets in order to install required modules
    ```powershell
    Install-Module Az.Resources -AllowClobber -Force
    Install-Module Az.Storage -AllowClobber -Force
    ```
    
2. Install AzureRmStorageTable
    ```powershell
    Install-Module AzureRmStorageTable
    ```

Below you will get the help content of every function that is exposed through the AzureRmStorageTable module:

* [Add-AzTableRow](docs/Add-AzTableRow.md)
* [Get-AzTableRow](docs/Get-AzTableRow.md)
* [Get-AzTableRowAll](docs/Get-AzTableRowAll.md)
* [Get-AzTableRowByColumnName](docs/Get-AzTableRowByColumnName.md)
* [Get-AzTableRowByCustomFilter](docs/Get-AzTableRowByCustomFilter.md)
* [Get-AzTableRowByPartitionKey](docs/Get-AzTableRowByPartitionKey.md)
* [Get-AzTableRowByPartitionKeyRowKey](docs/Get-AzTableRowByPartitionKeyRowKey.md)
* [Get-AzTableTable](docs/Get-AzTableTable.md)
* [Remove-AzTableRow](docs/Remove-AzTableRow.md)
* [Update-AzTableRow](docs/Update-AzTableRow.md)

> Note: Cmdlets Get-AzTableRowAll, Get-AzTableRowByColumnName, Get-AzTableRowByCustomFilter, Get-AzTableRowByPartitionKey, Get-AzTableRowByPartitionKeyRowKey, Get-AzTableRowByPartitionKeyRowKey are deprecated and **Get-AzTableRow** should be used instead, these will all be removed in a future release of this module.

# Running automated tests

## Prerequisites

* [Pester](https://github.com/pester/Pester) - PowerShell BDD style testing framework
* [Azure Storage Emulator](https://docs.microsoft.com/en-us/azure/storage/storage-use-emulator) or [Azure Subscription](https://azure.microsoft.com/en-us/free/)
* [Azure Power Shell](https://docs.microsoft.com/en-us/powershell/azure/overview)

## How to run automated tests

### Before you run

Please make sure that your Azure Storage Emulator is up and running if you want to run all tests against it.

### Run

```
PS> Invoke-Pester
```

To test on Azure instead of Storage Emmulator, use:

```
PS> Invoke-Pester @{Path="./Tests";Parameters=@{SubscriptionId='<your subscription id>';Location='<location>'}}
```

![Invoke-Pester](AzureRmStorageTable-Pester.gif)
