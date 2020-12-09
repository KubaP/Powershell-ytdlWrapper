<#
.SYNOPSIS
	Read the definitions from a config file.
	
.DESCRIPTION
	Read in either input definitions, variable definitions, or variable
	scriptblock declerations from a youtube-dl configuration file.
	
.EXAMPLE
	PS C:\> Read-ConfigDefinitions -Path "~/conf.txt" -InputDefinitions
	
	Reads in and generates a list of all input definition names.
	
.INPUTS
	None
	
.OUTPUTS
	System.Collections.Generic.List[System.String]
	
.NOTES
	
#>
function Read-ConfigDefinitions {
	
	[CmdletBinding()]
	param (
		
		[Parameter(Position = 0, Mandatory = $true)]
		[String]
		$Path,
		
		[Parameter()]
		[switch]
		$InputDefinitions,
		
		[Parameter()]
		[switch]
		$VariableDefinitions,
		
		[Parameter()]
		[switch]
		$VariableScriptblocks
		
	)
	
	# Read in the config file as a single string.
	$configFilestream = Get-Content -Path $Path -Raw
	$definitionList = New-Object -TypeName System.Collections.Generic.List[System.String]
	
	if ($InputDefinitions -eq $true) {
		# Find all matches to:
		# 1.	--some-parameter i@{name}	: full parameter definition
		# 1.	-s i@{name}					: shorthand parameter definition
		# 2.	'i@{Url}'					: special case for url, since it doesn't have a flag
		# Also matches even if multiple parameter definitions are on the same line.
		$regex = [regex]::Matches($configFilestream, "(-(\S+)\s'?i@{(\w+)}'?)\s*")
		$url = [regex]::Match($configFilestream, "'i@{url}'", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
		
		# Add the definition name fields to the list.
		foreach ($match in $regex) {
			# .Group[1] is the whole match
			# .Group[2] is the 'some-parameter' or 's' match
			# .Group[3] is the 'name' match
			$definitionList.Add($match.Groups[3].Value)
		}
		# If a url input is detected, add that too.
		if ($url.Success) {
			$definitionList.Add("Url")
		}
	}
	else {
		# Find all matches to:
		# 1.	--some-parameter v@{name}{start{scriptblock}end}	: full parameter definition
		# 1.	-s v@{name}{start{scritpblock}end}					: shorthand parameter definition
		# Also matches even if multiple parameter definitions are on the same line.
		$regex = [regex]::Matches($configFilestream, "(-(\S+)\s'?v@{(\w+)}{start{(?s)(.*?)}end}'?)\s+")
		
		# Add the descriptor fields to the list.
		foreach ($match in $regex) {
			# .Group[1] is the whole match
			# .Group[2] is the 'some-parameter' or 's' match
			# .Group[3] is the 'name' match
			# .Group[4] is the 'scriptblock' match
			if ($VariableDefinitions -eq $true) {
				$definitionList.Add($match.Groups[3].Value)
			}
			elseif ($VariableScriptblocks -eq $true) {
				$definitionList.Add($match.Groups[4].Value)
			}
		}
	}
	
	# Return the list as a List object, rather than as an array (by default).
	Write-Output $definitionList -NoEnumerate
}