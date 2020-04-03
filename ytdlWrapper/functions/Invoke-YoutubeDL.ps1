function Invoke-YoutubeDL {
	<#
	.SYNOPSIS
		Short description
		
	.DESCRIPTION
		Long description
		
	.EXAMPLE
		PS C:\> <example usage>
		Explanation of what the example does
		
	.INPUTS
		Inputs (if any)
		
	.OUTPUTS
		Output (if any)
		
	.NOTES
		General notes
		
	#>
	
	[CmdletBinding()]
	param (
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Config")]
		[Alias("Path")]
		[String]
		$ConfigPath
		
	)
	
	dynamicparam {
		
		# Only run the logic if the file exists
		if ((Test-Path $ConfigPath) -eq $true) {
			
			# Read in the config file
			$configFilestream = Get-Content -Path $ConfigPath
			
			$dynamicInputList = [System.Collections.Generic.List[System.String]]@()
			
			# Iterate through all lines in the config file when regexing
			foreach ($line in $configFilestream) {
				
				# Find all matches to:
				# 1.	--some-parameter i@{description}	: normal parameter definition
				# 1.	-s i@{description}					: shorthand parameter definition
				# 2.	'i@{description}'					: special case for url, since it doesn't have a flag
				# Also matches even if multiple parameter definitions are on the same line
				$regex1 = [regex]::Matches($line, "(-(\S+)\s'?i@{(\w+)}'?)\s*")
				$regex2 = [regex]::Matches($line, "('i@{(\w+)}')")
				
				# Add the descriptor fields to the list
				foreach ($match in $regex1) {
					
					# .Group[1] is the whole match
					# .Group[2] is the 'some-parameter' or 's' match
					# .Group[3] is the 'description' match
					
					$dynamicInputList.Add($match.Groups[3].Value)
					
				}
				
				foreach ($match in $regex2) {
					
					# .Group[1] is the whole match
					# .Group[2] is the 'description' match
					
					$dynamicInputList.Add($match.Groups[2].Value)
					
				}
				
			}
			
			#Define the dynamic parameter dictionary to add all new parameters to
			$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
			
			# Now that a list of all input parameters is found, create dynamic parameters for each
			foreach ($input in $dynamicInputList) {
				
				$paramAttribute = New-Object System.Management.Automation.ParameterAttribute
				$paramAttribute.Mandatory = $true
				#$paramAttribute.Position = ?
				#$paramAttribute.HelpMessage = "?"
				
				$attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
				$attributeCollection.Add($paramAttribute)				
				$param = New-Object System.Management.Automation.RuntimeDefinedParameter($input, [String], $attributeCollection)
				
				$parameterDictionary.Add($input, $param)
				
			}
			
			return $parameterDictionary
			
		}
		
	}
	
	begin {
		
		$PSBoundParameters
		
	}
	
	process {
		
		# Ensure the config file actually exists
		if ($null -eq (Test-Path -Path $ConfigPath)) {
			
			Write-Message -Message "There is no file located at: $ConfigPath" -DisplayError
			return
			
		}	
		
		
		
	}
	
	
}