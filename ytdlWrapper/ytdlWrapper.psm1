# Create some global variables
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile -Path "$($script:ModuleRoot)\ytdlWrapper.psd1").ModuleVersion

$script:DataPath = "$env:APPDATA\Powershell\ytdlWrapper"

if ((Test-Path -Path $script:DataPath) -eq $false) {
	
	# Create the module data storage folders if they don't exist
	New-Item -ItemType Directory -Path "$env:APPDATA" -Name "Powershell" -ErrorAction SilentlyContinue
	New-Item -ItemType Directory -Path "$env:APPDATA\Powershell" -Name "ytdlWrapper"
	
}

if ($null -eq (Get-Command "youtube-dl.exe" -ErrorAction SilentlyContinue)) {
	
	# Warn the user that youtube-dl.exe cannot be found since without the binary in PATH, the module won't function correctly.
	Write-Message -Message "Could not find youtube-dl.exe in the PATH." -DisplayWarning
	
}

# Detect whether at some level dotsourcing was enforced
$script:doDotSource = $global:ModuleDebugDotSource
$script:doDotSource = $true #! Needed to make code coverage tests work
# Detect whether at some level loading individual module files, rather than the compiled module was enforced
$importIndividualFiles = $global:ModuleDebugIndividualFiles

# Resolve-Path function which deals with non-existent paths
function Resolve-Path_i {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string]
		$Path # Path to resolve
	)
	
	# Run the command silently
	$resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
	
	# Variable will be null if $Path doesn't exist
	# In that case set it to an empty string
	if ($null -eq $resolvedPath) {
		$resolvedPath = ""
	}
	
	$resolvedPath
}

# If script detects its running from original dev environment, import individually since module won't be compiled
if (Test-Path (Resolve-Path_i -Path "$($script:ModuleRoot)\..\.git")) { $importIndividualFiles = $true }
if ("<was not compiled>" -eq '<was not compiled>') { $importIndividualFiles = $true }

# Imports a module file, either through dot-sourcing or through invoking the script
function Import-ModuleFile {
	<#
	.SYNOPSIS
		Loads files into the module on module import.
	
	.DESCRIPTION
		This helper function is used during module initialization.
		It should always be dotsourced itself, in order to proper function.
		
		This provides a central location to react to files being imported, if later desired
	
	.PARAMETER Path
		The path to the file to load
	
	.EXAMPLE
		PS C:\> . Import-ModuleFile -File $function.FullName
		
		Imports the file stored in $function according to import policy
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Path # Path of module file
	)
	
	# Get the resolved path to avoid any cross-OS issues
	$resolvedPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($Path).ProviderPath
	if ($doDotSource) {
		
		# Load the script through dot-sourcing
		. $resolvedPath
		
	}else {
		
		# Load the script through different method (unknown atm)
		$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($resolvedPath))), $null, $null) 
		
	}
}

# Load individual files if not compiled
if ($importIndividualFiles) {
	
	# Execute Preimport actions
	. Import-ModuleFile -Path "$ModuleRoot\internal\scripts\preimport.ps1"
	
	# Import all internal functions
	foreach ($function in (Get-ChildItem "$ModuleRoot\internal\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
						
		. Import-ModuleFile -Path $function.FullName
		
	}
	
	# Import all public functions
	foreach ($function in (Get-ChildItem "$ModuleRoot\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {	
			
		. Import-ModuleFile -Path $function.FullName
		
	}
	
	# Execute Postimport actions
	. Import-ModuleFile -Path "$ModuleRoot\internal\scripts\postimport.ps1"
	
	# End execution here, do not load compiled code below
	return
}

#region Load compiled code
"<compile code into here>"
#endregion Load compiled code