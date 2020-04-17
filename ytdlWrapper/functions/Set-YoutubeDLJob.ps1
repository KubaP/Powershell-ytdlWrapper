function Set-YoutubeDLJob {
	<#
	.SYNOPSIS
		Set a property of a job
		
	.DESCRIPTION
		Set a property of a youtube-dl job definition, such as the config filepath, or a variable value.
		
	.PARAMETER JobName
		The name of the job to configure. Accepts multiple names in an array.
		
	.PARAMETER Variable
		The variable to edit.
		
	.PARAMETER Value
		The new value for the variable.
		
	.PARAMETER ConfigPath
		The new filepath pointing to the configuration file.
		
	.EXAMPLE
		PS C:\> Set-YoutubeDLJob -JobName "test" -Variable "number" -Value "123"
		
		Sets the variable "number" to the new value of "123" for the job named "test".
		
	.EXAMPLE
		PS C:\> Set-YoutubeDLJob -JobName "test" -ConfigPath "~/new-config.txt"
		
		Sets the configuration filepath for the job named "test".
		
	.INPUTS
		System.String[]
		
	.OUTPUTS
		None
		
	.NOTES
		
		
	#>
	
	[CmdletBinding()]
	param (
		
		# Tab completion
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = "Variable")]
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = "Config")]
		[Alias("Job", "Name")]
		[string]
		$JobName,
		
		# Tab completion once jobname is given
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Variable")]
		[string]
		$Variable,
		
		[Parameter(Position = 2, Mandatory = $true, ParameterSetName = "Variable")]
		[string]
		$Value,
		
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Config")]
		[string]
		$ConfigPath
		
	)
	
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
			
		}
		
		# Save the modified database file with the job changes
		Export-Clixml -Path "$script:DataPath\database.xml" -InputObject $jobList | Out-Null
		
	}
	
}