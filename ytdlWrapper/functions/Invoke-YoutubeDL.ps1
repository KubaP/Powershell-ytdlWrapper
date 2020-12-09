<#
.SYNOPSIS
	Invoke youtube-dl
	
.DESCRIPTION
	Invoke the youtube-dl process, specifying either an already defined job or a configuration file.
	
.PARAMETER Path
	The path of a youtube-dl configuration file to use.
	
.PARAMETER JobName
	The name of the job to run.
	
.EXAMPLE
	PS C:\> Invoke-YoutubeDL -Path "~/conf.txt" -Url "//some/url/"
	
	Invokes youtube-dl using the specified configuration path, with has an input definition "Url" that is 
	passed in as a parameter.
	
.EXAMPLE
	PS C:\> Invoke-YoutubeDL -JobName "test"
	
	Invokes youtube-dl using the configuration path specified by the job, and any variables which may be 
	defined for this job.
	
.INPUTS
	None
	
.OUTPUTS
	None
	
.NOTES
	
	
#>
function Invoke-YoutubeDL {
	
	[CmdletBinding()]
	param (
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Config")]
		[Alias("ConfigPath")]
		[string]
		$Path,
		
		# Tab completion
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job")]
		[Alias("JobName", "Name")]
		[string]
		$Job
		
	)
	
	dynamicparam {
		# Only run the variable detection logic if a file is given in and
		# exists, i.e. if invoking youtube-dl against a config file.
		if ($null -ne $Path -and (Test-Path -Path $Path)) {
			# Retrieve all instances of input definitions in the config file.
			$definitionList = Read-ConfigDefinitions -Path $Path -InputDefinitions
			
			# Define the dynamic parameter dictionary to hold new parameters.
			$parameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
			# Now that a list of all input definitions is found, create a
			# dynamic parameter for each one.
			foreach ($definition in $definitionList) {
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
	
	process {
		if ($PSCmdlet.ParameterSetName -eq "Config") {
			# Validate the config file exists.
			if ((Test-Path -Path $Path) -eq $false) {
				Write-Error "The config path: '$Path' points to an invalid/non-existent location!"
				return
			}
			
			$configFileContent = Get-Content -Path $Path -Raw
			# Retrieve all input definitions within the config file.
			$definitionList = Read-ConfigDefinitions -Path $Path -InputDefinitions
			
			# Go through all input definitions and substitute the user provided
			# value, before writing the modified content to a temporary config
			# file.
			foreach ($definition in $definitionList) {
				if ($PSBoundParameters.ContainsKey($definition)) {
					# Replace the occurence of the input definition with the
					# user provided value.
					$configFileContent = $configFileContent -replace "i@{$definition}", $PSBoundParameters[$definition]
				}
				else {
					# There is a input definition which has not been provided a 
					# value by the user, so error.
					Write-Error "The following user input: '$definition' was not provided!"
					return
				}
			}
			
			# Write modified config file (with substituted user inputs) to a
			# temporary file. This is done because it is easier to use the 
			# --config-location flag for youtube-dl than to edit the whole
			# string to use proper escape sequences.
			$stream = [System.IO.MemoryStream]::new([byte[]][char[]]$configFileContent)
			$hash = (Get-FileHash -InputStream $stream -Algorithm SHA256).hash
			Out-File -FilePath "$script:Folder\$hash.conf" -Force -InputObject $configFileContent
		}
		elseif ($PSCmdlet.ParameterSetName -eq "Job") {
			
			# Retrieve the job and heck that it exists
			$jobList = Get-Jobs -Path "$script:DataPath\database.xml"
			$job = $jobList | Where-Object { $_.Name -eq $JobName }
			
			if ($null -eq $job) {
				
				Write-Message -Message "There is no job called: $JobName" -DisplayWarning
				return
				
			}
			
			# Read in the contents of the job config file
			$configFileContent = Get-Content -Path $job.ConfigPath -Raw
			
			# Retrieve all instances of variable definitions in the config file
			$definitionList = Read-ConfigDefinitions -Path $job.ConfigPath -VariableDefinitions
			
			# Check that the job variables match the configuration file definitions, otherwise there would be errors
			$jobDefinitionList = $job.Variables.Keys
			$difference1 = $jobDefinitionList | Where-Object { $definitionList -notcontains $_ }
			$difference2 = $definitionList | Where-Object { $jobDefinitionList -notcontains $_ }
			if (($null -ne $difference1) -or ($null -ne $difference2)) {
				
				Write-Message -Message "The job variables in the database do not match the variable definitions in the configuration file.
										`rRun Set-YoutubeDLJob with the -Update switch to fix the issue. See docs for help." -DisplayWarning
				return
				
			}
			
			foreach ($definition in $definitionList) {
				
				# Replace the occurence of the variable definition with the variable value from the database
				$configFileContent = $configFileContent -replace "v@{$definition}{start{(?s)(.*?)}end}", $job.Variables[$definition]
				
			}
			
			# Retrieve all instances of variable scriptblocks in the config file
			$scriptblockDefinitionList = Read-ConfigDefinitions -Path $job.ConfigPath -VariableScriptblocks
			
			# Create a table linking each scriptblock to its respective definition name
			[hashtable]$scriptblockList = [ordered]@{}	
			for ($i = 0; $i -lt $definitionList.Count; $i++) {
				
				$scriptblockList.Add($definitionList[$i], [scriptblock]::Create($scriptblockDefinitionList[$i]))
				
			}
			
			# Write modified config file (with user inputs) to a temp file
			# It is easier to read in the config file than edit the existing string to work properly, by surrounding stuff in "" quotes etc
			Out-File -FilePath "$script:DataPath\temp.conf" -Force -InputObject $configFileContent
			
		}
		
		# Define youtube-dl process information.
		$processStartupInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
			FileName = "youtube-dl"
			Arguments = "--config-location `"$script:Folder\$hash.conf`""
			UseShellExecute = $false
		}
		
		# Start and wait for youtube-dl to finish.
		$process = New-Object System.Diagnostics.Process
		$process.StartInfo = $processStartupInfo
		$process.Start()
		$process.WaitForExit()
		$process.Dispose()
		
		# Delete the temp config file since its no longer needed
		Remove-Item -Path "$script:Folder\$hash.conf" -Force
		
		# Execute any scriptblocks for variables
		if ($PSCmdlet.ParameterSetName -eq "Job") {
			
			# Run every scriptblock, and store the result back into the databasee
			foreach ($key in $scriptblockList.Keys) {
				
				$returnResult = Invoke-Command -ScriptBlock $scriptblockList[$key]
				
				if ($null -eq $returnResult) {
					
					Write-Message -Message "The scriptblock for the $key variable definition didn't return a value. It must return a value." -DisplayError
					return
					
				}
				
				$job.Variables[$key] = $returnResult
				
			}
			
			# If the job has a scriptblock, run it
			if ($null -ne $job.Scriptblock) {
				
				Invoke-Command -ScriptBlock $job.Scriptblock -ArgumentList $job
				
			}
			
			# Save the modified job (if any scriptblocks ran) to the database file
			Export-Clixml -Path "$script:DataPath\database.xml" -InputObject $jobList | Out-Null
			
		}
	}
}