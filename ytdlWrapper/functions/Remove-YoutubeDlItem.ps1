<#
.SYNOPSIS
	Deletes a specified youtube-dl item.
	
.DESCRIPTION
	The `Remove-YoutubeDlItem` cmdlet deletes one or more youtube-dl template
	or job definitions, specified by their name(s).
	
.PARAMETER Template
	Indicates that this cmdlet will be deleting a youtube-dl template.
	
.PARAMETER Job
	Indicates that this cmdlet will be deleting a youtube-dl job.
	
.PARAMETER Names
	Specifies the name(s) of the items to delete.
	
	Once you specify the '-DeleteTemplate/Job' option, this parameter will
	autocomplete to valid existing names for the respective item type.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the items
		to delete.
	
.OUTPUTS
	None
	
.NOTES
	This cmdlet is aliased by default to '#TODO'.
	
.EXAMPLE
	PS C:\> Remove-YoutubeDlItem -Template -Names "music","video"
	
	Deletes the youtube-dl templates named "music" and "video".
	
.EXAMPLE
	PS C:\> Remove-YoutubeDlItem -Job -Name "archive"
	
	Deletes a youtube-dl job named "archive".
	
#>
function Remove-YoutubeDlItem
{
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Template")]
		[switch]
		$Template,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job")]
		[switch]
		$Job,
		
		# TODO: Tab completion
		[Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("Name")]
		[string[]]
		$Names
		
	)
	
	begin
	{
		# Read in the correct list of templates or jobs.
		$objectList = if ($Template)
		{
			Read-Templates
		}
		else
		{
			Read-Jobs
		}
		
		# Get the correct databaseb path.
		$databasePath = if ($Template)
		{
			$script:TemplateData
		}
		else
		{
			$script:JobData
		}
	}
	
	process
	{
		
		# Iterate through all the passed in names.
		foreach ($name in $Names)
		{
			# If the object doesn't exist, warn the user.
			$object = $objectList | Where-Object { $_.Name -eq $name }
			if ($null -eq $object)
			{
				Write-Error "There is no $(if($Template){`"template`"}else{`"job`"}) named: '$name'."
				continue
			}
			
			# Remove the object from the list.
			$objectList.Remove($object) | Out-Null
		}
	}
	
	end
	{
		# Save the modified database.
		if ($PSCmdlet.ShouldProcess($databasePath, "Overwrite database with modified contents"))
		{
			Export-Clixml -Path $databasePath -InputObject $objectList -WhatIf:$false -Confirm:$false | Out-Null
		}
	}
}