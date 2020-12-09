function Get-YoutubeDLJob {
	<#
	.SYNOPSIS
		Get a job definition
		
	.DESCRIPTION
		Return a youtube-dl job definition object. If ran as a standalone command, it will write the job
		details to the screen.
		
	.PARAMETER Names
		The name of the job to retrieve. Accepts multiple names in an array.
		
	.EXAMPLE
		PS C:\> Get-YoutubeDLJob -Names "test"
		
		Returns the youtube-dl job object for the job named "test".
		
	.EXAMPLE
		PS C:\> "test","test2" | Get-YoutubeDLJob
		
		Returns the youtube-dl job objects for the jobs named "test" and "test2" one after another.
		
	.INPUTS
		System.String[]
		
	.OUTPUTS
		youtube-dl.Job[]
		
	.NOTES
		
		
	#>
	
	[CmdletBinding()]
	param (
		
		# Tab completion
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline)]
		[Alias("Job","Name")]
		[string[]]
		$Names
		
	)
	
	# Process logic since function accepts pipeline input.
	process {
		# First read in the list of job objects.
		$jobList = Get-Jobs -Path "$script:DataPath\database.xml"
		
		# Iterate through all the passed in names.
		foreach ($name in $Names) {
			# If the job doesn't exist, warn the user.
			$job = $jobList | Where-Object { $_.Name -eq $name }
			if ($null -eq $job) {
				Write-Message "There is no job called: '$name'" -DisplayWarning
				continue
			}
			
			# Pipe out the job object.
			Write-Output $job
		}
	}
	
}