function Set-YoutubeDLJob {
	<#
	.SYNOPSIS
		Set a property of a job
		
	.DESCRIPTION
		Set a property of a youtube-dl job definition, such as the configurataion filepath, or a variable value.
		This command also allows to sync up the job variables to the definitions in the config file, if the
		configuration file has been modified, i.e. variables added/removed.
		
	.PARAMETER JobName
		The name of the job to configure. Accepts multiple names in an array.
		
	.PARAMETER Variable
		The variable to edit.
		
	.PARAMETER Value
		The new value for the variable.
		
	.PARAMETER ConfigPath
		The new filepath pointing to the configuration file.
		
	.PARAMETER Scriptblock
		The new scriptblock to use post-execution.
		
	.PARAMETER Update
		Sync the job variable definitions to the definitions found in the configuration file. Use this switch
		if the variables have been added/removed from the configuration file.
		
	.EXAMPLE
		PS C:\> Set-YoutubeDLJob -JobName "test" -Variable "number" -Value "123"
		
		Sets the variable "number" to the new value of "123" for the job named "test".
		
	.EXAMPLE
		PS C:\> Set-YoutubeDLJob -JobName "test" -ConfigPath "~/new-config.txt"
		
		Sets the configuration filepath for the job named "test".
		
	.EXAMPLE
		PS C:\> Set-YoutubeDLJob -JobName "test" -Scriptblock $script
		
		Sets the scriptblock for the job named "test" to the scriptblock $script.
		
	.EXAMPLE
		PS C:\> Set-YoutubeDLJob -JobName "test" -Update -NewVariable "value"
		
		Sets the value for the non-initialised variable "NewVariable" to "value", for the job "test".
		
	.INPUTS
		System.String[]
		
	.OUTPUTS
		None
		
	.NOTES
		When using the -Update switch, once a valid job name has been supplied, the function will create
		parameters at runtime for each new (non-initialised) variable found in the configuration file, so if
		for example the configuration file has the new variable: "NewVariable" added to it, the parameter
		-NewVariable will be exposed.To see all the parameters, pressing Ctrl+Tab will show
		the variable parameters at the top of the list. The function will also automatically delete any records
		of variables that are no longer present in the configuration file.
		
	#>
	
	[CmdletBinding()]
	param (
		
		# Tab completion
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = "Variable")]
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = "Config")]
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = "Scriptblock")]
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = "Update")]
		[Alias("Job", "Name")]
		[string]
		$JobName,
		
		# Tab completion once jobname is given
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Variable")]
		[string]
		$Variable,
		
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Config")]
		[string]
		$ConfigPath,
		
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Scriptblock")]
		[scriptblock]
		$Scriptblock,
		
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Update")]
		[switch]
		$Update,
		
		[Parameter(Position = 2, Mandatory = $true, ParameterSetName = "Variable")]
		[string]
		$Value
		
	)
	
	dynamicparam {
		
		# Read in the list of job objects and try to get the job
		$jobList = Get-Jobs -Path "$script:DataPath\database.xml"
		$job = $jobList | Where-Object { $_.Name -eq $JobName }
		
		# Only run if a valid job name has been given and the -Update switch is on
		if (($null -ne $job) -and ($Update -eq $true)) {
			
			# Get a list of definitions stored in the job in the config file
			$jobDefinitions = $job.Variables.Keys
			$configDefinitions = Read-ConfigDefinitions -Path $job.ConfigPath -VariableDefinitions
			
			# Find a list of variables which need to be added
			$variablesToAdd = $configDefinitions | Where-Object { $jobDefinitions -notcontains $_ }
			
			#Define the dynamic parameter dictionary to add all new parameters to
			$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
			
			# Now that a list of all new variable definitions is found, create a dynamic parameter for each
			foreach ($variable in $variablesToAdd) {
				
				$paramAttribute = New-Object System.Management.Automation.ParameterAttribute
				$paramAttribute.Mandatory = $true
				$paramAttribute.ParameterSetName = "Update"
				
				$attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
				$attributeCollection.Add($paramAttribute)				
				$param = New-Object System.Management.Automation.RuntimeDefinedParameter($variable, [String], $attributeCollection)
				
				$parameterDictionary.Add($variable, $param)
				
			}
			
			return $parameterDictionary
			
		}
		
	}
	
	process {
		
		# Read in the list of job objects
		$jobList = Get-Jobs -Path "$script:DataPath\database.xml"
			
		# Check that the job exists
		$job = $jobList | Where-Object { $_.Name -eq $JobName }
		if ($null -eq $job) {
			
			Write-Message -Message "There is no job called: $JobName" -DisplayWarning
			return
			
		}
		
		if ($PSCmdlet.ParameterSetName -eq "Variable") {
			
			# Check that the variable is valid and exists
			if ($job.Variables.ContainsKey($Variable) -eq $false) {
				
				Write-Message -Message "There is no variable called: $Variable for the job: $JobName" -DisplayWarning
				return
				
			}
			
			# Set the variable value to the newly specified value
			$job.Variables[$Variable] = $Value
			
		}elseif ($PSCmdlet.ParameterSetName -eq "Config") {
			
			# Set the configuration filepath to the new value
			$job.ConfigPath = $ConfigPath
			
		}elseif ($PSCmdlet.ParameterSetName -eq "Scriptblock") {
			
			# Set the scriptblock to the new one, if there is no previously assigned scriptblock create a new one
			if ($null -ne $job.Scriptblock) {
				
				$job.Scriptblock = $Scriptblock.ToString()
				
			}else {
				
				$job | Add-Member -NotePropertyName "Scriptblock" -NotePropertyValue $Scriptblock.ToString()
				
			}
			
		}elseif ($PSCmdlet.ParameterSetName -eq "Update") {
			
			# Get a list of definitions stored in the job in the config file
			$jobDefinitions = $job.Variables.Keys
			$configDefinitions = Read-ConfigDefinitions -Path $job.ConfigPath -VariableDefinitions
			
			# Find a list of variables which need to be removed and remove them all
			$variablesToRemove = $jobDefinitions | Where-Object { $configDefinitions -notcontains $_ }
			foreach ($variable in $variablesToRemove) {
				
				$job.Variables.Remove($variable)
				
			}
			
			# Find a list of variables which need to be added and add them from the user passed in parameters
			$variablesToAdd = $configDefinitions | Where-Object { $jobDefinitions -notcontains $_ }
			foreach ($variable in $variablesToAdd) {
				
				$job.Variables.Add($variable, $PSBoundParameters[$variable])
				
			}
			
		}
		
		# Save the modified database file with the job changes
		Export-Clixml -Path "$script:DataPath\database.xml" -InputObject $jobList | Out-Null
		
	}
	
}