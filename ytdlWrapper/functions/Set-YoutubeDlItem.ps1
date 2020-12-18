function Set-YoutubeDlItem
{
	
	[CmdletBinding(SupportsShouldProcess = $true)]
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
		[switch]
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
		if ($null -eq $Name) { return }
		$jobList = Read-Jobs
		$jobObject = $jobList | Where-Object { $_.Name -eq $Name }
		if ($null -eq $jobObject) { return }
		if ($jobObject.GetState() -eq "InvalidPath") { return }
		if (-not $Update) { return }
		
		# Figure out which are the new variables in the configuration file
		# to add parameters for.
		$jobVariables = $jobObject.GetStoredVariables()
		$configVariables = $jobObject.GetVariables()
		$newVariables = $configVariables | Where-Object { $jobVariables -notcontains $_ }
		
		#Define the dynamic parameter dictionary to add all new parameters to
		$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
		
		# Now that a list of all new variable definitions is found, create a dynamic parameter for each
		foreach ($variable in $newVariables)
		{
			$paramAttribute = New-Object System.Management.Automation.ParameterAttribute
			$paramAttribute.Mandatory = $true
			$paramAttribute.ParameterSetName = "Job-Update"
			
			$attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
			$attributeCollection.Add($paramAttribute)				
			$param = New-Object System.Management.Automation.RuntimeDefinedParameter($variable, [String], `
				$attributeCollection)
			
			$parameterDictionary.Add($variable, $param)
		}
		
		# Create parameters for every uninitialised variable.
		foreach ($variable in $jobObject.GetNullVariables())
		{
			$paramAttribute = New-Object System.Management.Automation.ParameterAttribute
			$paramAttribute.Mandatory = $true
			$paramAttribute.ParameterSetName = "Job-Update"
			
			$attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
			$attributeCollection.Add($paramAttribute)				
			$param = New-Object System.Management.Automation.RuntimeDefinedParameter($variable, [String], `
				$attributeCollection)
			
			$parameterDictionary.Add($variable, $param)
		}
		
		return $parameterDictionary
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
				Write-Error "There is no template named: '$Name'."
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
			
			if ($PSCmdlet.ShouldProcess("$script:TemplateData", "Overwrite database with modified contents"))
			{
				Export-Clixml -Path $script:TemplateData -InputObject $templateList -WhatIf:$false -Confirm:$false `
					| Out-Null
			}
		}
		elseif ($Job -and -not $Update)
		{
			# TODO
		}
		elseif ($Job -and $Update)
		{
			# If the job doesn't exist, warn the user.
			$jobList = Read-Jobs
			$jobObject = $jobList | Where-Object { $_.Name -eq $Name }
			if ($null -eq $jobObject)
			{
				Write-Error "There is no job named: '$Name'."
				return
			}
			
			# Validate that the job can be used.
			switch ($jobObject.GetState())
			{
				"InvalidPath"
				{
					Write-Error "The job: '$name' has a configuration file path: '$($jobObject.Path)' which is invalid!"
					return
				}
				"HasInputs"
				{
					Write-Error "The job: '$name' has input definitions which a job cannot have!`nFor help regarding the configuration file, see the `"#TODO`" section in the help at: `'about_ytdlWrapper_jobs`'."
					return
				}
			}
			
			# Figure out which are the new variables in the configuration file
			# and which variables in the job (may) need to be removed.
			$jobVariables = $jobObject.GetStoredVariables()
			$configVariables = $jobObject.GetVariables()
			$newVariables = $configVariables | Where-Object { $jobVariables -notcontains $_ }
			$oldVariables = $jobVariables | Where-Object { $configVariables -notcontains $_ }
			
			$variableList = $jobObject._Variables
			# First remove all of the not-needed-anymore variables from the
			# hashtable.
			foreach ($key in $oldVariables)
			{
				$variableList.Remove($key)
			}
			# Then add all of the new variables which need an initial value
			# before the job can be ran.
			foreach ($key in $newVariables)
			{
				if ($PSBoundParameters.ContainsKey($key))
				{
					$variableList[$key] = $PSBoundParameters[$key]
				}
				else
				{
					Write-Error "The new variable: '$key' has not been provided an initial value as a parameter!"
					return
				}
			}
			# Then set the values of any uninitialised variables too.
			foreach ($key in $jobObject.GetNullVariables())
			{
				if ($PSBoundParameters.ContainsKey($key))
				{
					$variableList[$key] = $PSBoundParameters[$key]
				}
				else
				{
					Write-Error "The existing variable: '$key' has not been provided an initial value as a parameter!"
					return
				}
			}
			
			# Set the modified variable hashtable.
			$jobObject._Variables = $variableList
			if ($PSCmdlet.ShouldProcess("$script:JobData", "Overwrite database with modified contents"))
			{
				Export-Clixml -Path $script:JobData -InputObject $jobList -WhatIf:$false -Confirm:$false `
					| Out-Null
			}
		}
	}
}