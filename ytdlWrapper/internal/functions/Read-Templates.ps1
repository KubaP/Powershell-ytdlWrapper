<#
.SYNOPSIS
	Reads all of the defined template objects.
	
.DESCRIPTION
	Reads all of the defined template objects.
	
.EXAMPLE
	PS C:\> $list = Read-Templates
	
	Reads all of the template objects into a variable, for later manipulation.
	
.INPUTS
	None
	
.OUTPUTS
	System.Collections.Generic.List[YoutubeDlTemplate]
	
.NOTES
	
#>
function Read-Templates
{
	# Create an empty list.
	$templateList = New-Object -TypeName System.Collections.Generic.List[YoutubeDlTemplate]
	
	# If the file doesn't exist, skip any importing.
	if (Test-Path -Path $script:TemplateData -ErrorAction SilentlyContinue)
	{
		# Read the xml data in.
		$xmlData = Import-Clixml -Path $script:TemplateData
		
		# Iterate through all the objects.
		foreach ($item in $xmlData)
		{
			# Rather than extracting the deserialised objects, which would create a mess of serialised and
			# non-serialised objects, create new identical copies from scratch.
			if ($item.pstypenames[0] -eq "Deserialized.YoutubeDlTemplate")
			{
				$template = [YoutubeDlTemplate]::new($item.Name, $item.Path)
				$templateList.Add($template)
			}
		}
	}
	
	# Return the list as a <List> object, rather than as an array, (ps converts by default).
	Write-Output $templateList -NoEnumerate
}
