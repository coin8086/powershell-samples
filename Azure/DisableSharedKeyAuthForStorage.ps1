<#
.SYNOPSIS
Disable local auth for storage accounts

.DESCRIPTION
The script depends on module Az.Storage. Install it by

Install-Module -Name Az.Storage
#>

param(
    # CSV file path
    [Parameter(Mandatory)]
    [string] $Path,

    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'Continue'
$InformationPreference = 'Continue'

function DisableLocalAuth {
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroup,

        [Parameter(Mandatory)]
        [string]$AccountName,

        [string]$Subscription,

        [bool]$IgnoreWhenNotFound = $true,

        [bool]$WhatIf
    )
    if ($Subscription) {
        Write-Information "Changing to subscription $Subscription"
        Set-AzContext -Subscription $Subscription
    }
    Write-Information "Disabling $AccountName of $ResourceGroup"
    if (!$WhatIf) {
        try {
            Set-AzStorageAccount -ResourceGroupName $ResourceGroup -AccountName $AccountName -AllowSharedKeyAccess $false | Out-Null
        }
        catch {
            $ignore = $false
            if ($IgnoreWhenNotFound) {
                $code = $_.Exception.Response.StatusCode
                if ($code -eq 404) {
                    $ignore = $true
                    Write-Warning "$AccountName of $ResourceGroup is not found!"
                }
            }
            if (!$ignore) {
                throw
            }
        }
    }
}

function GetAccountName {
    param(
        [Parameter(Mandatory)]
        [string]$ResourceId
    )
    $pattern = '^/subscriptions/(?<sub>.+)/resourceGroups/(?<rg>.+)/providers/Microsoft.Storage/storageAccounts/(?<account>.+)'
    if (!($ResourceId -match $pattern)) {
        throw "'$ResourceId' doesn't match '$pattern'!"
    }
    return $Matches.account
}

$accounts = Import-Csv $Path
$failed = New-Object System.Collections.Generic.List[System.Object]
$total = 0
$lastSub = ''

$accounts | %{
    $rid = $_.ResourceId
    if (!$rid) {
        Write-Warning "Invalid ResourceId"
        return
    }
    Write-Information "Processing $rid"
    try {
        $name = GetAccountName $rid
        if ($lastSub -eq $_.SubscriptionId) {
            DisableLocalAuth -ResourceGroup $_.ResourceGroup -AccountName $name -WhatIf $WhatIf
        }
        else {
            DisableLocalAuth -ResourceGroup $_.ResourceGroup -AccountName $name -Subscription $_.SubscriptionId -WhatIf $WhatIf
            $lastSub = $_.SubscriptionId # If there's an exception in DisableLocalAuth then do not change $lastSub
        }
    }
    catch {
        Write-Warning "Failed disabling the account $name"
        Write-Warning $_
        $failed.Add($rid)
    }
    $total += 1
}

Write-Information "Processed: $total"
Write-Information "Failed: $($failed.Count)"

$failed
