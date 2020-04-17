function Get-YoutubeDLJob {
	<#
	.SYNOPSIS
		Get a job definition
		
	.DESCRIPTION
		Return a youtube-dl job definition object. If run as a standalone command, it will write the job
		details to the screen.
		
	.PARAMETER JobName
		The name of the job to retrieve. Accepts multiple names as an array.
		
	.EXAMPLE
		PS C:\> Get-YoutubeDLJob -JobName "test"
		
		Returns the youtube-dl job object for the job named "test".
		
	.EXAMPLE
		PS C:\> "test","test2" | Get-YoutubeDLJob
		
		Returns the youtube-dl job objects for the jobs "test" and "test2" one after another.
		
	.INPUTS
		System.String[]
		
	.OUTPUTS
		youtube-dl.Job[]
		
	.NOTES
		
		
	#>
	
	[CmdletBinding()]
	param (
		
		# Tab completion assigned
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline)]
		[Alias("Job","Name")]
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
			
			Write-Output $job
			
		}
		
	}
	
}