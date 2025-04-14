$ErrorActionPreference = 'Stop'

$logFIle = Join-Path $PSScriptRoot "remove-vm-extension-log.txt"

function log {
  param (
      [Parameter(Mandatory)]
      $msg
  )
  "$(Get-Date -Format o) $msg" | Out-File -FilePath $logFIle -Append
}

$vmExtensionName = 'Microsoft.Azure.Security.AntimalwareSignature.AntimalwareConfiguration'

try {
  log "Start"
  Connect-AzAccount -Identity
  Set-AzContext -Subscription azurehpc-1 -Tenant Microsoft

  $names = Get-AzVMExtension -ResourceGroupName robertdevrg -VMName robert-sdev-5 | ForEach-Object{ $_.Name }
  log "Current extensions on the VM: $($names -join ', ')"

  if ($names -contains $vmExtensionName) {
    log "Try to remove $vmExtensionName"
    Remove-AzVMExtension -ResourceGroupName robertdevrg -VMName robert-sdev-5 -Name $vmExtensionName -Force

    $names = Get-AzVMExtension -ResourceGroupName robertdevrg -VMName robert-sdev-5 | ForEach-Object{ $_.Name }
    log "Current extensions on the VM: $($names -join ', ')"
  }
  else {
    log "Extension '${vmExtensionName}' is not found on the VM."
  }

  log "OK"
}
catch {
  log "Error when removing extension '${vmExtensionName}': $_"
}
