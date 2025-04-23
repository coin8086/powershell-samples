param (
  # A list of subscription id, in which resource groups will be removed
  [Parameter(Mandatory)]
  [string[]]
  $SubscriptionList,

  # A name list of resoure groups, which will be exempt from being removed
  [string[]]
  $ExemptList=@(),

  # Try the command without real removal
  [switch]
  $WhatIf,

  [string]
  $LogFile
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

if (!$LogFile) {
  $baseName = Split-Path -Path $PSCommandPath -LeafBase
  $LogFile = Join-Path $PSScriptRoot "$baseName.log"
}

function log {
  param (
      [Parameter(Mandatory)]
      [string]
      $msg
  )
  "$(Get-Date -Format o) $msg" | Out-File -FilePath $LogFile -Append
}

$removeResourceGroup = {
  param(
    # Parameter help description
    [Parameter(Mandatory)]
    [string]
    $Name,

    [bool]
    $WhatIf = $false
  )

  $ErrorActionPreference = 'Stop'
  $InformationPreference = 'Continue'

  Get-AzResourceLock -ResourceGroupName $Name | ForEach-Object {
    Write-Information "Remove lock '$($_.Name)' on '$($_.ResourceId)'"
    $_
  } | Remove-AzResourceLock -Force -WhatIf:$WhatIf

  Remove-AzResourceGroup -Name $Name -Force -WhatIf:$WhatIf
}

foreach ($SubscriptionId in $SubscriptionList) {
  Write-Information ""
  Write-Information "Subscription '$SubscriptionId':"

  try {
    Set-AzContext -Subscription $SubscriptionId -WarningAction SilentlyContinue
  }
  catch {
    $log = "Cannot connect to subscription '$SubscriptionId'. Error: $_"
    Write-Warning $log
    log $log
    continue
  }

  $groups = Get-AzResourceGroup
  $jobs = @{}

  foreach ($group in $groups) {
    $name = $group.ResourceGroupName

    if ($name -in $ExemptList) {
      Write-Information "-- Exempt '$name'"
    }
    else {
      Write-Information "++ Remove '$name'"

      $job = Start-Job -ScriptBlock $removeResourceGroup -ArgumentList $name, $WhatIf
      $jobs[$name] = $job
    }
  }

  Write-Information "Waiting for $($jobs.Count) job(s) ..."

  foreach ($name in $jobs.Keys) {
    $job = $jobs[$name]

    try {
      Receive-Job -Job $job -Wait
    }
    catch {
      $log = "Error when removing '$name' in subscription '$SubscriptionId': $_"
      Write-Warning $log
      log $log
    }
    Remove-Job -Job $job
  }
}
