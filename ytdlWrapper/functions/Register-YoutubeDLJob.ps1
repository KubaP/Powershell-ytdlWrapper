function Register-YoutubeDLJob {
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
		
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[Alias("Path")]
		[string]
		$ConfigPath
		
	)
	
	dynamicparam {
		
		# Only run the logic if the file exists
		if ((Test-Path -Path $ConfigPath) -eq $true) {
			
			# Retrieve all instances of variable definitions in the config file
			$definitionList = Read-ConfigDefinitions -Path $ConfigPath -VariableDefinitions
			
			#Define the dynamic parameter dictionary to add all new parameters to
			$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
			
			# Now that a list of all variable definitions is found, create a dynamic parameter for each
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
		
		# Read in the list of job objects
		$jobList = Read-Jobs -Path "$script:DataPath\database.xml"
		
		# Check that the job name isn't already taken
		$job = $jobList | Where-Object { $_.Name -eq $Name }
		if ($null -ne $job) {
			
			Write-Message -Message "There already exists a job called: $Name" -DisplayWarning
			return
			
		}
		
		# Ensure the config file actually exists
		if ((Test-Path -Path $ConfigPath) -eq $false) {
				
			Write-Message -Message "There is no file located at: $ConfigPath" -DisplayWarning
			return
			
		}
		
		# Retrieve all instances of variable definitions in the config file
		$definitionList = Read-ConfigDefinitions -Path $ConfigPath -VariableDefinitions
		
		# Set up the job object
		$job = New-Object -TypeName psobject
		$job.PSObject.TypeNames.Insert(0, "youtube-dl.Job")		
		$job | Add-Member -NotePropertyName "Name" -NotePropertyValue $Name
		$job | Add-Member -NotePropertyName "ConfigPath" -NotePropertyValue $ConfigPath
		
		# Add the user-provided variable values to the job object
		[hashtable]$variableList = [ordered]@{}		
		foreach ($definition in $definitionList) {
			
			$variableList.Add($definition, $PSBoundParameters[$definition])
			
		}
		
		$job | Add-Member -NotePropertyName "Variables" -NotePropertyValue $variableList
		$jobList.Add($job)
		
		# Save the newly created job to the database file
		Export-Clixml -Path "$script:DataPath\database.xml" -InputObject $jobList
		
	}
	
	
}
