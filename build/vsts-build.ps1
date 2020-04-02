param (
	# Key for publishing to psgallery
	$ApiKey,
	
	# The root folder for the whole project, containing the git files, build files, module files etc
	# If running locally, specify it to the project root folder
	$WorkingDirectory,
	
	# Repository to publish to
	$Repository = 'PSGallery',
	
	# Publish to test PSGallery instead
	# WARNING: This requires PowershellGet v2.2.2 for some reason. With v2.2.3 the command hangs
	[switch]
	$TestRepo,
	
	# Build but don't publish
	[switch]
	$SkipPublish,
	
	# Build but don't create artifacts
	[switch]
	$SkipArtifact
	
)

#=======================
# Handle Working Directory paths within Azure pipelines
if (-not $WorkingDirectory) {
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS) {
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else { $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY }
}
#=======================
# Import modules
Import-Module "PowershellGet" -RequiredVersion "2.2.2" -Verbose
Get-Module -Verbose

#=======================
# Prepare publish folder
Write-Host "Creating and populating publishing directory"
Remove-Item -Path "$WorkingDirectory\publish" -Force -Recurse -ErrorAction SilentlyContinue
$publishDir = New-Item -Path $WorkingDirectory -Name "publish" -ItemType Directory -Force

# Copy the module files from the git repo to the publish folder
New-Item -Path $publishDir.FullName -Name "<MODULENAME>" -ItemType Directory -Force | Out-Null
Copy-Item -Path "$($WorkingDirectory)\<MODULENAME>\*" -Destination "$($publishDir.FullName)\<MODULENAME>\" -Recurse -Force -Exclude "*tests*"

#=======================
# Gather text data from scripts to compile
$text = @()
$processed = @()

# Gather stuff to run before
foreach ($line in (Get-Content "$($PSScriptRoot)\filesBefore.txt" | Where-Object { $_ -notlike "#*" })) {
	
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	# Get the full file paths within the publish directory
	$basePath = Join-Path "$($publishDir.FullName)\<MODULENAME>" $line
	
	# Get each file specified by filesBefore.txt
	foreach ($entry in (Resolve-Path -Path $basePath)) {
		
		# Get the file 
		$item = Get-Item $entry
		
		if ($item.PSIsContainer) { continue }
		if ($item.FullName -in $processed) { continue }
		
		# Add the text content and mark as processed
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
		
	}
	
}

# Gather commands of all functions and add text content
Get-ChildItem -Path "$($publishDir.FullName)\<MODULENAME>\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	
	$text += [System.IO.File]::ReadAllText($_.FullName)
	
}

Get-ChildItem -Path "$($publishDir.FullName)\<MODULENAME>\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	
	$text += [System.IO.File]::ReadAllText($_.FullName)
	
}

# Gather stuff to run after
foreach ($line in (Get-Content "$($PSScriptRoot)\filesAfter.txt" | Where-Object { $_ -notlike "#*" })) {
	
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	# Get the full file paths within the publish directory
	$basePath = Join-Path "$($publishDir.FullName)\<MODULENAME>" $line
		
	# Get each file specified by filesBefore.txt
	foreach ($entry in (Resolve-Path -Path $basePath)) {
		
		# Get the file 
		$item = Get-Item $entry
		
		if ($item.PSIsContainer) { continue }
		if ($item.FullName -in $processed) { continue }
		
		# Add the text content and mark as processed
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
		
	}
	
}

#=======================
# Update the psm1 file with all the read-in text content
# This is done to reduce load times for the module, if all code is within the single psm1 file
$fileData = Get-Content -Path "$($publishDir.FullName)\<MODULENAME>\<MODULENAME>.psm1" -Raw
# Change the complied flag to true
$fileData = $fileData.Replace('"<was not compiled>"', '"<was compiled>"')
# Paste the text picked up from all files into the psm1 main file, and save
$fileData = $fileData.Replace('"<compile code into here>"', ($text -join "`n`n"))
[System.IO.File]::WriteAllText("$($publishDir.FullName)\<MODULENAME>\<MODULENAME>.psm1", $fileData, [System.Text.Encoding]::UTF8)

#=======================
# Publish
if ($SkipPublish -eq $false) {
	
	if ($TestRepo -eq $true) {
		
		# Publish to TESTING PSGallery
		Write-Host "Publishing the <MODULENAME> module to TEST PSGallery"
		
		# Register testing repository
		Register-PSRepository -Name "test-repo" -SourceLocation "https://www.poshtestgallery.com/api/v2" -PublishLocation "https://www.poshtestgallery.com/api/v2/package" -InstallationPolicy Trusted -Verbose
		Publish-Module -Path "$($publishDir.FullName)\<MODULENAME>" -NuGetApiKey $ApiKey -Force -Repository "test-repo" -Verbose
		
		Write-Host "Published package to test repo. Waiting 30 seconds."
		Start-Sleep -Seconds 30
		
		# Uninstall module if it already exists, to then install the test-module
		Uninstall-Module -Name "<MODULENAME>" -Force -Verbose
		Install-Module -Name "<MODULENAME>" -Repository "test-repo" -Force -AcceptLicense -SkipPublisherCheck -Verbose
		Write-Host "Test <MODULENAME> module installed"
		
		# Remove the testing repository
		Unregister-PSRepository -Name "test-repo" -Verbose
		
	}else {
		
		# Publish to PSGallery
		Write-Host "Publishing the <MODULENAME> module to $($Repository)"
		Publish-Module -Path "$($publishDir.FullName)\<MODULENAME>" -NuGetApiKey $ApiKey -Force -Repository $Repository -Verbose
		
	}

}

#=======================
# Create Artifact
if ($SkipArtifact -eq $false) {
	
	$moduleVersion = (Import-PowerShellDataFile -Path "$PSScriptRoot\..\<MODULENAME>\<MODULENAME>.psd1").ModuleVersion
	# Move the module contents to the desired folder structure
	New-Item -ItemType Directory -Path "$($publishDir.FullName)\<MODULENAME>\" -Name "$moduleVersion" -Force
	Move-Item -Path "$($publishDir.FullName)\<MODULENAME>\*" -Destination "$($publishDir.FullName)\<MODULENAME>\$moduleVersion\" -Exclude "*$moduleVersion*" -Force -Verbose
	
	# Create a packaged zip file
	Compress-Archive -Path "$($publishDir.FullName)\<MODULENAME>" -DestinationPath "$($publishDir.FullName)\<MODULENAME>-v$($moduleVersion).zip" -Verbose
	
	# Write the module number as a azure pipeline variable for publish task
	Write-Host "##vso[task.setvariable variable=version;isOutput=true]$moduleVersion"
}
