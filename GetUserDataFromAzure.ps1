cd "$PSSCriptRoot"
cls

#Credential read and prepare login object
if(![System.IO.File]::Exists("$env:USERPROFILE\Documents\Secure2.txt")){
    .\source\Password_generator3.ps1 
    cls}

if(![System.IO.File]::Exists("$env:USERPROFILE\Documents\ID.txt")){
    .\source\Password_generator3.ps1 
    cls}

$Username = Get-Content "$env:USERPROFILE\Documents\ID.txt"
$ssPwd = Get-Content "$env:USERPROFILE\Documents\Secure2.txt" | ConvertTo-SecureString

$credential = New-Object System.Management.Automation.PSCredential ($Username,$ssPwd)

#Connecting to AAD
Try{
    write-host ""
    
    Connect-AzureAD -Credential $credential | out-null
    write-host "Connected to AzureCloud"

} Catch {
    Remove-Item $env:USERPROFILE\Documents\Secure2.txt;
    remove-item $env:USERPROFILE\Documents\ID.txt;
    Write-Host "AzureAD login failed. Try again.";
    pause;
    exit;
}


#Read a CSV input file and catch errors
$csvFilePath = '.\IDList.csv'
try
{
    $csvFileData = import-csv -Path $csvFilePath | Select-Object -ExpandProperty "ADID" -ErrorAction SilentlyContinue
    if (!$?)
    {
        throw $Error[0].Exception    
    } 
}
catch 
{
    Write-warning "Unable to import CSV. Check format."
    Write-Warning "Exiting the script"
    pause
    exit
}

#Gather user data. Groups filtered using *-e3* and *ims*.
write-host "Generating user data from AzureAD. Might take a while..."
write-host ""

$UserData = @()
foreach ($Id in $csvFileData)
{
    $UserUPN = Get-ADUser -Server pdk.pnad.pninfrasrv.net -Identity $Id -Property UserPrincipalName | Select-Object -ExpandProperty UserPrincipalName
    $users = Get-AzureADUser -SearchString $UserUPN
    foreach ($user in $users)
    {
        $UserData += $user | select displayName,userPrincipalName,@{n="Groups";e={$user |
            Get-AzureADUserMembership | where {$_.objecttype -eq "group" -and $_.displayname -like "*ims*" -or $_.displayname -like "*-e5*"} |
            sort | Get-Unique |
            select -ExpandProperty displayname }}   
    }       
}
write-host "Finished. Outputing data"
write-host ''

#Output options:
write-host "Select data output option:"
Write-Host "1 - Gridview"
Write-Host "2 - Export to CSV"
$menuOptions = 1,2

#Waiting for menu number until provided. Input validated
do
{
    $outputOption = read-host "Enter option number" 

    switch ($outputOption)
    {
        1 {
            #Display and format data
            $UserData | Out-GridView -Title "User Data"
        }    
        2 {
            #Export to a CSV file
            $UserData | Export-Csv -Path .\userData.csv -NoTypeInformation -Encoding UTF8
            write-host ""
            write-host "CSV File exported to"(Get-Location)
        }
        Default {write-warning "No such menu option. Try again"}
    }    
}
until ($menuOptions -contains $outputOption)

#Disconnecting from AAD
Disconnect-AzureAD | out-null
write-host ""
write-host "Successfully disconnected from Azure AD"

pause