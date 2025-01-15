<# 
This is not a self-executing script. Run the commands in powershell based on situation and needs
#>
# Get all the conference rooms that have "Pacific Standard Time" time zone
$RoomsWithPacificTimeZone = Get-Mailbox -ResultSize unlimited -Filter { 
    RecipientTypeDetails -eq "RoomMailbox" 
    } | Where-Object { 
        (Get-MailboxCalendarConfiguration -Identity $_.Id -WarningAction SilentlyContinue).WorkingHoursTimeZone -eq "Pacific Standard Time" 
        } | Sort-Object Id #WhenCreated | Format-Table -Property Name, WhenCreated -AutoSize

# If the information about the rooms is already collected, get it from a text file
# $RoomsWithPacificTimeZoneFromFile = Get-Content -Path "C:\Users\loberauskis\OneDrive - DXC Production\Desktop\rooms.txt"

# Get location for each room
$RoomsAndLocations = $RoomsWithPacificTimeZone | ForEach-Object {
    Get-MgUser -UserId $_.UserPrincipalName -Property DisplayName, UserPrincipalName, Country, City, UsageLocation
    } | Sort-Object Country

<# $Countries = $RoomsAndLocations.Country | Select-Object -Unique
$UsageLocations = $RoomsAndLocations.UsageLocation | Select-Object -Unique #>

$WEuropeStdTime = "W. Europe Standard Time"
$FLEStdTime = "FLE Standard Time"

# Change time zone according to the UsageLocation / Country
# Since there are objects that are missing either UsageLocation or Country attributes, must check
$RoomsAndLocations | ForEach-Object {
    # First check if Country is not empty
    if($null -ne $_.Country) {
        # Since there are only 4 countries in this case, the values are hard-coded
        # If the country is not Finland, set the time zone to "W. Europe Standard Time" which is suitable for Germany, Denmark, Norway and Sweden
        if($_.Country -ne "Finland") {
            Set-MailboxCalendarConfiguration -Identity $_.UserPrincipalName -WorkingHoursTimeZone $WEuropeStdTime -Verbose -WarningAction SilentlyContinue
            "Room `"$($_.DisplayName)`" timezone set to `"$($WEuropeStdTime)`"" >> "C:\Users\loberauskis\OneDrive - DXC Production\Desktop\log.txt"
        } else {
            Set-MailboxCalendarConfiguration -Identity $_.UserPrincipalName -WorkingHoursTimeZone $FLEStdTime -Verbose -WarningAction SilentlyContinue
            "Room `"$($_.DisplayName)`" timezone set to `"$($FLEStdTime)`"" >> "C:\Users\loberauskis\OneDrive - DXC Production\Desktop\log.txt"
        }
        
    } 
    # Same with UsageLocation
    elseif ($null -ne $_.UsageLocation) {
        if($_.UsageLocation -ne "FI") {
            Set-MailboxCalendarConfiguration -Identity $_.UserPrincipalName -WorkingHoursTimeZone $WEuropeStdTime -Verbose -WarningAction SilentlyContinue
            "Room `"$($_.DisplayName)`" timezone set to `"$($WEuropeStdTime)`"" >> "C:\Users\loberauskis\OneDrive - DXC Production\Desktop\log.txt"
        } else {
            Set-MailboxCalendarConfiguration -Identity $_.UserPrincipalName -WorkingHoursTimeZone $FLEStdTime -Verbose -WarningAction SilentlyContinue
            "Room `"$($_.DisplayName)`" timezone set to `"$($FLEStdTime)`"" >> "C:\Users\loberauskis\OneDrive - DXC Production\Desktop\log.txt"
        }
    }
}

# For the rest of the rooms which lack UsageLocation, Country properties
# Finnish rooms
$RoomsAndLocations | Where-Object { 
    $_.DisplayName -like "*FI-*" 
    } | ForEach-Object { 
        Set-MailboxCalendarConfiguration -Identity $_.UserPrincipalName -WorkingHoursTime $FLEStdTime -Verbose -WarningAction SilentlyContinue 
        "Room `"$($_.DisplayName)`" timezone set to `"$($FLEStdTime)`"" >> "C:\Users\loberauskis\OneDrive - DXC Production\Desktop\log.txt"
    }

$RoomsAndLocations | ForEach-Object {
    if($_.DisplayName -notlike "*FI-*") {
        Set-MailboxCalendarConfiguration -Identity $_.UserPrincipalName -WorkingHoursTimeZone $WEuropeStdTime -Verbose -WarningAction SilentlyContinue
        "Room `"$($_.DisplayName)`" timezone set to `"$($WEuropeStdTime)`"" >> "C:\Users\loberauskis\OneDrive - DXC Production\Desktop\log.txt"
    }
}