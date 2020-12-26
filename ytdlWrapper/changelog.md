# Changelog
## 0.2.1 (2020-12-22)
⚠This version modifies the object/data format. There is an automatic migration method which runs on module import, and migrates data from `v0.2.0`.
 - Update: `[YoutubeDlJob]`: Holds information regarding the last execution of the job; the date-time of the last run and its success state.
 - Update: Format.ps1xml: Shows the new execution state information for jobs where appropriate.
## 0.2.0 (2020-12-21)
⚠For this release, the module has been rewritten from the ground up. Previous stored data will be invalid for this release.
 - New: `New-YoutubeDlItem`: Allows for creating template or job items.
 - New: `Get-YoutubeDlItem`: Allows for retrieving an existing template or job.
 - New: `Set-YoutubeDlItem`: Allows for changing the properties of a template or job. For jobs, it offers the ability to fix any discrepancies between the job and configuration file.
 - New: `Remove-YoutubeDlItem`: Allows for removing a template or job item.
 - New: `Invoke-YoutubeDl`: Allows for invoking youtube-dl, either to run a configuration file as-is, a template, or a job.
 - New: alias: Added the 'nydl', 'gydl', 'sydl', 'rydl', 'iydl' aliases for each respective exported cmdlet.
 - New: about_ytdlWrapper: Explains how the module works in general and outlines the use cases.
 - New: about_ytdlWrapper_jobs: Explains how jobs work and how to set them up in detail.
 - New: about_ytdlWrapper_templates: Explains how templates work and how to set them up in detail.
 - New: help_descriptions: Contains descriptions of all cmdlets along with multiple examples for each and any important notes to know.
 - New: tab_completion: Tab completion functionality for parameters of all cmdlets where appropriate.
 - New: should_process: Support for the *'-WhatIf'* and *'-Confirm'* switches for the `New-`, `Set-`, `Remove-`, and `Invoke-` cmdlets.
 - New: stream_output: Provides error logging, and verbose logging when using the *'-Verbose'* switch.
 - New: `[YoutubeDlTemplate]`: Implementation of template logic as part of a custom object.
 - New: `[YoutubeDlJob]`: Implementation of job logic as part of a custom object.
 - New: Format.ps1xml: Includes basic and fancy formatting styles for both template and job objects.
## 0.1.0 (2020-04-20)
 - New: `Invoke-YoutubeDL`: Allows for the invocation of the youtube-dl binary, specifying a config file or a job.
 - New: `Add-YoutubeDLJob`: Allows creating a new job for persistent data storage in the database.
 - New: `Get-YoutubeDLJob`: Allows retrieving details for a job, returning an object.
 - New: `Set-YoutubeDLJob`: Allows changing properties for a job.
 - New: `Remove-YoutubeDLJob`: Allows deleting a job from the database.
 - New: about_ytdlWrapper: Explains the general module.
 - New: about_ytdlWrapper_templates: Explains how to use templates.
 - New: about_ytdlWrapper_jobs: Explains how to use jobs.
 - New: `[youtube-dl.Job]`: Holds information regarding the job.
