# Modules necessary for the script to work
$PSModules = @(
    "Microsoft.Graph.Users"
    "Microsoft.Graph.DeviceManagement"
    "Microsoft.Graph.Identity.DirectoryManagement"
    "Microsoft.Graph.Authentication"
    )


Function Install-NuGet {
    [CmdletBinding()]
    param ()
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

Function Install-Modules {
    [CmdletBinding()]
    param (
        $Modules
    )
    $Modules | ForEach-Object {
        if(!(Get-InstalledModule -Name $_ -ErrorAction SilentlyContinue)) {
            Set-PSRepository PSGallery -InstallationPolicy Trusted
            Install-Module -Name $_ -Confirm:$False -Force
        }
    }
}


Install-NuGet
Install-Modules -Modules $PSModules