function Remove-YoutubeDLJob {
	<#
	.SYNOPSIS
		Short description
		
	.DESCRIPTION
		Long description
		
	.EXAMPLE
		PS C:\> <example usage>
		
		Explanation of what the example does
		
	.INPUTS
		None
		
	.OUTPUTS
		None
		
	.NOTES
		General notes
		
	#>
	
	[CmdletBinding()]
	param (
		
		[Parameter(Position = 0, Mandatory = $true)]
		[Alias("Job")]
		[string]
		$JobName
		
	)
	
	# Read in the list of job objects
	$jobList = Get-Jobs -Path "$script:DataPath\database.xml"
		
	# Check that the job exists
	$job = $jobList | Where-Object { $_.Name -eq $JobName }
	if ($null -eq $job) {
		
		Write-Message -Message "There is no job called: $JobName" -DisplayWarning
		return
		
	}
	
	$jobList.Remove($job)
	
	# Save the modified database file with the job removed changes
	Export-Clixml -Path "$script:DataPath\database.xml" -InputObject $jobList | Out-Null
	
}