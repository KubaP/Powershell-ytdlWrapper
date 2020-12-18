<#
.SYNOPSIS
	Changes a value of a youtube-dl item.
	
.DESCRIPTION
	The `Set-YoutubeDlItem` cmdlet changes the value of a  youtube-dl template
	or job.
	
	This cmdlet can be used to change a template's/job's path of the location
	of the configuration file to use.
	
	This cmdlet can be used to change a value of a variable of a job.
	
	This cmdlet can be used to update a job if the configuration file changes,
	initialising any new variables which have been added since the last time, 
	and removing any now-unnecessary variables.
	
.PARAMETER Template
	Indicates that this cmdlet will be changing a youtube-dl template.
	
.PARAMETER Job
	Indicates that this cmdlet will be changing a youtube-dl job.
	
.PARAMETER Name
	Specifies the name of the item to be changed.
	
	Once you specify the '-Template'/'-Job' switch, this parameter will
	autocomplete to valid names for the respective item type.
	
.PARAMETER Path
	Specifies the new path of the location of the configuration file to use.
	
.PARAMETER Variable
	Specifies the name of the variable to change the value of for a job.
	
.PARAMETER Value
	Specifies the new value of the variable being changed.
	
.PARAMETER Update
	Updates the variables of a job to match with what the defined configuration
	file has defined.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.INPUTS
	System.String
		You can pipe the name of the item to change.
	
.OUTPUTS
	YoutubeDlTemplate
	YoutubeDlJob
	
.NOTES
	This cmdlet is aliased by default to 'sydl'.
	
.EXAMPLE
	PS C:\> Set-YoutubeDlItem -Template -Name "music" -Path ~\new\music.conf
	
	Changes the path of the location of the configuration file, for the 
	youtube-dl template named "music".
	
.EXAMPLE
	PS C:\> Set-YoutubeDlItem -Job -Name "archive" -Path ~\new\archive.conf
				
	Changes the path of the location of the configuration file, for the 
	youtube-dl job named "archive".
	
.EXAMPLE
	Assuming the job 'archive' has a variable "Autonumber"=5
	
	PS C:\> Set-YoutubeDlItem -Job -Name "archive" -Variable "Autonumber"
				-Value "100"
	
	Changes the "Autonumber" variable of the job named "archive" to the new
	value of "100". The next time the job will be run, this new value will 
	be used.
	
.EXAMPLE
	Assuming the job 'archive' has the variables "Autonumber"=5 and 
	"Format"=best.
	
	Assuming the configuration file has the variable definitions "Autonumber"
	and "Quality".
	
	PS C:\> Set-YoutubeDlItem -Job -Name "archive" -Update -Quality "normal"
	
	Updates the job named "archive" to reflect its modified configuration file.
	The configuration file has a new variable named "Quality", whose initial
	value is provided through the '-Quality' parameter. The configuration file
	lacks the "Format" variable now, so that is deleted from the job.
	
.LINK
	Get-YoutubeDlItem
	Set-YoutubeDlItem
	Remove-YoutubeDlItem
	about_ytdlWrapper
	
#>
function Set-YoutubeDlItem
{
	[Alias("sydl")]
	
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
		
		[Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
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
			Write-Verbose "Validating parameters and the configuration file."
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
			
			Write-Verbose "Changing the path property of the template object."
			$templateObject.Path = $Path
			
			if ($PSCmdlet.ShouldProcess("Updating database at '$script:TemplateData' with the changes.", "Are you sure you want to update the database at '$script:TemplateData' with the changes?", "Save File Prompt"))
			{
				Export-Clixml -Path $script:TemplateData -InputObject $templateList -Force -WhatIf:$false `
					-Confirm:$false | Out-Null
			}
		}
		elseif ($Job -and -not $Update)
		{
			# If the job doesn't exist, warn the user.
			$jobList = Read-Jobs
			$jobObject = $jobList | Where-Object { $_.Name -eq $Name }
			Write-Verbose "Validating parameters and the configuration file."
			if ($null -eq $jobObject)
			{
				Write-Error "There is no job named: '$Name'."
				return
			}
			
			if ($Path)
			{
				if (-not (Test-Path -Path $Path))
				{
					Write-Error "The configuration file path: '$Path' is invalid!"
					return
				}
				
				Write-Verbose "Changing the path property of the job object."
				$jobObject.Path = $Path
			}
			else
			{
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
				
				# Validate that the variable-to-modify exists.
				if ($jobObject._Variables.Keys -notcontains $Variable)
				{
					Write-Error "The job: '$name' does not contain the variable named: '$Variable'!"
					return
				}
				
				if ([System.String]::IsNullOrWhiteSpace($Value)) 
				{
					Write-Error "The new value for the variable: '$Variable' cannot be empty!"
					return
				}
				
				Write-Verbose "Changing the variable property of the job object."
				$jobObject._Variables[$Variable] = $Value
			}
			
			if ($PSCmdlet.ShouldProcess("Updating database at '$script:JobData' with the changes.", "Are you sure you want to update the database at '$script:JobData' with the changes?", "Save File Prompt"))
			{
				Export-Clixml -Path $script:JobData -InputObject $jobList -WhatIf:$false -Confirm:$false `
					| Out-Null
			}
			
		}
		elseif ($Job -and $Update)
		{
			# If the job doesn't exist, warn the user.
			$jobList = Read-Jobs
			$jobObject = $jobList | Where-Object { $_.Name -eq $Name }
			Write-Verbose "Validating parameters and the configuration file."
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
			Write-Verbose "Updating the variables of the job object."
			$jobObject._Variables = $variableList
			if ($PSCmdlet.ShouldProcess("Updating database at '$script:JobData' with the changes.", "Are you sure you want to update the database at '$script:JobData' with the changes?", "Save File Prompt"))
			{
				Export-Clixml -Path $script:JobData -InputObject $jobList -WhatIf:$false -Confirm:$false `
					| Out-Null
			}
		}
	}
}