<#
.SYNOPSIS
	Gets the specified youtube-dl item.
	
.DESCRIPTION
	The `Get-Item` cmdlet gets one or more youtube-dl template or job
	definitions specified by their name(s).
	
.PARAMETER Template
	Indicates that this cmdlet will be retrieving a youtube-dl template.
	
.PARAMETER Job
	Indicates that this cmdlet will be retrieving a youtube-dl job.
	
.PARAMETER Names
	Specifies the name(s) of the items to get.
	
	Once you specify the '-Template/Job' option, this parameter will
	autocomplete to valid existing names for the respective item type.
	
.PARAMETER All
	Specifies to get all items of the respective item type.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the items
		to get.
	
.OUTPUTS
	YoutubeDlTemplate
	YoutubeDlJob
	
.NOTES
	This cmdlet is aliased by default to '#TODO'.
	
.EXAMPLE
	PS C:\> Get-YoutubeDlItem -Template -Name "music","video"
	
	Gets the youtube-dl template definitions which are named "music" and 
	"video".
	
.EXAMPLE
	PS C:\> Get-YoutubeDlItem -Job -All
	
	Gets all youtube-dl job definitions.
	
#>
function Get-YoutubeDlItem
{
	
	[CmdletBinding()]
	param
	(
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Template-All")]
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Template-Specific")]
		[switch]
		$Template,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job-All")]
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job-Specific")]
		[switch]
		$Job,
		
		# TODO: Tab completion.
		[Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Template-Specific")]
		[Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Job-Specific")]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Template-All")]
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = "Job-All")]
		[switch]
		$All
		
	)
	
	begin
	{
		# Store the retrieved items, to in one go at the end of execution.
		$outputList = if ($Template)
		{
			New-Object -TypeName System.Collections.Generic.List[YoutubeDlTemplate]
		}
		else
		{
			New-Object -TypeName System.Collections.Generic.List[YoutubeDlJob]
		}
		
		# Read in the correct list of templates or jobs.
		$objectList = if ($Template)
		{
			Read-Templates
		}
		else
		{
			Read-Jobs
		}
	}
	
	process
	{
		if (-not $All)
		{
			# Iterate through all the passed in names.
			foreach ($name in $Names)
			{
				# If the object doesn't exist, warn the user.
				$existingObject = $objectList | Where-Object { $_.Name -eq $name }
				if ($null -eq $existingObject)
				{
					Write-Warning "There is no $(if($Template){`"Template`"}else{`"Job`"}) called: '$name'."
					continue
				}
				
				# Add the object for outputting.
				$outputList.Add($existingObject)
			}
		}
		else
		{
			# Output every object.
			$outputList = $objectList
		}
	}
	
	end
	{
		# By default, this outputs in List formatting.
		$outputList | Sort-Object -Property Name
	}
}