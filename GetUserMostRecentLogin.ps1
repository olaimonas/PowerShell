# Get username input
$Username = (Read-Host -Prompt "Username").Trim().ToUpper()
# Look for the user in the system
$Domains = (Get-ADForest).Domains
$UserObjects = @()

Function Get-MostRecentLogon {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$Domain,

        [Parameter(Mandatory)]
        [String]$UserName
    )
    Write-Verbose -Message "Getting domain controllers on user's domain"
    $DomainControllers = @(Get-ADDomainController -Server $Domain -Filter * | Sort Name | Select-Object -ExpandProperty Name)
    $LastLogonTimes = @()

    Write-Verbose -Message "Checking logon dates..."

    foreach($DomainController in $DomainControllers) {
        $UserObject = Get-ADUser -Identity $UserName -Server $DomainController -Properties lastlogon
        $LastLogonRaw = $UserObject.lastLogon
        $LastLogonTimes += $LastLogonRaw
    }

    Write-Verbose -Message "Getting the most recent login..."
    $MostRecentLogonDate = $LastLogonTimes | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    $MostRecentLogonDate = ([datetime]::FromFileTime($MostRecentLogonDate)).ToString("yyyy-MMM-dd, HH:mm")
    Write-Output $MostRecentLogonDate
}

foreach($Domain in $Domains) {
    try {
        $UserObjects += Get-ADUser -Identity $Username -Server $Domain -Properties *
    } catch {}
}

if($UserObjects.Length -eq 0) {
    Write-Host "User not found on any domain"
    Pause
} elseif($UserObjects.Length -gt 1) {
    $DomainsUserFoundOn = @()

    foreach($UserObject in $UserObjects) {
        $DomainsUserFoundOn += $UserObject.CanonicalName.Split("/")[0]
    }

    Write-Host "User $Username found on multiple domains"

    # Get user to choose the domain to use for user display
    for($i = 0; $i -lt $DomainsUserFoundOn.Length; $i ++) {
        Write-Host ($i+1)"-"$DomainsUserFoundOn[$i]
    }

    $ChosenNumber = Read-Host -Prompt "Choose domain"
    $UserObject = $UserObjects[$ChosenNumber-1]

    Get-MostRecentLogon -Domain $DomainsUserFoundOn[$ChosenNumber-1] -UserName $Username -Verbose
    Pause
} else {
    Get-MostRecentLogon -Domain $UserObjects[0].CanonicalName.Split("/")[0] -UserName $Username -Verbose
    Pause
}