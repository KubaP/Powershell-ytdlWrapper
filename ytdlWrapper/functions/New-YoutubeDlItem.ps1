﻿<#
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
	
.PARAMETER CreateTemplate
	Indicates that this cmdlet will be creating a youtube-dl template.
	
.PARAMETER CreateJob
	Indicates that this cmdlet will be creating a youtube-dl job.
	
.PARAMETER Name
	Specifies the name/identifier of this template/job; must be unique.
	
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
	PS C:\> New-YoutubeDlItem -CreateTemplate -Name "music" -Path ~\music.conf
	
	Creates a new youtube-dl template named "music", and moves the configuration
	file from the home directory to the module appdata folder.
	
.EXAMPLE
	PS C:\> New-YoutubeDlItem -CreateTemplate -Name "music" -Path ~\music.conf
				-DontMoveConfigurationFile
				
	Creates a new youtube-dl template named "music", but doesn't move the
	configuration file from the home directory.
	
.EXAMPLE
	PS C:\> New-YoutubeDlJob -CreateJob -Name "archive" -Path ~\archive.conf
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
		[Alias("Template")]
		[switch]
		$CreateTemplate,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job")]
		[Alias("Job")]
		[switch]
		$CreateJob,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Position = 2, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("ConfigPath")]
		[string]
		$Path,
		
		[Parameter(Position = 3)]
		[switch]
		$DontMoveConfigurationFile
		
	)
	
	dynamicparam
	{
		if ($CreateJob -and ($null -ne $Path) -and (Test-Path -Path $Path))
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
		# Validate the config file exists.
		if (-not (Test-Path -Path $Path))
		{
			Write-Error "The configuration file path: '$Path' points to an invalid/non-existent location!"
			return
		}
		
		if ($CreateTemplate)
		{
			$templateList = Read-Templates
			
			# Validate that the name isn't already taken.
			$existingTemplate = $templateList | Where-Object { $_.Name -eq $Name }
			if ($null -ne $existingTemplate)
			{
				Write-Error "The name: '$Name' is already taken!"
				return
			}
			
			# Validate that at least one input is present for this template
			# to make sense.
			if ((Read-ConfigDefinitions -Path $Path -InputDefinitions).Count -eq 0)
			{
				Write-Error "The configuration file located at: '$Path' does not have a single input definition!`nFor help regarding the configuration file, see the `"#TODO`" section in the help at: `'about_ytdlWrapper`'."
				return
			}
			
			if (-not $DontMoveConfigurationFile -and $PSCmdlet.ShouldProcess("$Path", `
				"Move configuration file to module appdata folder"))
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
				Export-Clixml -Path $script:TemplateData -InputObject $templateList -WhatIf:$false -Confirm:$false | Out-Null
			}
			
			Write-Output $newTemplate
		}
		elseif ($CreateJob)
		{
			$jobList = Read-Jobs
			
			# Validate that the name isn't already taken.
			$existingJob = $jobList | Where-Object { $_.Name -eq $Name }
			if ($null -ne $existingJob)
			{
				Write-Error "The name: '$Name' is already taken!"
				return
			}
			
			# Validate that at there are no inputs as this is an automated
			# job, not a template.
			if ((Read-ConfigDefinitions -Path $Path -InputDefinitions).Count -ne 0)
			{
				Write-Error "The configuration file located at: '$Path' has input definitions!`nFor help regarding the configuration file, see the `"#TODO`" section in the help at: `'about_ytdlWrapper`'."
				return
			}
			
			# Validate that for each variable definition, an initial value has
			# been provided as a parameter.
			$definitionList = Read-ConfigDefinitions -Path $Path -VariableDefinitions
			$initialVariableValues = New-Object -TypeName hashtable
			foreach ($definition in $definitionList)
			{
				if ($PSBoundParameters.ContainsKey($definition))
				{
					$initialVariableValues[$definition] = $PSBoundParameters[$definition]
				}
				else
				{
					Write-Error "The variable: '$definition' has not been provided with an initial value!"
					return
				}
			}
			
			if (-not $DontMoveConfigurationFile -and $PSCmdlet.ShouldProcess("$Path", `
				"Move configuration file to module appdata folder"))
			{
				# Move the file over to the module appdata folder, and rename it
				# to the unique name of the template to avoid any potential
				# filename collisions.
				$fileName = Split-Path -Path $Path -Leaf
				Move-Item -Path $Path -Destination "$script:Folder\Jobs" -Force -WhatIf:$false -Confirm:$false | Out-Null
				Rename-Item -Path "$script:Folder\Jobs\$fileName" -NewName "$Name.conf" -Force -WhatIf:$false -Confirm:$false | Out-Null
				$Path = "$script:Folder\Jobs\$Name.conf"
			}
			
			# Create the object and save it to the database file.
			$newJob = [YoutubeDlJob]::new($Name, $Path, $initialVariableValues)
			$jobList.Add($newJob)
			if ($PSCmdlet.ShouldProcess("$script:JobData", "Overwrite database with modified contents"))
			{
				Export-Clixml -Path $script:JobData -InputObject $templateList -WhatIf:$false -Confirm:$false | Out-Null
			}
			
			Write-Output $newJob
		}
	}
}