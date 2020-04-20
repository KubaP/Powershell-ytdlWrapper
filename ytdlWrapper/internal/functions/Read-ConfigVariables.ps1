function Read-ConfigDefinitions {
	<#
	.SYNOPSIS
		Read definitions from a config file
		
	.DESCRIPTION
		Read in either input definitions, variable definitions, or variable scriptblock declerations
		from a youtube-dl configuration file.
		
	.EXAMPLE
		PS C:\> Read-ConfigDefinitions -Path "~/conf.txt" -InputDefinitions
		
		Reads in and generates a list of all input definition names.
		
	.INPUTS
		None
		
	.OUTPUTS
		System.Collections.Generic.List[System.String]
		
	.NOTES
		
		
	#>
	
	[CmdletBinding()]
	param (
		
		[Parameter(Mandatory = $true)]
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
	
	# Read in the config file as a single string
	$configFilestream = Get-Content -Path $Path -Raw
	
	$definitionList = [System.Collections.Generic.List[System.String]]@()
	
	if ($InputDefinitions -eq $true) {
		
		# Find all matches to:
		# 1.	--some-parameter i@{name}	: normal parameter definition
		# 1.	-s i@{name}					: shorthand parameter definition
		# 2.	'i@{name}'					: special case for url, since it doesn't have a flag
		# Also matches even if multiple parameter definitions are on the same line
		$regex1 = [regex]::Matches($configFilestream, "(-(\S+)\s'?i@{(\w+)}'?)\s*")
		$regex2 = [regex]::Matches($configFilestream, "('i@{(\w+)}')")
		
		# Add the descriptor fields to the list
		foreach ($match in $regex1) {
			
			# .Group[1] is the whole match
			# .Group[2] is the 'some-parameter' or 's' match
			# .Group[3] is the 'name' match
			
			$definitionList.Add($match.Groups[3].Value)
			
		}
		
		foreach ($match in $regex2) {
			
			# .Group[1] is the whole match
			# .Group[2] is the 'name' match
			
			$definitionList.Add($match.Groups[2].Value)
			
		}
		
	}else {
		
		# Find all matches to:
		# 1.	--some-parameter v@{name}{start{scriptblock}end}	: normal parameter definition
		# 1.	-s v@{name}{start{scritpblock}end}					: shorthand parameter definition
		# Also matches even if multiple parameter definitions are on the same line
		$regex = [regex]::Matches($configFilestream, "(-(\S+)\s'?v@{(\w+)}{start{(?s)(.*?)}end}'?)\s+")
		
		# Add the descriptor fields to the list
		foreach ($match in $regex) {
			
			# .Group[1] is the whole match
			# .Group[2] is the 'some-parameter' or 's' match
			# .Group[3] is the 'name' match
			# .Group[4] is the 'scriptblock' match
			
			if ($VariableDefinitions -eq $true) {
				
				$definitionList.Add($match.Groups[3].Value)
				
			}elseif ($VariableScriptblocks -eq $true) {
				
				$definitionList.Add($match.Groups[4].Value)
				
			}
			
		}
		
	}
	
	# Return the list as a List object, rather than as an array (by default)
	Write-Output $definitionList -NoEnumerate
	
}