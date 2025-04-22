param (
  # A list of subscription id, in which role assignments will be removed
  [Parameter(Mandatory)]
  [string[]]
  $SubscriptionList,

  # A list of SignInName (one@domain.com), who will be exempt from being removed role in the subscription
  [string[]]
  $ExemptList=@(),

  # Try the command without real removal
  [switch]
  $WhatIf
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$baseName = Split-Path -Path $PSCommandPath -LeafBase
$logFIle = Join-Path $PSScriptRoot "$baseName.log"

function log {
  param (
      [Parameter(Mandatory)]
      [string]
      $msg
  )
  "$(Get-Date -Format o) $msg" | Out-File -FilePath $logFIle -Append
}

foreach ($SubscriptionId in $SubscriptionList) {
  $scope = "/subscriptions/$SubscriptionId"

  Write-Information ""
  Write-Information "For scope '$scope':"

  try {
    $assignments = Get-AzRoleAssignment -Scope $scope # | Where-Object { $_.Scope -eq $scope }
  }
  catch {
    $log = "Cannot get role assignments in scope $scope. Error: $_"
    Write-Warning $log
    log $log
    continue
  }

  foreach ($one in $assignments) {
    if ($one.ObjectType -ne 'User') {
      continue
    }

    $assignmentInfo = "user '$($one.DisplayName)' ($($one.SignInName)) of role '$($one.RoleDefinitionName)' at scope $($one.Scope)"

    if (!($one.SignInName -in $ExemptList)) {
      Write-Information "++ Remove $assignmentInfo"

      if (!$WhatIf) {
        try {
          Remove-AzRoleAssignment -Scope $one.Scope -RoleDefinitionId $one.RoleDefinitionId -ObjectId $one.ObjectId
        }
        catch {
          $log = "Cannot remove $assignmentInfo. Error: $_"
          Write-Warning $log
          log $log
        }
      }
    }
    else {
      Write-Information "-- Exempt $assignmentInfo"
    }
  }
}
