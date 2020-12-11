<#
.SYNOPSIS
	Deletes a specified youtube-dl item.
	
.DESCRIPTION
	The `New-YoutubeDlItem` cmdlet deletes one or more youtube-dl template or
	job definitions.
	
.PARAMETER DeleteTemplate
	Indicates that this cmdlet will be deleting a youtube-dl template.
	
.PARAMETER DeleteJob
	Indicates that this cmdlet will be deleting a youtube-dl job.
	
.PARAMETER Names
	Specifies the name(s) of the items to delete.
	
	Once you specify the '-DeleteTemplate/Job' option, this parameter will
	autocomplete to existing names for the respective item type.
	
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
	PS C:\> Remove-YoutubeDlItem -DeleteTemplate -Name "music"
	
	Deletes a youtube-dl template named "music".
	
.EXAMPLE
	PS C:\> Remove-YoutubeDlItem -DeleteJob -Name "archive"
	
	Deletes a youtube-dl job named "archive".
	
#>
function Remove-YoutubeDlItem
{
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Template")]
		[Alias("Template")]
		[switch]
		$DeleteTemplate,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "Job")]
		[Alias("Job")]
		[switch]
		$DeleteJob,
		
		# Tab completion
		[Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("Name")]
		[string[]]
		$Names
		
	)
	
	process
	{
		foreach ($name in $Names)
		{
			if ($DeleteTemplate)
			{
				$templateList = Read-Templates
				
				# Find the template by name.
				$template = $templateList | Where-Object { $_.Name -eq $name }
				if ($null -eq $template)
				{
					Write-Error "There is no template called: '$name'."
					continue
				}
				
				# Save the modified database.
				$templateList.Remove($template) | Out-Null
				if ($PSCmdlet.ShouldProcess("$script:TemplateData", "Overwrite database with modified contents"))
				{
					Export-Clixml -Path $script:TemplateData -InputObject $templateList -WhatIf:$false `
						-Confirm:$false | Out-Null
				}
			}
			elseif ($DeleteJob)
			{
				$jobList = Read-Jobs
				
				# Find the job by name.
				$job = $jobList | Where-Object { $_.Name -eq $name }
				if ($null -eq $job)
				{
					Write-Error "There is no job called: '$name'."
					continue
				}
				
				# Save the modified database.
				$jobList.Remove($job) | Out-Null
				if ($PSCmdlet.ShouldProcess("$script:JobData", "Overwrite database with modified contents"))
				{
					Export-Clixml -Path $script:JobData -InputObject $jobList -WhatIf:$false `
						-Confirm:$false | Out-Null
				}
			}
		}
	}
}