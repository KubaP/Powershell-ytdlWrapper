<#
.SYNOPSIS
	Gets the specified youtube-dl item(s).
	
.DESCRIPTION
	The `Get-YoutubeDlItem` cmdlet gets one or more youtube-dl templates or
	jobs, specified by their name(s).
	
.PARAMETER Template
	Indicates that this cmdlet will be retrieving youtube-dl template(s).
	
.PARAMETER Job
	Indicates that this cmdlet will be retrieving youtube-dl job(s).
	
.PARAMETER Names
	Specifies the name(s) of the items to get.
	
 [!]Once you specify the '-Template'/'-Job' switch, this parameter will
	autocomplete to valid names for the respective item type.
	
.PARAMETER All
	Specifies to get all items of the respective item type.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the items
		to get.
	
.OUTPUTS
	YoutubeDlTemplate
	YoutubeDlJob
	
.NOTES
	This cmdlet is aliased by default to 'gydl'.
	
.EXAMPLE
	PS C:\> Get-YoutubeDlItem -Template -Names "music","video"
	
	Gets the youtube-dl template definitions which are named "music" and 
	"video", and pipes them out to the screen, by default formatted in a list.
	
.EXAMPLE
	PS C:\> Get-YoutubeDlItem -Job -All
	
	Gets all youtube-dl job definitions, and pipes them out to the screen,
	by default formatted in a list.
	
.EXAMPLE
	PS C:\> Get-YoutubeDlItem -Job "music" | Invoke-YoutubeDl -Job
	
	Gets the youtube-dl job named "music", and then pipes it to the 
	`Invoke-YoutubeDl` cmdlet which invokes youtube-dl and run the job
	automatically.
	
.LINK
	New-YoutubeDlItem
	Set-YoutubeDlItem
	Remove-YoutubeDlItem
	Invoke-YoutubeDl
	about_ytdlWrapper
	
#>
function Get-YoutubeDlItem
{
	[Alias("gydl")]
	
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
		
		[Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Template-Specific")]
		[Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Job-Specific")]
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
		elseif ($Job)
		{
			New-Object -TypeName System.Collections.Generic.List[YoutubeDlJob]
		}
		
		# Read in the correct list of templates or jobs.
		$objectList = if ($Template)
		{
			Read-Templates
		}
		elseif ($Job)
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
					Write-Warning "There is no $(if($Template){`"template`"}else{`"job`"}) named: '$name'."
					continue
				}
				
				# Add the object for outputting.
				$outputList.Add($existingObject) | Out-Null
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