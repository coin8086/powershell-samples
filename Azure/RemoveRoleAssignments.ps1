param (
  # A list of subscription id, on which role assignments will be removed
  [Parameter(Mandatory)]
  [string[]]
  $SubscriptionList,

  # A list of the SignInName (one@domain.com). These users will be exempt from removing role on the subscription.
  [string[]]
  $ExcludeList=@(),

  # Try the command without real removal
  [switch]
  $WhatIf
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

foreach ($SubscriptionId in $SubscriptionList) {
  $scope = "/subscriptions/$SubscriptionId"

  Write-Information ""
  Write-Information "For scope '$scope':"

  try {
    $assignments = Get-AzRoleAssignment -Scope $scope | Where-Object { $_.Scope -eq $scope }
  }
  catch {
    Write-Warning "Cannot get role assignments. Error: $_"
    continue
  }

  foreach ($one in $assignments) {
    if (!($one.SignInName -in $ExcludeList)) {
      Write-Information "++ Remove user '$($one.DisplayName)' ($($one.ObjectId)) of role '$($one.RoleDefinitionName)'"
      if (!$WhatIf) {
        try {
          Remove-AzRoleAssignment -Scope $scope -RoleDefinitionId $one.RoleDefinitionId -ObjectId $one.ObjectId
        }
        catch {
          Write-Warning "Cannot remove user '$($one.DisplayName)' ($($one.ObjectId)) of role '$($one.RoleDefinitionName)'. Error: $_"
        }
      }
    }
    else {
      Write-Information "-- Exempt user '$($one.DisplayName)' ($($one.SignInName)) of role '$($one.RoleDefinitionName)'"
    }
  }
}

