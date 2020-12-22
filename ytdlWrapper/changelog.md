# Changelog
## 0.2.1 (2020-12-xx)
⚠This version modifies the object/data format. There is an automatic migration method which runs when the module is imported, and migrates data from `v0.2.0`.
 - Update: `[YoutubeDlJob]`: Holds information regarding the last execution of the job; date-time and success state.
 - Update: `format.ps1xml`: Shows the new execution state information for jobs.
## 0.2.0 (2020-12-21)
⚠For this release, the module has been rewritten from the ground up. Previous stored data will be invalid for this release.
 - New: Command `New-YoutubeDlItem`: Allows for the creation of a template or job item.
 - New: Command `Get-YoutubeDlItem`: Allows retrieving a previously-created template or job.
 - New: Command `Set-YoutubeDlItem`: Allows for changing the properties of a template or job. For jobs, it offers the ability to fix any discrepancies between the job and configuration file.
 - New: Command `Remove-YoutubeDlItem`: Allows for the removal of a template or job item.
 - New: Command `Invoke-YoutubeDl`: Allows for invoking youtube-dl, either to run a template or a job.
 - New: `about_ytdlWrapper`: Explains the module in general.
 - New: `about_ytdlWrapper_jobs`: Explains how jobs work and how to set them up.
 - New: `about_ytdlWrapper_templates`: Explains how templates work and how to set them up.
 - New: `format.ps1xml`: Includes basic and fancy formatting styles for both template and job objects.
 - New: `[YoutubeDlTemplate]`: Holds information regarding a template.
 - New: `[YoutubeDlJob]`: Holds information regarding a job.
## 0.1.0 (2020-04-20)
 - New: Command `Invoke-YoutubeDL`: Allows for the invocation of the youtube-dl binary, specifying a config file or a job.
 - New: Command `Add-YoutubeDLJob`: Allows creating a new job for persistent data storage in the database.
 - New: Command `Get-YoutubeDLJob`: Allows retrieving details for a job, returning an object.
 - New: Command `Set-YoutubeDLJob`: Allows changing properties for a job.
 - New: Command `Remove-YoutubeDLJob`: Allows deleting a job from the database.
 - New: `about_ytdlWrapper`: Explains the general module.
 - New: `about_ytdlWrapper_templates`: Explains how to use templates.
 - New: `about_ytdlWrapper_jobs`: Explains how to use jobs.
 - New: `[youtube-dl.Job]`: Holds information regarding the job.
