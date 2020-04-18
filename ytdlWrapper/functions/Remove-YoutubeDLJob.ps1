function Remove-YoutubeDLJob {
	<#
	.SYNOPSIS
		Remove a job definition
		
	.DESCRIPTION
		Remove a youtube-dl job definition from the database.
		
	.PARAMETER JobName
		The name of the job to remove. Accepts multiple names in an array.
		
	.EXAMPLE
		PS C:\> Remove-YoutubeDLJob -JobName "test"
		
		Removes a job called "test" from the database.
		
	.EXAMPLE
		PS C:\> "test","test2" | Remove-YoutubeDLJob
		
		Removes the jobs called "test" and "test2" from the database.
		
	.INPUTS
		System.String[]
		
	.OUTPUTS
		None
		
	.NOTES
		
		
	#>
	
	[CmdletBinding()]
	param (
		
		# Tab completion
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline)]
		[Alias("Job")]
		[string[]]
		$JobName
		
	)
	
	process {
		
		foreach ($name in $JobName) {
			
			# Read in the list of job objects
			$jobList = Get-Jobs -Path "$script:DataPath\database.xml"
				
			# Check that the job exists
			$job = $jobList | Where-Object { $_.Name -eq $name }
			if ($null -eq $job) {
				
				Write-Message -Message "There is no job called: $name" -DisplayWarning
				return
				
			}
			
			$jobList.Remove($job)
			
			# Save the modified database file with the job removed changes
			Export-Clixml -Path "$script:DataPath\database.xml" -InputObject $jobList | Out-Null
			
		}
		
	}
	
}