﻿# Create module-wide variables.
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile -Path "$ModuleRoot\ytdlWrapper.psd1").ModuleVersion
$script:Folder = "$env:APPDATA\Powershell\ytdlWrapper"
$script:TemplateData = "$env:APPDATA\Powershell\ytdlWrapper\template-database.$ModuleVersion.xml"
$script:JobData = "$env:APPDATA\Powershell\ytdlWrapper\job-database.$ModuleVersion.xml"

# For the debug output to be displayed, $DebugPreference must be set
# to 'Continue' within the current session.
Write-Debug "`e[4mMODULE-WIDE VARIABLES`e[0m"
Write-Debug "Module root folder: $ModuleRoot"
Write-Debug "Module version: $ModuleVersion"
Write-Debug "Template Database file: $TemplateData"
Write-Debug "Job Database file: $JobData"
Write-Debug "Data Folder: $Folder"

# Create the module data-storage folder if it doesn't exist.
if (-not (Test-Path -Path "$env:APPDATA\Powershell\ytdlWrapper" -ErrorAction Ignore))
{
	New-Item -ItemType Directory -Path "$env:APPDATA" -Name "Powershell\ytdlWrapper" -Force -ErrorAction Stop -WhatIf:$false -Confirm:$false
}
if (-not (Test-Path -Path "$Folder\Templates" -ErrorAction Ignore))
{
	New-Item -ItemType Directory -Path "$Folder" -Name "Templates" -Force -ErrorAction Stop -WhatIf:$false -Confirm:$false
}
if (-not (Test-Path -Path "$Folder\Jobs" -ErrorAction Ignore))
{
	New-Item -ItemType Directory -Path "$Folder" -Name "Jobs" -Force -ErrorAction Stop -WhatIf:$false -Confirm:$false
}
Write-Debug "Created database folders!"

if ($null -eq (Get-Command youtube-dl.exe -ErrorAction SilentlyContinue))
{
	Write-Error "The 'youtube-dl.exe' binary could not be found! Make sure the %PATH% variable has the location of the binary."
}

# Potentially force this module script to dot-source the files, rather than 
# load them in an alternative method.
$doDotSource = $global:ModuleDebugDotSource
$doDotSource = $true # Needed to make code coverage tests work

function Resolve-Path_i
{
	<#
	.SYNOPSIS
		Resolves a path, gracefully handling a non-existent path.
		
	.DESCRIPTION
		Resolves a path into the full path. If the path is invalid,
		an empty string will be returned instead.
		
	.PARAMETER Path
		The path to resolve.
		
	.EXAMPLE
		PS C:\> Resolve-Path_i -Path "~\Desktop"
		
		Returns 'C:\Users\...\Desktop"

	#>
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string]
		$Path
	)
	
	# Run the command, silencing errors.
	$resolvedPath = Resolve-Path -Path $Path -ErrorAction Ignore
	
	# If NULL, then just return an empty string.
	if ($null -eq $resolvedPath)
	{
		$resolvedPath = ""
	}
	
	Write-Output $resolvedPath
}
function Import-ModuleFile {
	<#
	.SYNOPSIS
		Loads files into the module on module import.
		Only used in the project development environment.
		In built module, compiled code is within this module file.
		
	.DESCRIPTION
		This helper function is used during module initialization.
		It should always be dot-sourced itself, in order to properly function.
		
	.PARAMETER Path
		The path to the file to load.
		
	.EXAMPLE
		PS C:\> . Import-ModuleFile -File $function.FullName
		
		Imports the code stored in the file $function according to import policy.
		
	#>
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Path
	)
	
	# Get the resolved path to avoid any cross-OS issues.
	$resolvedPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($Path).ProviderPath
	
	if ($doDotSource)
	{
		# Load the file through dot-sourcing.
		. $resolvedPath	
		Write-Debug "Dot-sourcing file: $resolvedPath"
	}
	else
	{
		# Load the file through different method (unknown atm?).
		$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($resolvedPath))), $null, $null) 
		Write-Debug "Importing file: $resolvedPath"
	}
}

# ISSUE WITH BUILT MODULE FILE
# ----------------------------
# If this module file contains the compiled code below, as this is a "packaged"
# build, then that code *must* be loaded, and you cannot individually import
# and of the code files, even if they are there.
# 
# 
# If this module file is built, then it contains the class definitions below,
# and on Import-Module, this file is AST analysed and those class definitions 
# are read-in and loaded.
# 
# It's only once a command is run that this module file is executed, and if at
# that point this file starts to individually import the project files, it will
# end up re-defining the classes, and apparently that seems to cause issues 
# later down the line.
# 
# 
# Therefore to prevent this issue, if this module file has been built and it
# contains the compile code below, that code will be used, and nothing else.
# 
# The build script should also not package the individual files, so that the
# *only* possibility is to load the compiled code below and there is no way
# the individual files can be imported, as they don't exist.


# If this module file contains the compiled code, import that, but if it
# doesn't, then import the individual files instead.
$importIndividualFiles = $false
if ("<was not built>" -eq '<was not built>')
{
	$importIndividualFiles = $true
	Write-Debug "Module not built! Importing individual files."
}

Write-Debug "`e[4mIMPORT DECISION`e[0m"
Write-Debug "Dot-sourcing: $doDotSource"
Write-Debug "Importing individual files: $importIndividualFiles"

# If importing code as individual files, perform the importing.
# Otherwise, the compiled code below will be loaded.
if ($importIndividualFiles)
{
	Write-Debug "!IMPORTING INDIVIDUAL FILES!"
	
	# Execute Pre-import actions.
	. Import-ModuleFile -Path "$ModuleRoot\internal\preimport.ps1"
	
	# Import all internal functions.
	foreach ($file in (Get-ChildItem "$ModuleRoot\internal\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore))
	{
		. Import-ModuleFile -Path $file.FullName
	}
	
	# Import all public functions.
	foreach ($file in (Get-ChildItem "$ModuleRoot\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore))
	{	
		. Import-ModuleFile -Path $file.FullName
	}
	
	# Execute Post-import actions.
	. Import-ModuleFile -Path "$ModuleRoot\internal\postimport.ps1"
}
else
{
	Write-Debug "!LOADING COMPILED CODE!"
	
	#region Load compiled code
	"<compile code into here>"
	#endregion Load compiled code
}

# TEMPLATE DATA MIGRATION
# -----------------------
Write-Debug "Checking for template databse migration"
$templateDatabaseVersion = [Regex]::Match((Get-Item -Path "$Folder\template-database.*.xml" -ErrorAction Ignore), ".*?ytdlWrapper\\template-database.(.*).xml").Groups[1].Value
if ($templateDatabaseVersion -eq "0.2.0")
{
	Write-Debug "`e[4mDetected database version 0.2.0!`e[0m"
	Rename-Item -Path "$Folder\template-database.0.2.0.xml" -NewName "template-database.0.2.1.xml" -Force -WhatIf:$false -Confirm:$false | Out-Null
}

# JOB DATA MIGRATION
# ------------------
Write-Debug "Checking for job database migration"
$jobDatabaseVersion = [Regex]::Match((Get-Item -Path "$Folder\job-database.*.xml" -ErrorAction Ignore), ".*?ytdlWrapper\\job-database.(.*).xml").Groups[1].Value
if ($jobDatabaseVersion -eq "0.2.0")
{
	Write-Debug "`e[4mDetected database version 0.2.0!`e[0m"
	$jobList = New-Object -TypeName System.Collections.Generic.List[YoutubeDlJob]
	$xmlData = Import-Clixml -Path "$Folder\job-database.$jobDatabaseVersion.xml"
	foreach ($item in $xmlData)
	{
		if ($item.pstypenames[0] -eq "Deserialized.YoutubeDlJob")
		{
			$job = [YoutubeDlJob]::new($item.Name, $item.Path, $item._Variables, $null, $null)
			$jobList.Add($job)
		}
	}
	
	Export-Clixml -Path "$Folder\job-database.0.2.1.xml" -InputObject $jobList -WhatIf:$false -Confirm:$false | Out-Null
	Remove-Item -Path "$Folder\job-database.$jobDatabaseVersion.xml" -Force -WhatIf:$false -Confirm:$false | Out-Null
}
