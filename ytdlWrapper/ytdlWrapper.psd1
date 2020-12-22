﻿@{
	# Script module or binary module file associated with this manifest
	RootModule = 'ytdlWrapper.psm1'
	
	# Version number of this module.
	ModuleVersion = '0.2.1'
	
	# ID used to uniquely identify this module
	GUID = 'adb3211a-7554-4beb-a591-e110130b708f'
	
	# Author of this module
	Author = 'KubaP'
	
	# Company or vendor of this module
	CompanyName = ' '
	
	# Copyright statement for this module
	Copyright = 'Copyright (c) 2020 KubaP'
	
	# Description of the functionality provided by this module
	Description = 'A powershell wrapper for youtube-dl, which allows for advanced automation and template re-use.'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '6.0'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	<#!
	RequiredModules = @(
		@{ ModuleName='name'; ModuleVersion='1.0.0' }
	)#>
	
	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\ytdlWrapper.dll')
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\ytdlWrapper.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @('xml\ytdlWrapper.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport = @(
		"New-YoutubeDlItem",
		"Get-YoutubeDlItem",
		"Set-YoutubeDlItem",
		"Remove-YoutubeDlItem",
		"Invoke-YoutubeDl"
	)
	
	# Cmdlets to export from this module
	CmdletsToExport = ''
	
	# Variables to export from this module
	VariablesToExport = ''
	
	# Aliases to export from this module
	AliasesToExport = ''
	
	# List of all modules packaged with this module
	ModuleList = @()
	
	# List of all files packaged with this module
	FileList = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @("Windows", "MacOS", "Linux", "youtube-dl", "Youtube", "Video", "Download", "Wrapper", "PSEdition_Core")
			
			# A URL to the license for this module.
			LicenseUri = 'https://www.gnu.org/licenses/gpl-3.0.en.html'
			
			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/KubaP/Powershell-ytdlWrapper'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/KubaP/Powershell-ytdlWrapper/blob/master/ytdlWrapper/changelog.md'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}