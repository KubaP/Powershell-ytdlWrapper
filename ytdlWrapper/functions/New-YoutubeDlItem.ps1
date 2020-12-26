<#
.SYNOPSIS
	Creates a new youtube-dl item.
	
.DESCRIPTION
	The `New-YoutubeDlItem` cmdlet creates a new youtube-dl template or job, 
	and sets its values in accordance to the given configuration
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
	Specifies the path of the location of the configuration file to use.
	
.PARAMETER DontMoveConfigurationFile
	Prevents the configuration file from being moved from its original location
	to a new location in the module appdata folder.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.PARAMETER Force
	Forces this cmdlet to create an item that writes over an existing item.
	Even using this parameter, if the filesystem denies access to the
	necessary files, this cmdlet will fail.
	
.INPUTS
	System.String
		You can pipe a string containing a path to the location of the 
		configuration file.
	
.OUTPUTS
	YoutubeDlTemplate
	YoutubeDlJob
	
.NOTES
	When creating a job using the '-Job' switch, a dynamic parameter
	corresponding to each variable definition, found within the configuration
	file, will be generated. The parameter sets the initial value of the
	variable to make the job ready for first-time execution.
	
	For detailed help regarding the configuration file, see the 
	"SETTING UP A CONFIGURATION FILE" section in the help at:
	'about_ytdlWrapper_jobs'.
	
	This cmdlet is aliased by default to 'nydl'.
	
.EXAMPLE
	PS C:\> New-YoutubeDlItem -Template -Name "music" -Path ~\music.conf
	
	Creates a new youtube-dl template named "music", and moves the configuration
	file to the module appdata folder.
	
.EXAMPLE
	PS C:\> New-YoutubeDlItem -Template -Name "music" -Path ~\music.conf
			 -DontMoveConfigurationFile
				
	Creates a new youtube-dl template named "music", but doesn't move the
	configuration file from the existing location. If this file is ever moved
	manually, this template will cease working until the path is updated to 
	the new location of the configuration file.
	
.EXAMPLE
	Assuming "music.conf" has an input definition named "Url".
	
	PS C:\> New-YoutubeDlItem -Template -Name "music" -Path ~\music.conf | 
			 Invoke-YoutubeDl -Template -Url "https:\\some\youtube\url"
	
	Creates a new youtube-dl template named "music", and then invokes
	youtube-dl to run it, giving in the required inputs (Url) in the process.
	
.EXAMPLE
	Assuming "archive.conf" has a variable definition named "Autonumber".
	
	PS C:\> New-YoutubeDlJob -Job -Name "archive" -Path ~\archive.conf
			 -Autonumber "5"
				
	Creates a new youtube-dl job named "archive", and moves the configuration
	file from the home directory to the module appdata foler. Also sets 
	the "Autonumber" variable within this configuration file to an initial
	value of "5".
	
.LINK
	Get-YoutubeDlItem
	Set-YoutubeDlItem
	Remove-YoutubeDlItem
	about_ytdlWrapper
	
#>
function New-YoutubeDlItem
{
	[Alias("nydl")]
	
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
		$DontMoveConfigurationFile,
		
		[Parameter()]
		[switch]
		$Force
		
	)
	
	dynamicparam
	{
		# Only run the variable detection logic if creating a new job,
		# and a valid configuration file path has been given in.
		if ($Job -and ($null -ne $Path) -and (Test-Path -Path $Path))
		{
			# Retrieve all instances of variable definitions in the config file.
			$definitionList = Read-ConfigDefinitions -Path $Path -VariableDefinitions
			
			# Define the dynamic parameter dictionary to hold new parameters.
			$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
			
			# Create a parameter for each variable definition found.
			foreach ($definition in $definitionList)
			{
				# Set up the necessary objects for a parameter.
				$paramAttribute = New-Object System.Management.Automation.ParameterAttribute
				$paramAttribute.Mandatory = $true
				$attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
				$attributeCollection.Add($paramAttribute)				
				$param = New-Object System.Management.Automation.RuntimeDefinedParameter($definition, [String], `
					$attributeCollection)
				
				$parameterDictionary.Add($definition, $param)
			}
			
			return $parameterDictionary
		}
	}
	
	begin
	{
		# Validate that '-WhatIf'/'-Confirm' isn't used together with '-Force'.
		# This is ambiguous, so warn the user instead.
		Write-Debug "`$WhatIfPreference: $WhatIfPreference"
		Write-Debug "`$ConfirmPreference: $ConfirmPreference"
		if ($WhatIfPreference -and $Force)
		{
			Write-Error "You cannot specify both '-WhatIf' and '-Force' in the invocation for this cmdlet!"
			return
		}
		if (($ConfirmPreference -eq "Low") -and $Force)
		{
			Write-Error "You cannot specify both '-Confirm' and '-Force' in the invocation for this cmdlet!"
			return
		}
	}
	
	process
	{
		if ($Template)
		{
			# Validate that the name isn't already taken.
			$templateList = Read-Templates
			$existingTemplate = $templateList | Where-Object { $_.Name -eq $Name }
			Write-Verbose "Validating parameters and the configuration file."
			if ($null -ne $existingTemplate)
			{
				if ($Force)
				{
					Write-Verbose "Existing template named: '$Name' exists, but since the '-Force' switch is present, the existing template will be deleted."
					$existingTemplate | Remove-YoutubeDlItem -Template
				}
				else
				{
					Write-Error "The name: '$Name' is already taken for a template."
					return
				}
			}
			
			# Validate that the configuration file exists and can be used.
			if ([YoutubeDlTemplate]::HasInvalidPath($Path))
			{
				Write-Error "The configuration file path: '$Path' is invalid."
				return
			}
			if ([YoutubeDlTemplate]::HasNoInput($Path))
			{
				Write-Error "The configuration file located at: '$Path' has no input definitions.`nFor help regarding the configuration file, see the `"SETTING UP A CONFIGURATION FILE`" section in the help at: `'about_ytdlWrapper_templates`'."
					return
			}
			
			if (-not $DontMoveConfigurationFile -and $PSCmdlet.ShouldProcess("Moving configuration file from '$(Split-Path -Path $Path -Parent)' to '$script:Folder\Templates'.", "Are you sure you want to move the configuration file from '$(Split-Path -Path $Path -Parent)' to '$script:Folder\Templates'?", "Move File Prompt")) 
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
			
			# Create the object and save it to the database.
			Write-Verbose "Creating new youtube-dl template object."
			$newTemplate = [YoutubeDlTemplate]::new($Name, $Path)
			$templateList.Add($newTemplate)
			if ($PSCmdlet.ShouldProcess("Saving newly-created template to database at '$script:TemplateData'.", "Are you sure you want to save the newly-created template to the database at '$script:TemplateData'?", "Save File Prompt"))
			{
				Export-Clixml -Path $script:TemplateData -InputObject $templateList -Force -WhatIf:$false `
					-Confirm:$false | Out-Null
			}
			
			Write-Output $newTemplate
		}
		elseif ($Job)
		{
			# Validate that the name isn't already taken.
			$jobList = Read-Jobs
			$existingJob = $jobList | Where-Object { $_.Name -eq $Name }
			Write-Verbose "Validating parameters and the configuration file."
			if ($null -ne $existingJob)
			{
				if ($Force)
				{
					Write-Verbose "Existing job named: '$Name' exists, but since the '-Force' switch is present, the existing job will be deleted."
					$existingJob | Remove-YoutubeDlItem -Job
				}
				else
				{
					Write-Error "The name: '$Name' is already taken for a job."
					return
				}
			}
			
			# Validate that each required variable in the configuration file
			# has been given an initial value.
			$variableDefinitions = Read-ConfigDefinitions -Path $Path -VariableDefinitions
			$initialVariableValues = @{}
			foreach ($definition in $variableDefinitions)
			{
				if ($PSBoundParameters.ContainsKey($definition))
				{
					$initialVariableValues[$definition] = $PSBoundParameters[$definition]
				}
				else
				{
					Write-Error "The variable: '$definition' has not been provided an initial value as a parameter!"
					return
				}
			}
			# Validate that the configuration file exists and can be used.
			if ([YoutubeDlJob]::HasInvalidPath($Path))
			{
				Write-Error "The configuration file path: '$Path' is invalid."
				return
			}
			if ([YoutubeDlJob]::HasInputs($Path))
			{
				Write-Error "The configuration file at: '$Path' has input definitions, which a job cannot have.`nFor help regarding the configuration file, see the `"SETTING UP A CONFIGURATION FILE`" section in the help at: `'about_ytdlWrapper_jobs`'."
				return
			}
			
			if (-not $DontMoveConfigurationFile -and $PSCmdlet.ShouldProcess("Moving configuration file from '$(Split-Path -Path $Path -Parent)' to '$script:Folder\Jobs'.", "Are you sure you want to move the configuration file from '$(Split-Path -Path $Path -Parent)' to '$script:Folder\Jobs'?", "Move File Prompt"))
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
			
			# Create the object and save it to the database.
			Write-Verbose "Creating new youtube-dl job object."
			$newJob = [YoutubeDlJob]::new($Name, $Path, $initialVariableValues, $null, $null)
			$jobList.Add($newJob)
			if ($PSCmdlet.ShouldProcess("Saving newly-created template to database at '$script:JobData'.", "Are you sure you want to save the newly-created template to the database at '$script:JobData'?", "Save File Prompt"))
			{
				Export-Clixml -Path $script:JobData -InputObject $jobList -Force -WhatIf:$false -Confirm:$false `
					| Out-Null
			}
			
			Write-Output $newJob
		}
	}
}