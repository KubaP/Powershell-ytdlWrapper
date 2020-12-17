<#
.SYNOPSIS
	Creates a new youtube-dl item.
	
.DESCRIPTION
	The `New-YoutubeDlItem` cmdlet creates a new youtube-dl template or job  
	definition, and sets its values in accordance to the given configuration
	file.
	
	This cmdlet can be used to create a youtube-dl template, which takes in
	a configuration file with input definitions. Alternatively, this cmdlet
	can be used to create a youtube-dl job, which takes in a configuration
	file with variable definitions.
	
	This cmdlet can optionally keep the configuration files in their original
	location if desired.
	
.PARAMETER Template
	Indicates that this cmdlet will be creating a youtube-dl template.
	
.PARAMETER Job
	Indicates that this cmdlet will be creating a youtube-dl job.
	
.PARAMETER Name
	Specifies the name of the item to be created; must be unique.
	
.PARAMETER Path
	Specifies the path of the location of the configuration file to use. The
	default is the current location if no value is given in.
	
.PARAMETER DontMoveConfigurationFile
	Prevents the configuration file from being moved from its original location
	to a new location in the module appdata folder.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.INPUTS
	System.String
		You can pipe a string containing a path to the location of the 
		configuration file.
	
.OUTPUTS
	YoutubeDlTemplate
	YoutubeDlJob
	
.NOTES
	When creating a job using the '-CreateJob' switch, a dynamic parameter
	corresponding to each variable definition, found within the configuration
	file, will be generated. This parameter sets the initial value of the
	variable to make the job ready for first-time execution.
	
	For detailed help regarding the configuration file, see the 
	"#TODO" section in the help at: 'about_ytdlWrapper'.
	
	This cmdlet is aliased by default to '#TODO'.
	
.EXAMPLE
	PS C:\> New-YoutubeDlItem -Template -Name "music" -Path ~\music.conf
	
	Creates a new youtube-dl template named "music", and moves the configuration
	file from the home directory to the module appdata folder.
	
.EXAMPLE
	PS C:\> New-YoutubeDlItem -Template -Name "music" -Path ~\music.conf
				-DontMoveConfigurationFile
				
	Creates a new youtube-dl template named "music", but doesn't move the
	configuration file from the home directory.
	
.EXAMPLE
	PS C:\> New-YoutubeDlJob -Job -Name "archive" -Path ~\archive.conf
				-Autonumber "5"
				
	Creates a new youtube-dl job named "archive", and moves the configuration
	file from the home directory to the module appdata foler. This also sets 
	the 'Autonumber' variable within this configuration file to an initial
	value of "5".
	
#>
function New-YoutubeDlItem
{
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Template")]
		[switch]
		$Template,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job")]
		[switch]
		$Job,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Position = 2, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("ConfigurationFilePath")]
		[string]
		$Path,
		
		[Parameter(Position = 3)]
		[switch]
		$DontMoveConfigurationFile
		
	)
	
	dynamicparam
	{
		if ($Job -and ($null -ne $Path) -and (Test-Path -Path $Path))
		{
			# Retrieve all instances of variable definitions in the config file.
			$definitionList = Read-ConfigDefinitions -Path $Path -VariableDefinitions
			
			# Define the dynamic parameter dictionary to hold new parameters.
			$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
			# Now that a list of all input definitions is found, create a
			# dynamic parameter for each one.
			foreach ($definition in $definitionList)
			{
				# Set up the necessary objects for a parameter.
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
	
	process
	{
		if ($Template)
		{
			# Validate that the name isn't already taken.
			$templateList = Read-Templates
			$existingTemplate = $templateList | Where-Object { $_.Name -eq $Name }
			if ($null -ne $existingTemplate)
			{
				Write-Error "The name: '$Name' is already taken for a template."
				return
			}
			
			# Validate that the configuration file exists and can be used.
			switch ([YoutubeDlTemplate]::GetState($Path))
			{
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
			
			if (-not $DontMoveConfigurationFile -and
				$PSCmdlet.ShouldProcess("$Path", "Move configuration file to module appdata folder"))
			{
				# Move the file over to the module appdata folder, and rename it
				# to the unique name of the template to avoid any potential
				# filename collisions.
				$fileName = Split-Path -Path $Path -Leaf
				Move-Item -Path $Path -Destination "$script:Folder\Templates" -Force -WhatIf:$false `
					-Confirm:$false | Out-Null
				Rename-Item -Path "$script:Folder\Templates\$fileName" -NewName "$Name.conf" -Force -WhatIf:$false `
					-Confirm:$false | Out-Null
				$Path = "$script:Folder\Templates\$Name.conf"
			}
			
			# Create the object and save it to the database file.
			$newTemplate = [YoutubeDlTemplate]::new($Name, $Path)
			$templateList.Add($newTemplate)
			if ($PSCmdlet.ShouldProcess("$script:TemplateData", "Overwrite database with modified contents"))
			{
				Export-Clixml -Path $script:TemplateData -InputObject $templateList -WhatIf:$false -Confirm:$false `
					| Out-Null
			}
			
			Write-Output $newTemplate
		}
		elseif ($Job)
		{
			# Validate that the name isn't already taken.
			$jobList = Read-Jobs
			$existingJob = $jobList | Where-Object { $_.Name -eq $Name }
			if ($null -ne $existingJob)
			{
				Write-Error "The name: '$Name' is already taken for a job."
				return
			}
			
			# Validate that the configuration file exists and can be used.
			# Validate that each required variable in the configuration file
			# has been given an initial value.
			$variableList = Read-ConfigDefinitions -Path $Path -VariableDefinitions
			$initialVariableInputs = New-Object hashtable
			foreach ($variable in $variableList)
			{
				if ($PSBoundParameters.ContainsKey($variable))
				{
					$initialVariableInputs[$variable] = $PSBoundParameters[$variable]
				}
				else
				{
					Write-Error "The variable: '$variable' has not been provided an initial value as a parameter!"
					return
				}
			}

			switch ([YoutubeDlJob]::GetState($Path, $initialVariableInputs.Keys))
			{
				"InvalidPath"
				{
					Write-Error "The configuration file path: '$Path' is invalid."
					return
				}
				"MismatchedVariables"
				{
					Write-Error "There is a mismatch between the variables defined within the configuration file and the variable initial values passed to this cmdlet!`nFor help regarding the configuration file, see the `"#FUCKYOU`" section in the help at: `'about_ytdlWrapper_jobs`'."
					return
				}
				"HasInputs"
				{
					Write-Error "The configuration file at: '$Path' has input definitions, which a job cannot have!`nFor help regarding the configuration file, see the `"#TODO`" section in the help at: `'about_ytdlWrapper_jobs`'."
					return
				}
			}
			
			if (-not $DontMoveConfigurationFile -and
				$PSCmdlet.ShouldProcess("$Path", "Move configuration file to module appdata folder"))
			{
				# Move the file over to the module appdata folder, and rename it
				# to the unique name of the template to avoid any potential
				# filename collisions.
				$fileName = Split-Path -Path $Path -Leaf
				Move-Item -Path $Path -Destination "$script:Folder\Jobs" -Force -WhatIf:$false -Confirm:$false `
					| Out-Null
				Rename-Item -Path "$script:Folder\Jobs\$fileName" -NewName "$Name.conf" -Force -WhatIf:$false `
					-Confirm:$false | Out-Null
				$Path = "$script:Folder\Jobs\$Name.conf"
			}
			
			# Create the object and save it to the database file.
			$newJob = [YoutubeDlJob]::new($Name, $Path, $initialVariableInputs)
			$jobList.Add($newJob)
			if ($PSCmdlet.ShouldProcess("$script:JobData", "Overwrite database with modified contents"))
			{
				Export-Clixml -Path $script:JobData -InputObject $jobList -WhatIf:$false -Confirm:$false `
					| Out-Null
			}
			
			Write-Output $newJob
		}
	}
}