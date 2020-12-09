function Get-Jobs {
	<#
	.SYNOPSIS
		Get and return a list of jobs
		
	.DESCRIPTION
		Get and return a list of youtube-dl.Job objects from the database file.
		
	.PARAMETER Path
		The path of the database file.
		
	.EXAMPLE
		PS C:\> $jobList = Get-Job -Path "%appdata%/database.xml"
		
		Populates the array/list with all jobs in the specified database.
		
	.INPUTS
		None
		
	.OUTPUTS
		None
		
	.NOTES
		
		
	#>
	
	[CmdletBinding()]
	param (
		
		[Parameter(Mandatory = $true)]
		[string]
		$Path
		
	)
	
	$jobList = [System.Collections.Generic.List[psobject]]@()
	
	# If the file doesn't exist, then the import logic will error accordingly
	if ((Test-Path -Path $Path) -eq $true) {
		
		# Read the xml data in
		$xmlData = Import-Clixml -Path $Path 
		
		foreach ($item in $xmlData) {
			
			# Rather than extracting the deserialised objects, which would create a mess of serialised and non-serialised objects
			# Create new identical copies from scratch
			if ($item.PSObject.TypeNames[0] -eq "Deserialized.youtube-dl.Job") {
				
				$job = New-Object -TypeName psobject
				$job.PSObject.TypeNames.Insert(0, "youtube-dl.Job")		
				
				# Copy the properties from the Deserialized object into the new one
				foreach ($property in $item.PSObject.Properties) {
					
					# Copy over the deserialised object properties over to new object
					if ($property.Name -eq "Scriptblock") {
						
						# In the case of a scriptblock, create it as a proper scriptblock object so that it doesn't
						# have to be converted later on, possibly more than once?
						$job | Add-Member -Type NoteProperty -Name "Scriptblock" -Value ([Scriptblock]::Create($property.Value))
						
					}else {
						
						$job | Add-Member -Type NoteProperty -Name $property.Name -Value $property.Value
						
					}
					
				}
				
				$jobList.Add($job)
				
			}
			
		}
		
	}
	
	# Return the list as a <List> object, rather than as an array (by default)
	Write-Output $jobList -NoEnumerate
	
}