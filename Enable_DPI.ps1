# Change the value of Enable_DPI to a desired value in the Windows Registry
# The modification of the 'Enable_DPI' value requires administrator rights

$ErrorActionPreference = 'silentlycontinue'
cd "$PSSCriptRoot"
$path = "HKLM:\SOFTWARE\Policies\Citrix\ICA Client\DPI"
$regKeyName = "Enable_DPI"

Function getEnable_DPIValue {
    $regKeyValue = $null
    $parameters = @{
        ScriptBlock = {
            Param ($path, $regKeyName) 
            Get-ItemProperty -Path $path -Name $regKeyName | Select-Object -ExpandProperty $regKeyName
        }
        ArgumentList = $path, $regKeyName
    }
    Invoke-Command @parameters
}

Function setEnable_DPIValue() {
    $Choice = Read-Host "Enter the desired value"
    Set-ItemProperty -Path $path -Name $regKeyName -Value $Choice
}

Function executeScript {

    $Enable_DPIValue = getEnable_DPIValue
    
    $yesNo = (Read-Host "'Enable_DPI' value is $Enable_DPIValue. Do you want to modify it? [Y/N]?").ToUpper().Trim();
        if($yesNo -eq "Y") {
            setEnable_DPIValue;
            $Enable_DPIValue = getEnable_DPIValue
            Write-Host "'Enable_DPI' value is now $Enable_DPIValue"
        } else {
            $Enable_DPIValue = getEnable_DPIValue
            Write-Host "'Enable_DPI' value has not been modified and is equal to $Enable_DPIValue"
            }
}

executeScript