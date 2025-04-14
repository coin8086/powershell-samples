<#
.SYNOPSIS
Update Windows

.DESCRIPTION

To update computers in a cluster, put the script in a shared dir, say \\computer1\share1\Update-Windows.ps1. Then execute the following command line in a cmd shell on each computer:

powershell "& { Set-ExecutionPolicy -ExecutionPolicy bypass; \\computer1\share1\Update-Windows.ps1 -a -r }

.PARAMETER AcceptAll

.PARAMETER AutoReboot
#>

param(
    [Alias("a")]
    [switch]$AcceptAll,

    [Alias("r")]
    [switch]$AutoReboot
)

$ErrorActionPreference = 'Stop'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (!(Get-Module -Name PSWindowsUpdate -ListAvailable))
{
    "Preparing to install PSWindowsUpdate..." | out-string
    try
    {
        Get-PackageProvider -Name NuGet -ListAvailable
    }
    catch
    {
        "Installing package provider NuGet..." | out-string
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    }

    "Setting InstallationPolicy for PSGallery..." | out-string
    $retry = 0
    while ($retry -lt 5)
    {
        if ($retry -gt 0)
        {
            "Retrying..." | out-string
            Sleep 5
        }

        # Sometimes (probablity <= 1%) 'Set-PSRepository -Name "PSGallery" ...' failed with error:
        # Set-PSRepository : No repository with the name 'PSGallery' was found.
        # Hopefully retry can help that.
        try
        {
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
            break
        }
        catch
        {
            "Set-PSRepository failed with error:\n$_" | out-string
            $retry += 1
        }
    }
    if ($retry -eq 5)
    {
        throw "Abort!" | out-string
    }

    "Installing PSWindowsUpdate..." | out-string
    Install-Module -Name PSWindowsUpdate
}
else
{
    Import-Module PSWindowsUpdate
}

"Checking for updates..." | out-string
Get-WindowsUpdate | out-string

"Downloading and installing updates..." | out-string
Install-WindowsUpdate -AcceptAll:$AcceptAll -AutoReboot:$AutoReboot | out-string

"Done!" | out-string
