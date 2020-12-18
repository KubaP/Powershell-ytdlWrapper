<#
.SYNOPSIS
	Deletes a specified youtube-dl item.
	
.DESCRIPTION
	The `Remove-YoutubeDlItem` cmdlet deletes one or more youtube-dl templates
	or jobs, specified by their name(s).
	
.PARAMETER Template
	Indicates that this cmdlet will be deleting youtube-dl template(s).
	
.PARAMETER Job
	Indicates that this cmdlet will be deleting youtube-dl job(s).
	
.PARAMETER Names
	Specifies the name(s) of the items to delete.
	
	Once you specify a '-Template'/'-Job' switch, this parameter will
	autocomplete to valid names for the respective item type.
	
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
	This cmdlet is aliased by default to 'rydl'.
	
.EXAMPLE
	PS C:\> Remove-YoutubeDlItem -Template -Names "music","video"
	
	Deletes the youtube-dl templates named "music" and "video".
	
.EXAMPLE
	PS C:\> Remove-YoutubeDlItem -Job -Name "archive"
	
	Deletes a youtube-dl job named "archive".
	
.LINK
	New-YoutubeDlItem
	Get-YoutubeDlItem
	Set-YoutubeDlItem
	about_ytdlWrapper
	
#>
function Remove-YoutubeDlItem
{
	[Alias("rydl")]
	
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
		
		# Get the correct database path.
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
			Write-Verbose "Deleting the youtube-dl $(if($Template){`"template`"}else{`"job`"}) object."
			$objectList.Remove($object) | Out-Null
		}
	}
	
	end
	{
		# Save the modified database.
		if ($PSCmdlet.ShouldProcess("Updating database at '$databasePath' with the changes (deletions).", "Are you sure you want to update the database at '$databasePath' with the changes (deletions)?", "Save File Prompt"))
		{
			Export-Clixml -Path $databasePath -InputObject $objectList -Force -WhatIf:$false `
				-Confirm:$false | Out-Null
		}
	}
}