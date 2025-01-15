$global:Domains = (Get-ADForest).Domains
$global:EnabledThinClients = @()
$global:EnabledThinClientsAndIPs = @()


function Get-EnabledThinClientNames {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$Domains
    )
    Write-Verbose -Message "Getting enabled ThinClients from $($Domains.Count) domains..."
    $Computers = @()
    $Options = @{
        Filter = "Enabled -eq $true"
        Properties = "CanonicalName, Name"
    }
    foreach($Domain in $Domains) {
        Computers += Get-ADComputer -Server $Domain @Options | 
        Where-Object { $_.CanonicalName -like "*thinclient*" } | 
        Select-Object -ExpandProperty Name | Sort-Object -Unique
    }
    Write-Verbose -Message "Complete. Devices found: $($Computers.Count)"
    $global:EnabledThinClients = $Computers
}


function Create-ThinClientFile {
    [CmdletBinding()]
    param ()
    $TextFilePath = "$env:USERPROFILE\Desktop\enabledThinClients.txt"
    $global:EnabledThinClients | Out-File -FilePath $TextFilePath
    Write-Verbose -Message "List exported to $($TextFilePath)"
}


function Get-IPADDresses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Computers
    )
    $ComputersAndIPs = @()
    foreach($Computer in $Computers) {
        $IP = Test-Connection $Computer -Count 1 -ErrorAction SilentlyContinue | % { $_.IPV4Address.IPAddressToString }
        $ComputerAndIP = [PSCustomObject]@{
            ComputerName = $Computer
            IP = $IP
        }
         $ComputersAndIPs += $ComputerAndIP
    }
    $global:EnabledThinClientsAndIPs = $ComputersAndIPs
}


function Create-ThinClientAndIPFile {
    [CmdletBinding()]
    param (
    #[Parameter(Mandatory)]
    #$Source
    )
    $TextFilePath = "$env:USERPROFILE\Desktop\enabledThinClientsAndIPs.txt"
    $global:EnabledThinClientsAndIPs | Format-Table -AutoSize | Out-File -FilePath $TextFilePath 
    Write-Verbose -Message "List exported to $($TextFilePath)"
}

Get-EnabledThinClientNames -Domains $global:Domains -Verbose
Create-ThinClientFile -Verbose
Get-IPADDresses -Computers $global:EnabledThinClients
Create-ThinClientAndIPFile -Verbose

Pause