<#
.SYNOPSIS
	Invoke youtube-dl
	
.DESCRIPTION
	Invoke the youtube-dl process, specifying either an already defined job or
	a configuration file.
	
.PARAMETER Path
	The location of a youtube-dl configuration file to use.
	
.PARAMETER Template
	The name of a template to use.
	
.PARAMETER JobName
	The name of the job to run.
	
.EXAMPLE
	PS C:\> Invoke-YoutubeDl -Path ~\template.conf -Url "https:\some\url"
	
	Invokes youtube-dl using the specified configuration path, with has an
	input definition "Url" that is passed in as a parameter.
	
.EXAMPLE
	PS C:\> Invoke-YoutubeDl -JobName "test"
	
	Invokes youtube-dl using the configuration path specified by the job, and
	any variables which may be defined for this job.
	
.INPUTS
	None
	
.OUTPUTS
	None
	
.NOTES
	
#>
function Invoke-YoutubeDl
{
	# TODO: Implement SupportsShouldProcess.
	
	[CmdletBinding()]
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
		# has a valid file path.
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
			
			Invoke-Process -Path $Path
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
			if ($null -eq $templateObject)
			{
				Write-Error "There is no template called: '$name'."
				return
			}
			
			# Validate that the template can be used.
			switch ($templateObject.GetState()) {
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
			Out-File -FilePath "$script:Folder\$hash.conf" -Force -InputObject $completedTemplateContent `
				-ErrorAction Stop
			
			Invoke-Process -Path "$script:Folder\$hash.conf"
			
			# Clean up the temporary file.
			Remove-Item -Path "$script:Folder\$hash.conf" -Force
		}
		elseif ($PSCmdlet.ParameterSetName -eq "Job")
		{
			foreach ($name in $Names)
			{
				# Retrieve the template and check that it exists.
				$jobList = Read-Jobs
				$jobObject = $jobList | Where-Object { $_.Name -eq $name }
				if ($null -eq $jobObject)
				{
					Write-Error "There is no job called: '$name'."
					return
				}
				
				# Validate that the job can be used.
				switch ($jobObject.GetState()) {
					"InvalidPath"
					{
						Write-Error "The job: '$name' has a configuration file path: '$($jobObject.Path)' which is invalid!"
						return
					}
					"MismatchedVariables"
					{
						Write-Error "The job: '$name' has a mismatch between the variables stored in the database and the variable definitions within the configuration file!`nRun the `Set-YoutubeDlItem` cmdlet with the '-Update' switch to fix the issue."
						return
					}
					"HasInputs"
					{
						Write-Error "The job: '$name' has input definitions which a job cannot have!`nFor help regarding the configuration file, see the `"#TODO`" section in the help at: `'about_ytdlWrapper_jobs`'."
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
				Out-File -FilePath "$script:Folder\$hash.conf" -Force -InputObject $completedJobContent
				
				Invoke-Process -Path "$script:Folder\$hash.conf"
				
				# Delete the temp config file since its no longer needed.
				Remove-Item -Path "$script:Folder\$hash.conf" -Force
				
				# If a scriptblock didn't return a value, warn the user.
				$return = $jobObject.ExecuteScriptblocks()
				if (-not [System.String]::IsNullOrWhiteSpace($return))
				{
					Write-Error "The job: '$name' has a scriptblock definition named: '$return' which did not return a value!`nFor help regarding the configuration file, see the `"#TODO`" section in the help at: `'about_ytdlWrapper_jobs`'."
					return
				}
				
				# TODO: should process
				Export-Clixml -Path $script:JobData -InputObject $jobList -WhatIf:$false -Confirm:$false `
					| Out-Null
			}
		}
	}
}