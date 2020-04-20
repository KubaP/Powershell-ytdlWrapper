# Design Document

## Powershell-YoutubeDL

## Features
- Allow the automation of running youtube-dl jobs in the background.
- Allow the use of 'templates' when downloading manually, such as a template for music mp3 downloads.
- Have 'live variables' who's value can be modified by script.
- Allow the execution of scriptblocks during the job:
    - arbitrary scriptblocks before the job is started
    - after the job ends scriptblocks for each 'live variable'
    - arbitrary scriptblocks after the job ends completely
- Have a user interface via commands rather than a wizzard?

## Logic
Interpet and execute actual youtube-dl config files:
- Improves compatibility.
- No need to redo all youtube jobs through module-specific commands.
- Wont break compatibility if newer module features come out.
- No need to migrate complicated xml config structures when features change.

Order of Execution:
- Execute pre-job scriptblock
- Parse in job config, detect live variables
- Replace live variables with values read in from persistent config storage
- Assemble parameter string and pass it to youtube-dl
- Wait for job to finish
- Replace persistent config storage with values determined by variable scriptblocks
- Save persistent storage
- Execute post-job scriptblock

#### For manual jobs where you need to specify some parameters manually
In config file, include live variable which requests user input

## Implementation details
Config example:
```
--autonumber-start s@{
    $string = (Get-ChildItem -Path $ROOT -Sort Latest)[0].Name
    $regex = [regex]::New($string, "(.*)\w([0-9]+)")
    return $regex[0]
}
```
On job execution

1. Find all occurences of `--... s@{...}{}`
2. From database, get the lastest value for `...` key, replace the `s@{...}{}` string with it.
3. Assemble complete paramter string
4. Wait for job to complete
5. Create scriptblock from `{}`
6. Execute scriptblock, store retun value back to database under `...` key

On job creation, specify the initial value for `s@{...}{}` since the scriptblock runs after execution.


### For manual jobs
Config example:
```
-o i@{DownloadPath}
```
On job execution

1. Find all occurences of `--... i@{...}`
2. Create dynamic parameter with name `i@{...}`, accept user input and store
3. Replace `i@{...}` string with parameter value
4. Assemble complete parameter string
4. Wait for job to complete


Match any regex for `-...` or `--...` strings, since config can include both types.


### Wording scheme

*Invoke-YoutubeDL* -> Start a youtube-dl download process
*Register-YoutubeDLJob* -> Register a new resource (job object containing data) for access by another command (Invoke-YoutubeDL)

A *Job* is an object containing information for automation
    It contains a *Path* which points to the *Configuration file* (a youtube-dl config file)
    It contains a *Name* which is used to call/differentiate the job
    It contains a *LastRun* timestamp to help determine when the job was last run
    It contains a *Variable* array which keeps track of the variables for this specific job
        Each *Variable* contains a *Value*


The *Configuration file* contains the following
    A *Variable definition* which contains the whole string and defines the following:
        A *Variable syntax* which is the whole `v@{name}{scriptblock}` string
        A *Variable name* which is the `{name}` part, and labels the variable
        A *Variable scriptblock* which is the `{scriptblock}` part, and contain powershell code to form a scriptblock
    A *Input definition* which contains the whole string and defines the following:
        A *Input syntax* which is the whole `i@{name}` string
        A *Input name* which is the `{name}` part, and labels the input
        


When you first register a job, you provide an *initial Value* for each *Variable* to instantiate it, before any scriptblocks can run.


When you run Invoke-YoutubeDL specifying a *configuration file* (running as a template)
    It requests *user input* for each *input definition* under the *input name*
    
When you run Invoke-YoutubeDL specifying a *job* (automation)
    It finds all *variable definitions* and for each, it gets the *value* of the *variable* from the *database*
    It creates a scriptblock for each *variable scriptblock*




