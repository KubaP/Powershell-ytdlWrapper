function Write-Message {
	<#
	.SYNOPSIS
		Writes a message to the screen.
		
	.DESCRIPTION
		Writes a message to the screen, as text, a warning, or an error.
		
	.PARAMETER Message
		The message to print to screen.
		
	.PARAMETER DisplayText
		Writes the message as standard text.
		
	.PARAMETER DisplayWarning
		Writes the message as a warning.
		
	.PARAMETER DisplayError
		Writes the message as an error.
		
	.EXAMPLE
		PS C:\> Write-Message -Message "invalid argument" -DisplayError
		
		Prints the error message to screen by invoking Write-Error.
		
	#>
	[CmdletBinding()]
	Param(
		
		[Parameter(ParameterSetName = "DisplayText", Mandatory = $true)]
		[Parameter(ParameterSetName = "DisplayWarning", Mandatory = $true)]
		[Parameter(ParameterSetName = "DisplayError", Mandatory = $true)]
		[string]
		$Message,
		
		[Parameter(ParameterSetName = "DisplayText", Mandatory = $true)]
		[switch]
		$DisplayText,
		
		[Parameter(ParameterSetName = "DisplayWarning", Mandatory = $true)]
		[switch]
		$DisplayWarning,
		
		[Parameter(ParameterSetName = "DisplayError", Mandatory = $true)]
		[switch]
		$DisplayError
	)
	
	if ($DisplayText -eq $true) {
		
		Write-Host -Message $Message
		
	}elseif ($DisplayWarning -eq $true) {
		
		Write-Warning -Message $Message
		
	}elseif ($DisplayError -eq $true) {
		
		Write-Error -Message $Message
		
	}
	
	
}