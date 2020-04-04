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
		$ConfigPath,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job")]
		[Alias("Job")]
		[String]
		$JobName
		
	)
	
	dynamicparam {
		
		# Only run the logic if the file exists
		if ((Test-Path $ConfigPath) -eq $true) {
			
			# Retrieve all instances of input variables in the config file
			$dynamicInputList = Get-ConfigVariables -Path $ConfigPath
			
			#Define the dynamic parameter dictionary to add all new parameters to
			$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
			
			# Now that a list of all input parameters is found, create a dynamic parameter for each
			foreach ($userInput in $dynamicInputList) {
				
				$paramAttribute = New-Object System.Management.Automation.ParameterAttribute
				$paramAttribute.Mandatory = $true
				
				$attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
				$attributeCollection.Add($paramAttribute)				
				$param = New-Object System.Management.Automation.RuntimeDefinedParameter($userInput, [String], $attributeCollection)
				
				$parameterDictionary.Add($userInput, $param)
				
			}
			
			return $parameterDictionary
			
		}
		
	}
	
	process {
		
		# This logic replaces 
		if ($PSCmdlet.ParameterSetName -eq "Config") {
			
			# Ensure the config file actually exists
			if ($null -eq (Test-Path -Path $ConfigPath)) {
				
				Write-Message -Message "There is no file located at: $ConfigPath" -DisplayError
				return
				
			}
			
			$configFileContent = Get-Content -Path $ConfigPath -Raw
			
			# Retrieve all instances of input variables in the config file
			$dynamicInputList = Get-ConfigVariables -Path $ConfigPath
			
			foreach ($inputField in $dynamicInputList) {
				
				if ($PSBoundParameters.ContainsKey($inputField) -eq $true) {
					
					# Replace the occurence of the input field with the user provided value
					$configFileContent = $configFileContent -replace "i@{$inputField}", $PSBoundParameters[$inputField]
					
				}else {
					
					# Warn the user and exit if they've not specified one of the input field parameters
					Write-Message -Message "You have not supplied the following user input: $inputField" -DisplayError
					return
					
				}
				
			}
			
			# Write modified config file (with user inputs) to a temp file
			# It is easier to read in the config file than edit the existing string to work properly, by surrounding stuff in "" quotes etc
			Out-File -FilePath "$script:DataPath\temp.conf" -Force -InputObject $configFileContent
		
		}
		
		if ($PSCmdlet.ParameterSetName -eq "Job") {
			
			# Check that job exists
			
			# Read in the contents of the job config file
			
			# Retrieve all instances of live variables in the config file
			
			foreach ($liveVariable in $dynamicVariableList) {
				
				# Perform live variable logic
				
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
		
		# Delete the temp config file
		Remove-Item -Path "$script:DataPath\temp.conf" -Force
		
	}
	
	
}