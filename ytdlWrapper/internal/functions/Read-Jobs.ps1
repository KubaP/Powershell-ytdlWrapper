<#
.SYNOPSIS
	Reads all of the defined job objects.
	
.EXAMPLE
	PS C:\> $list = Read-Jobs
	
	Reads all of the job objects into a variable, for later manipulation.
	
.INPUTS
	None
	
.OUTPUTS
	System.Collections.Generic.List[YoutubeDlJob]
	
.NOTES
	
#>
function Read-Jobs
{
	# Create an empty list.
	$jobList = New-Object -TypeName System.Collections.Generic.List[YoutubeDlJob]
	
	# If the file doesn't exist, skip any importing.
	if (Test-Path -Path $script:JobData -ErrorAction SilentlyContinue)
	{
		# Read the xml data in.
		$xmlData = Import-Clixml -Path $script:JobData
		
		# Iterate through all the objects.
		foreach ($item in $xmlData)
		{
			# Rather than extracting the deserialised objects, which would
			# create a mess of serialised and non-serialised objects, create
			# new identical copies from scratch.
			if ($item.pstypenames[0] -eq "Deserialized.YoutubeDlJob")
			{
				$job = [YoutubeDlJob]::new($item.Name, $item.Path, $item._Variables)
				$jobList.Add($job)
			}
		}
	}
	
	# Return the list as a <List> object, rather than as an array,
	# (ps converts by default).
	Write-Output $jobList -NoEnumerate
}
