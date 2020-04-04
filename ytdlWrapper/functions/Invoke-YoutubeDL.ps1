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
		[string]
		$ConfigPath,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job")]
		[Alias("Job")]
		[string]
		$JobName
		
	)
	
	dynamicparam {
		
		# Only run the logic if the file exists
		if ($null -ne $ConfigPath -and (Test-Path $ConfigPath) -eq $true) {
			
			# Retrieve all instances of input definitions in the config file
			$definitionList = Read-ConfigDefinitions -Path $ConfigPath -InputDefinitions
			
			#Define the dynamic parameter dictionary to add all new parameters to
			$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
			
			# Now that a list of all input definitions is found, create a dynamic parameter for each
			foreach ($definition in $definitionList) {
				
				$paramAttribute = New-Object System.Management.Automation.ParameterAttribute
				$paramAttribute.Mandatory = $true
				
				$attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
				$attributeCollection.Add($paramAttribute)				
				$param = New-Object System.Management.Automation.RuntimeDefinedParameter($definition, [String], $attributeCollection)
				
				$parameterDictionary.Add($definition, $param)
				
			}
			
			return $parameterDictionary
			
		}
		
	}
	
	process {
		
		if ($PSCmdlet.ParameterSetName -eq "Config") {
			
			# Ensure the config file actually exists
			if ((Test-Path -Path $ConfigPath) -eq $false) {
				
				Write-Message -Message "There is no file located at: $ConfigPath" -DisplayWarning
				return
				
			}
			
			$configFileContent = Get-Content -Path $ConfigPath -Raw
			
			# Retrieve all instances of input definitions in the config file
			$definitionList = Read-ConfigDefinitions -Path $ConfigPath -InputDefinitions
			
			foreach ($definition in $definitionList) {
				
				if ($PSBoundParameters.ContainsKey($definition) -eq $true) {
					
					# Replace the occurence of the input definition with the user provided value
					$configFileContent = $configFileContent -replace "i@{$definition}", $PSBoundParameters[$definition]
					
				}else {
					
					# Warn the user and exit if they've not specified one of the input definition parameters
					Write-Message -Message "You have not supplied the following user input: $definition" -DisplayWarning
					return
					
				}
				
			}
			
			# Write modified config file (with user inputs) to a temp file
			# It is easier to read in the config file than edit the existing string to work properly, by surrounding stuff in "" quotes etc
			Out-File -FilePath "$script:DataPath\temp.conf" -Force -InputObject $configFileContent
		
		}
		
		if ($PSCmdlet.ParameterSetName -eq "Job") {
			
			# Retrieve the job and heck that it exists
			$jobList = Read-Jobs -Path "$script:DataPath\database.xml"
			$job = $jobList | Where-Object { $_.Name -eq $JobName }
			
			if ($null -eq $job) {
				
				Write-Message -Message "There is no job called: $JobName" -DisplayWarning
				return
				
			}
			
			# Read in the contents of the job config file
			$configFileContent = Get-Content -Path $job.ConfigPath -Raw
			
			# Retrieve all instances of variable definitions in the config file
			$definitionList = Read-ConfigDefinitions -Path $job.ConfigPath -VariableDefinitions
			
			foreach ($definition in $definitionList) {
				
				# Replace the occurence of the variable definition with the variable value from the database
				$configFileContent = $configFileContent -replace "v@{$definition}{.*?}", $job.Variables[$definition]
				
			}
			
			# Retrieve all instances of variable scriptblocks in the config file
			$scriptblockDefinitionList = Read-ConfigDefinitions -Path $job.ConfigPath -VariableScriptblocks
			
			# Create a table linking each scriptblock to its respective definition name
			[hashtable]$scriptblockList = [ordered]@{}	
			for ($i = 0; $i -lt $definitionList.Count; $i++) {
				
				$scriptblockList.Add($definitionList[$i], [scriptblock]::Create($scriptblockDefinitionList[$i]))
				
			}
			
			# Write modified config file (with user inputs) to a temp file
			# It is easier to read in the config file than edit the existing string to work properly, by surrounding stuff in "" quotes etc
			Out-File -FilePath "$script:DataPath\temp.conf" -Force -InputObject $configFileContent
			
		}
		
		# Define youtube-dl process information
		$processStartupInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
			FileName = "youtube-dl"
			Arguments = "--config-location `"$script:DataPath\temp.conf`""
			UseShellExecute = $false
		}
		
		# Start and wait for youtube-dl to finish
		$process = New-Object System.Diagnostics.Process
		$process.StartInfo = $processStartupInfo
		$process.Start()
		
		$process.WaitForExit()
		$process.Dispose()
		
		# Delete the temp config file since its no longer needed
		Remove-Item -Path "$script:DataPath\temp.conf" -Force
		
		# Execute any scriptblocks for variables
		if ($PSCmdlet.ParameterSetName -eq "Job") {
			
			# Run every scriptblock, and store the result back into the databasee
			foreach ($key in $scriptblockList.Keys) {
				
				$return = Invoke-Command -ScriptBlock $scriptblockList[$key]
				
				if ($null -eq $return) {
					
					Write-Message -Message "The scriptblock for the $key variable definition didn't return a value. It must return a value." -DisplayError
					return
					
				}
				
				$job.Variables[$key] = $return
				
			}
			
		}
		
		# Save the modified job (if any scriptblocks ran) to the database file
		Export-Clixml -Path "$script:DataPath\database.xml" -InputObject $jobList
		
	}
	
	
}