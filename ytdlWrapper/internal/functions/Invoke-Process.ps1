<#
.SYNOPSIS
	Starts the youtube-dl process and waits for it to finish.

.EXAMPLE
	PS C:\> Invoke-Process -Path $path
	
	Starts youtube-dl specifying the configuration file at the $path location.
	
.INPUTS
	None
	
.OUTPUTS
	None
	
.NOTES
	
#>
function Invoke-Process
{
	
	[CmdletBinding()]
	Param
	(
		
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$Path
		
	)
	
	# Define youtube-dl process information.
	$processStartupInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
		FileName = "youtube-dl"
		Arguments = "--config-location `"$Path`""
		UseShellExecute = $false
	}
	
	# Start and wait for youtube-dl to finish.
	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $processStartupInfo
	$process.Start() | Out-Null
	$process.WaitForExit()
	$process.Dispose()
	
}