<#
.SYNOPSIS
Get deployments from a JSON file.

.DESCRIPTION
For Azure_Subscription_DP_Avoid_Plaintext_Secrets_Deployments
#>

param(
    # Json file path
    [Parameter(Mandatory)]
    [string] $Path
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function GetDeploymentAndSecret {
    param(
        [string] $Source,
        [string] $Secret
    )
    $pattern = '^/subscriptions/(?<sub>.+)/resourceGroups/(?<rg>.+)/providers/Microsoft.Resources/deployments/(?<deployment>.+)'
    if (!($Source -match $pattern)) {
        throw "'$Source' doesn't match '$pattern'!"
    }
    return [pscustomobject]@{
        Sub = $Matches.sub
        Rg = $Matches.rg
        Deploymkent = $Matches.deployment
        Secret = $Secret
    }
}

$json = cat -Raw $Path | ConvertFrom-Json

# NOTE: $json is a custom PSObject, not a Hashtable. So $json['xxx'] is not available.
$detections = $json.Detections
if (!$detections) {
    Write-Information 'Processing truncated data...'
    $detections = $json.'Truncated Data'.Detections
}
else {
    Write-Information 'Processing data...'
}

$detections | %{ GetDeploymentAndSecret $_.Source $_.Secret }
