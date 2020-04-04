function Read-Jobs {
	<#
	.SYNOPSIS
		Short description
	.DESCRIPTION
		Long description
	.EXAMPLE
		PS C:\> <example usage>
		Explanation of what the example does
	.INPUTS
		Inputs (if any)
	.OUTPUTS
		Output (if any)
	.NOTES
		General notes
	#>
	
	[CmdletBinding()]
	param (
		
		[Parameter(Mandatory = $true)]
		[string]
		$Path
		
	)
	
	# Ensure that the file actually exists
	if ($null -eq (Test-Path -Path $Path)) {
		
		Write-Message -Message "There is no file located at: $Path" -DisplayError
		return
		
	}
	
	$jobList = [System.Collections.Generic.List[psobject]]@()
	
	# Read the xml data in
	$xmlData = Import-Clixml -Path $Path 
	
	
	foreach ($item in $xmlData
	) {
		
		# Rather than extracting the deserialised objects, which would create a mess of serialised and non-serialised objects
		# Create new identical copies from scratch
		if ($item.PSObject.TypeNames[0] -eq "Deserialized.youtube-dl.Job") {
			
			$job = New-Object -TypeName psobject
			$job.PSObject.TypeNames.Insert(0, "youtube-dl.Job")		
			
			# Copy the properties from the Deserialized object into the new one
			foreach ($property in $item.PSObject.Properties) {
					
				# Copy over the deserialised object properties over to new object
				$job | Add-Member -Type NoteProperty -Name $property.Name -Value $property.Value
				
			}
			
			$jobList.Add($job)
			
		}
		
	}
	
	# Return the list as a List object, rather than as an array (by default)
	Write-Output $jobList -NoEnumerate
	
}