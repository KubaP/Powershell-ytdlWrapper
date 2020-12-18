<#
.SYNOPSIS
	Runs youtube-dl.
	
.DESCRIPTION
	The `Invoke-YoutubeDl` cmdlet runs youtube-dl.exe using the specified
	method.
	
	This cmdlet can be used to run youtube-dl, giving it a fully completed
	configuration file which matches the youtube-dl config specification.
	
	This cmdlet can be used to run a youtube-dl template, giving it the
	required input parameters.
	
	This cmdlet can be used to run a youtube-dl job, which happens without
	user input.
	
.PARAMETER Path
	Specifies the path of the location of the configuration file to use.
	
.PARAMETER Template
	Indicates that this cmdlet will be running a youtube-dl template.
	
.PARAMETER Job
	Indicates that this cmdlet will be running a youtube-dl job.
	
.PARAMETER Names
	Specifies the name(s) of the items to get.
	
	Once you specify the '-Template'/'-Job' switch, this parameter will
	autocomplete to valid names for the respective item type.
	
	If specifying the '-Template' switch, you can only pass in one name.
	
	If specifying the '-Job' switch, you can pass in multiple names.
	
.EXAMPLE
	PS C:\> Invoke-YoutubeDl -Path ~\download.conf
	
	Runs youtube-dl, giving it the "download.conf" configuration file to parse.
	The configuration file must fully align to the youtube-dl config
	specification.
	
.EXAMPLE
	Assuming the template 'music' has the input named "Url".
	
	PS C:\> Invoke-YoutubeDl -Template -Name "music" -Url "https:\\some\url"
	
	Runs the "music" template, which takes in the '-Url' parameter to complete
	the configuration file, before giving it to youtube-dl.
	
.EXAMPLE
	PS C:\> Invoke-YoutubeDl -Job -Name "archive"
	
	Runs the "archive" job, which uses the stored variables to complete the
	configuration file and pass it to youtube-dl. Afterwards, the scriptblocks
	responsible for each variable run to generate the new variable values to 
	be used for the next run.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the items
		to run.
	
.OUTPUTS
	None
	
.NOTES
	This cmdlet is aliased by default to 'iydl'.
	
.LINK
	New-YoutubeDlItem
	Get-YoutubeDlItem
	Set-YoutubeDlItem
	Remove-YoutubeDlItem
	about_ytdlWrapper
	
#>
function Invoke-YoutubeDl
{
	[Alias("iydl")]
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Template")]
		[switch]
		$Template,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job")]
		[switch]
		$Job,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Config")]
		[Alias("ConfigurationFilePath")]
		[string]
		$Path,
		
		# TODO: Tab completion.
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Template")]
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Job", ValueFromPipelineByPropertyName = $true)]
		[Alias("Name")]
		[string[]]
		$Names
		
	)
	
	dynamicparam
	{
		# Only run the input detection logic if a template is given, and only
		# one template is given, and the template exists, and the template
		# has a valid configuration file path.
		if (-not $Template) { return }
		if ($null -eq $Names) { return }
		$name = $Names[0]
		if ([system.string]::IsNullOrWhiteSpace($name)) { return }
		$templateList = Read-Templates
		$templateObject = $templateList | Where-Object { $_.Name -eq $name }
		if ($null -eq $templateObject) { return }
		if ($templateObject.GetState() -eq "InvalidPath") { return }
		
		# Retrieve all instances of input definitions in the config file.
		$inputNames = $templateObject.GetInputs()
		
		# Define the dynamic parameter dictionary to hold new parameters.
		$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
		# Now that a list of all input definitions is found, create a
		# dynamic parameter for each one.
		foreach ($input in $inputNames)
		{
			# Set up the necessary objects for a parameter.
			$paramAttribute = New-Object System.Management.Automation.ParameterAttribute
			$paramAttribute.Mandatory = $true
			$attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
			$attributeCollection.Add($paramAttribute)				
			$param = New-Object System.Management.Automation.RuntimeDefinedParameter($input, [String], $attributeCollection)
			
			$parameterDictionary.Add($input, $param)
		}
		
		return $parameterDictionary
	}
	
	process
	{
		if ($PSCmdlet.ParameterSetName -eq "Config")
		{
			# Validate that the path is valid.
			if (-not (Test-Path -Path $Path))
			{
				Write-Error "The configuration file path: '$Path' is invalid!"
				return
			}
			
			if ($PSCmdlet.ShouldProcess("Starting youtube-dl.exe.", "Are you sure you want to start youtube-dl.exe?", "Start Process Prompt"))
			{
				Invoke-Process -Path "$script:Folder\$hash.conf"
			}
		}
		elseif ($PSCmdlet.ParameterSetName -eq "Template")
		{
			# Only accept one template at a time.
			if ($Names.Length -gt 1)
			{
				Write-Error "Cannot specify more than one template per invocation of this cmdlet!"
				return
			}
			
			$name = $Names[0]
			
			# Retrieve the template and check that it exists.
			$templateList = Read-Templates
			$templateObject = $templateList | Where-Object { $_.Name -eq $name }
			Write-Verbose "Validating parameters and the configuration file."
			if ($null -eq $templateObject)
			{
				Write-Error "There is no template named: '$name'."
				return
			}
			
			# Validate that the template can be used.
			switch ($templateObject.GetState())
			{
				"InvalidPath"
				{
					Write-Error "The template: '$name' has a configuration file path: '$($templateObject.Path)' which is invalid!"
					return
				}
				"NoInputs"
				{
					Write-Error "The template: '$name' has a configuration file with no input definitions!`nFor help regarding the configuration file, see the `"#TODO`" section in the help at: `'about_ytdlWrapper_templates`'."
					return
				}
			}
			
			# Get the necessary inputs for this template, and assign each the 
			# user provided value. Quit if the user has failed to give in a 
			# certain value.
			$inputNames = $templateObject.GetInputs()
			$inputs = New-Object -TypeName hashtable
			foreach ($input in $inputNames)
			{
				if ($PSBoundParameters.ContainsKey($input))
				{
					$inputs[$input] = $PSBoundParameters[$input]
				}
				else
				{
					Write-Error "The template: '$name' requires the input: '$input' which has been not provided!"
					return
				}
			}
			
			$completedTemplateContent = $templateObject.CompleteTemplate($inputs)
			
			# Write modified config file (with substituted user inputs) to a
			# temporary file. This is done because it is easier to use the 
			# --config-location flag for youtube-dl than to edit the whole
			# string to use proper escape sequences.
			$stream = [System.IO.MemoryStream]::new([byte[]][char[]]$completedTemplateContent)
			$hash = (Get-FileHash -InputStream $stream -Algorithm SHA256).hash
			if ($PSCmdlet.ShouldProcess("Creating temporary configuration file at: '$script:Folder\$hash.conf'.", "Are you sure you want to create a temporary configuration file at: '$script:Folder\$hash.conf'?", "Create File Prompt"))
			{
				Out-File -FilePath "$script:Folder\$hash.conf" -Force -InputObject $completedTemplateContent `
					-ErrorAction Stop
			}
			
			if ($PSCmdlet.ShouldProcess("Starting youtube-dl.exe.", "Are you sure you want to start youtube-dl.exe?", "Start Process Prompt"))
			{
				Invoke-Process -Path "$script:Folder\$hash.conf"
			}
			
			# Clean up the temporary file.
			if ($PSCmdlet.ShouldProcess("Clean-up temporary configuration file from: '$script:Folder\$hash.conf'.", "Are you sure you want to clean-up the temporary configuration file from: '$script:Folder\$hash.conf'?", "Delete File Prompt"))
			{
				Remove-Item -Path "$script:Folder\$hash.conf" -Force
			}
		}
		elseif ($PSCmdlet.ParameterSetName -eq "Job")
		{
			foreach ($name in $Names)
			{
				# Retrieve the template and check that it exists.
				$jobList = Read-Jobs
				$jobObject = $jobList | Where-Object { $_.Name -eq $name }
				Write-Verbose "Validating parameters and the configuration file."
				if ($null -eq $jobObject)
				{
					Write-Error "There is no job named: '$name'."
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
					"MismatchedVariables"
					{
						Write-Error "The job: '$name' has a mismatch between the variables stored in the database and the variable definitions within the configuration file!`nRun the `Set-YoutubeDlItem` cmdlet with the '-Update' switch to fix the issue."
						return
					}
					"UninitialisedVariables"
					{
						Write-Error "The job: '$name' has uninitialised variables and cannot run!`nRun the `Set-YoutubeDlItem` cmdlet with the '-Update' switch to fix the issue."
						return
					}
				}
				
				$completedJobContent = $jobObject.CompleteJob()
				
				# Write modified config file (with substituted variable values) to a
				# temporary file. This is done because it is easier to use the 
				# --config-location flag for youtube-dl than to edit the whole
				# string to use proper escape sequences.
				$stream = [System.IO.MemoryStream]::new([byte[]][char[]]$completedJobContent)
				$hash = (Get-FileHash -InputStream $stream -Algorithm SHA256).hash
				if ($PSCmdlet.ShouldProcess("Creating temporary configuration file at: '$script:Folder\$hash.conf'.", "Are you sure you want to create a temporary configuration file at: '$script:Folder\$hash.conf'?", "Create File Prompt"))
				{
					Out-File -FilePath "$script:Folder\$hash.conf" -Force -InputObject $completedJobContent `
						-ErrorAction Stop
				}
				
				if ($PSCmdlet.ShouldProcess("Starting youtube-dl.exe.", "Are you sure you want to start youtube-dl.exe?", "Start Process Prompt"))
				{
					Invoke-Process -Path "$script:Folder\$hash.conf"
				}
				
				# Clean up the temporary file.
				if ($PSCmdlet.ShouldProcess("Clean-up temporary configuration file from: '$script:Folder\$hash.conf'.", "Are you sure you want to clean-up the temporary configuration file from: '$script:Folder\$hash.conf'?", "Delete File Prompt"))
				{
					Remove-Item -Path "$script:Folder\$hash.conf" -Force
				}
				
				# If a scriptblock didn't return a value, warn the user.
				Write-Verbose "Updating variable values for the job."
				$return = $jobObject.ExecuteScriptblocks()
				if (-not [System.String]::IsNullOrWhiteSpace($return))
				{
					Write-Error "The job: '$name' has a scriptblock definition named: '$return' which did not return a value!`nFor help regarding the configuration file, see the `"#TODO`" section in the help at: `'about_ytdlWrapper_jobs`'."
					return
				}
				
				if ($PSCmdlet.ShouldProcess("Updating database at '$script:JobData' with the changes.", "Are you sure you want to update the database at '$script:JobData' with the changes?", "Save File Prompt"))
				{
					Export-Clixml -Path $script:JobData -InputObject $jobList -WhatIf:$false -Confirm:$false `
						| Out-Null
				}
			}
		}
	}
}