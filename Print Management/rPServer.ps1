Param (
    $newPrintServer = "b11",
	$oldPrintServers = @("b06")
)

  
#Pull the current default printer's name
$defaultPrinter = gwmi win32_printer | where {$_.Default -eq $true}
 
#Enable Verbose output (will be reverted at the end of script)
$oldverbose = $VerbosePreference
$VerbosePreference = "continue"
 
 
#Change the printer from old to new
function ChangePrinter {
try{
        ForEach ($printer in $printers) {
            Write-Verbose ("{0}: Replacing with new print server name: {1}" -f $Printer.Name,$newPrintServer)
            $newPrinter = $printer.Name -replace $oldPrintServer,$newPrintServer		
            $returnValue = ([wmiclass]"Win32_Printer").AddPrinterConnection($newPrinter).ReturnValue                
            If ($returnValue -eq 0) {         
                Write-Verbose ("{0}: Removing" -f $printer.name)
                $printer.Delete()
            } Else {
                Write-Verbose ("{0} returned error code: {1}" -f $newPrinter,$returnValue) -Verbose
            }
        }
    
	# Gets new list of printers that are pointed to newserver
	$newPrinterList = @(Get-WmiObject -Class Win32_Printer -Filter "SystemName='\\\\$newPrintServer'" -ErrorAction Stop)
 
	# iterates through each new printer and compares the ShareName to the old ShareName that was the user’s default printer and sets it
	ForEach ($printer in $newPrinterList) {
	If ($printer.ShareName -eq $defaultPrinter.ShareName) {
 
                $tmp = $printer.SetDefaultPrinter()
                Write-Verbose ("{0} Set as default printer" -f $printer.Name,$returnValue) -Verbose
		}
	}
}catch{
}
}
 
#Main Code-Block
Try {
    #ForEach Server in $oldPrintServers do
    ForEach ($oldPrintServer in $oldPrintServers) {
		
        Write-Verbose ("{0}: Checking for printers mapped to old print server {1}" -f $Env:USERNAME, $oldPrintServer)
		$printers = @(Get-WmiObject -Class Win32_Printer -Filter "SystemName='\\\\$oldPrintServer'" -ErrorAction Stop)
		
        #If we get back any mapped printer call ChangePrinter and do it
        If ($printers.count -gt 0) {        
			ChangePrinter
		}
	}
	
} Catch {
}
 
 
$VerbosePreference = $oldverbose