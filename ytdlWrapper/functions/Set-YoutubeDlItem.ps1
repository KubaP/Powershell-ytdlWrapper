function Set-YoutubeDlItem
{
	
	[CmdletBinding()]
	param
	(
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Template")]
		[switch]
		$Template,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job-Path")]
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job-Update")]
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job-Property")]
		[switch]
		$Job,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Position = 2, Mandatory = $true, ParameterSetName = "Template")]
		[Parameter(Position = 2, Mandatory = $true, ParameterSetName = "Job-Path")]
		[Alias("ConfigurationFilePath")]
		[string]
		$Path,
		
		[Parameter(Position = 2, Mandatory = $true, ParameterSetName = "Job-Update")]
		$Update,
		
		# TODO: Tab completion.
		[Parameter(Position = 2, Mandatory = $true, ParameterSetName = "Job-Property")]
		[string]
		$Variable,
		
		[Parameter(Position = 3, Mandatory = $true, ParameterSetName = "Job-Property")]
		$Value		
		
	)
	
	dynamicparam
	{
		# Only run the variable detection logic if a job is given, and the job
		# exists, and it has a valid configuration file path, and the '-Update'
		# switch is on.
		if (-not $Job) { return }
		if ($null -eq $Names) { return }
		$jobList = Read-Jobs
		$jobObject = $jobList | Where-Object { $_.Name -eq $name }
		if ($null -eq $jobObject) { return }
		if ($jobObject.GetState() -eq "InvalidPath") { return }
		if (-not $Update) { return }
		
		
		
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
	
	process
	{
		if ($Template)
		{
			# If the template doesn't exist, warn the user.
			$templateList = Read-Templates
			$templateObject = $templateList | Where-Object { $_.Name -eq $Name }
			if ($null -eq $templateObject)
			{
				Write-Error "There is no template named: '$name'."
				return
			}
			
			# Validate that the new configuration file exists and can be used.
			switch ([YoutubeDlTemplate]::GetState($Path)) {
				"InvalidPath"
				{
					Write-Error "The configuration file path: '$Path' is invalid."
					return
				}
				"NoInputs"
				{
					Write-Error "The configuration file located at: '$Path' has no input definitions.`nFor help regarding the configuration file, see the `"#TODO`" section in the help at: `'about_ytdlWrapper_templates`'."
					return
				}
			}
			
			$templateObject.Path = $Path
			
			Export-Clixml -Path $script:TemplateData -InputObject $templateList -WhatIf:$false -Confirm:$false `
				| Out-Null
		}
		elseif ($Job -and -not $Update)
		{
			
		}
		elseif ($Job -and $Update)
		{
			
		}
	}
}