# ytdlWrapper
Powershell-ytdlWrapper is a module aimed at improving ease-of-use and allowing the automation of [youtube-dl](https://github.com/ytdl-org/youtube-dl). The module allows for creating templates which allow reusing a specific youtube-dl configuration to download certain types of content. The module also allows for the creation of jobs which run 100% automatically and can be scheduled to the user's needs.

<br>

<!-- [![Azure DevOps builds](https://img.shields.io/azure-devops/build/KubaP999/3d9148d2-04d0-4835-b7cb-7bf89bdbf11b/7?label=latest%20build&logo=azure-pipelines)](https://dev.azure.com/KubaP999/ProgramManager/_build/latest?definitionId=7&branchName=development)
[![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/KubaP999/ProgramManager/7?logo=codecov&logoColor=white)](https://dev.azure.com/KubaP999/ProgramManager/_build/latest?definitionId=7&branchName=development) -->
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/ProgramManager?logo=powershell&logoColor=white)](https://www.powershellgallery.com/packages/ytdlWrapper)
![PowerShell Gallery Platform](https://img.shields.io/powershellgallery/p/ProgramManager?logo=windows)
[![License](https://img.shields.io/badge/license-GPLv3-blue)](./LICENSE)

## Getting Started
### Installation
In order to get started with the latest build, simply download the module from the [PSGallery](https://www.powershellgallery.com/packages/ytdlWrapper), or install it from powershell by running:
```powershell
PS C:\> Install-Module ytdlWrapper
```
Installing this module does not mean that it is loaded automatically on start-up. Powershell supports loading modules on-the-fly since v3, however the first time you run a command it can be a bit slow to tabcomplete parameters or values. If you would like to load this module on shell start-up, add the following line to `~/Documents/Powershell/Profile.ps1` :
```powershell
Import-Module ytdlWrapper
```

### Requirements
This module requires `powershell 5.1` minimum. Works with `powershell core` as well.

This module works on `windows`. Although there is technically nothing which should stop this from working on linux/macos, I've not tested it on those platforms yet so no guarantees that it will work correctly.

## Usage
To Invoke a youtube-dl process, simply run the command
```powershell
PS C:\> Invoke-YoutubeDL
```
Use the `-ConfigPath` parameter to pass in a complete configuration file or a template file.<br>
Use the `-JobName` parameter to execute a job.

For a general overview of the module, and more in-depth explanations and examples, see `about_ytdlWrapper` by running the `Get-Help` command.

Further feature specific information is available at `about_ytdlWrapper_templates` and `about_ytdlWrapper_jobs`.

### Extra features
#### Tab completion
The functions support advanced tab-completion for values:
- Any `JobName` parameters support tab-completion.
- The `Variable` parameter supports tab-completion once a `JobName` is given in.

#### Custom scriptblock support
When adding a new job, you can register a scriptblock. This scriptblock will execute once the main youtube-dl process is finished downloading a job.

For details, see `about_ytdlWrapper_jobs`.
<!-- 
#### -WhatIf and -Confirm support
All functions in this module support these parameters when appropriate.

Use `-WhatIf` to see what changes a function will do.
Use `-Confirm` to require a prompt for every major change.
 -->
## Build Instructions
### Prerequesites
Install the following:
- Powershell Core 7.0.0
- Pester 4.9.0
- PSScriptAnalyzer 1.18.3

### Clone the git repo
```
git clone https://github.com/KubaP/Powershell-ytdlWrapper.git
```

### Run the build scripts

Run the following commands in this order:
```powershell
& .\build\vsts-prerequisites.ps1
& .\build\vsts-valiate.ps1
& .\build\vsts-build.ps1 -WorkingDirectory .\ -SkipPublish
```
The built module will be located in the `.\publish` folder.

## Support
If there is a bug/issue please file it on the github issue tracker.

## Contributing
Feel free to make pull requests if you have an improvement. Only submit a single feature at a time, and make sure that the code is cleanly formatted, readable, and well commented.

## License 
This project is licensed under the GPLv3 license - see [LICENSE.md](./LICENSE) for details.


## Acknowledgements
Any youtube-dl branding belongs to the respective copyright holders.