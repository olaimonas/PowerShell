$Date = Get-Date -Format "yyyy-MM-dd, HH:mm:ss";

Function EmptyLine {
    Write-Host "";
}


$swedishPrinterPattern = "PRSE\d+";
$danishPrinterPattern = "PR\d+";

# Get the printer number
$printerNumber = (Read-Host "Enter printer number").ToUpper().Trim();
"$env:username looked for $printerNumber on $Date" >> C:\Users\laob600\Desktop\myScripts\logs\modifiedScript.txt;
$printerFound = $false;

if($printerNumber -match $swedishPrinterPattern) {
    $printerCountry = "SE";
} elseif($printerNumber -match $danishPrinterPattern) {
    $printerCountry = "DK";
} else { Write-Host "Wrong printer name"; return; }

if($printerCountry -eq "DK") {
    # Danish printer servers
    $printerServerArray = @("SRPRNA520", "SRPRNA521", "SRPRNA522", "SRPRNA523", "SRPRNA524");
} else {
    # Swedish printer servers
    $printerServerArray = @("IN-174-ESS-WVP", "IN-175-ESS-WVP", "IN-176-ESS-WVP");
}

# Find on which server the printer is
foreach($server in $printerServerArray) {
    # Servers can occassionally be down, so need to check if one is up
    $serverReachable = Test-Connection $server -Count 1 -Quiet;
    if($serverReachable) {
        $printerNames = Get-Printer -ComputerName $server | Select-Object -ExpandProperty Name;
        # If the printer is found, terminate the search
        if($printerNames.Contains($printerNumber)) {
            $printerServer = $server;
            $printerFound = $true;
            break;
        }
    } else { Write-Host -ForegroundColor Yellow "Print server $server is unreachable"; }
}

if($printerFound) {
    # Selecting first instance because there are many duplicates with Danish printers
    $printerObject = Get-Printer -ComputerName $printerServer -Name $printerNumber | Select-Object -First 1;

     # Display \\PRINTER_SERVER\PRINTER_NAME
    EmptyLine;
    Write-Host \\$printerServer\$printerNumber;

    # Status
    EmptyLine;
    Write-Host -ForegroundColor DarkYellow "STATUS ";
    if($printerObject.PrinterStatus -contains "error") {
        Write-Host -ForegroundColor Red $printerObject.PrinterStatus
    } else {
        Write-Host $printerObject.PrinterStatus
    }
    EmptyLine;
    Write-Host -NoNewline -ForegroundColor Cyan "Shared: "; Write-Host $printerObject.Shared;
    Write-Host -NoNewline -ForegroundColor Cyan "Published: "; Write-Host $printerObject.Published;
    EmptyLine;

    if($printerCountry -eq "DK") {
        # The real names are something like "PRNDK0047"
        $printerRealNamePattern = "PRNDK(\d+)"
        # The real name is hidden in location property of the printer object
        $patternMatch = $printerObject.Location | Select-String -Pattern $printerRealNamePattern -AllMatches | ForEach-Object { $_.Matches }
        if($patternMatch.Success) {
            $printerFQDN = $patternMatch.Value + ".print.pninfrasrv.net";
        } else { Write-Host -ForegroundColor Yellow "Could not find the real name of the printer"; EmptyLine; EmptyLine; }
    } elseif($printerCountry -eq "SE") {
        $printerFQDN = $printerNumber + ".print.pninfrasrv.net";
    }

    $printerIP = Test-Connection $printerFQDN -Count 1 | % { $_.IPV4Address.IPAddressToString }

    if($printerFQDN -ne $null) {
        # Full printer name
        Write-Host -ForegroundColor DarkYellow "FULL NAME ";
        Write-Host $printerFQDN;
        EmptyLine;
    }

    # IP
    Write-Host -ForegroundColor DarkYellow "IP ";
    if($printerIP -ne $null) {        
        Write-Host $printerIP;
    } else { Write-Host -ForegroundColor Yellow "Could not get printer IP"; EmptyLine; }
    EmptyLine;
    EmptyLine;

} else { Write-Host "Printer not found"; EmptyLine; }