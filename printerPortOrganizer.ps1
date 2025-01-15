$PrinterServer = Read-Host "Enter printer host server";

# find printer ports whose name starts with "10."
$PrinterPortObjects = Get-PrinterPort -ComputerName $PrinterServer -Name "10.*";

# get IP addresses from port names
$PrinterPorts = foreach($Object in $PrinterPortObjects) { $Object.PrinterHostAddress }

# check each IP
foreach($IP in $PrinterPorts) {
    if(Test-Connection $IP -Count 1 -Quiet) {
        # get the printer hostname (i.e. PRSE0454.print.pninfrasrv.net)
        $PrinterHostName = ([System.Net.Dns]::GetHostByAddress($IP)).HostName;

        # get the printer name (i.e. PRSE0353)
        $PrinterName = $PrinterHostName.Split(".")[0];

        # check if printer exists on the server
        if($PrinterObj = Get-Printer -Name $PrinterName -ComputerName $PrinterServer -ErrorAction SilentlyContinue) {

            # check if there is a standard port created for this printer
            if($StandardPortObject = Get-PrinterPort -Computer $PrinterServer -Name HST_$PrinterName*) {
                $StandardPortName = $StandardPortObject.Name;
                $StandardPortHostName =  $StandardPortObject.PrinterHostAddress;

                # check if the standard port hostname begins with the printer name
                if($StandardPortHostName -like "$PrinterName*") {

                    # check if the standard port hostname is reachable
                    if(Test-Connection $StandardPortObject.PrinterHostAddress -Count 1 -Quiet) {

                        # check if the printer already has the standard port set
                        if($PrinterObj.PortName -ne $StandardPortName) {
                            # if not, set it
                            Set-Printer -Name $PrinterName -ComputerName $PrinterServer -PortName $StandardPortName;
                            Write-Host "Printer $PrinterName IP $IP, port changed to $StandardPortName";
                        } else { Write-Host "The printer $PrinterName IP $IP already has the standard port"; }
                    } else { Write-Host "Port $StandardPortName is not reachable by $StandardPortHostName"; }
                } else { Write-Host "Port $StandardPortName hostname $StandardPortHostName is incorrect"; }
            } else { Write-Host "Standard printer port does not exist for printer $PrinterName "; }
        } else { Write-Host "Printer $PrinterName, hostname $PrinterHostName, IP $IP does not exist on this server"; }
    } else { Write-Host "$IP is unreachable"; }
}