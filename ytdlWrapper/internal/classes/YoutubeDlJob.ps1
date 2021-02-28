enum JobState
{
	Valid
	InvalidPath
	MismatchedVariables
	UninitialisedVariables
	HasInputs
}

class YoutubeDlJob
{
	[string]$Name
	[string]$Path
	[hashtable]$Variables
	[nullable[datetime]]$LastExecutionTime
	[nullable[boolean]]$LastExecutionSuccess
	
	# Constructor.
	YoutubeDlJob ([string]$name, [string]$path, [hashtable]$variables, [nullable[datetime]]$lastExecutionTime, 
		[nullable[boolean]]$lastExecutionSuccess)
	{
		$this.Name = $name
		$this.Path = $path
		$this.Variables = $variables
		$this.LastExecutionTime = $lastExecutionTime
		$this.LastExecutionSuccess = $lastExecutionSuccess
	}
		
	[JobState] GetState()
	{
		# Check through all the invalid states for a job.
		if ($this.HasInvalidPath())
		{
			return [JobState]::InvalidPath
		}
		if ($this.HasInputs())
		{
			return [JobState]::HasInputs
		}
		if ($this.HasMismatchedVariables())
		{
			return [JobState]::MismatchedVariables
		}
		if ($this.HasUninitialisedVariables())
		{
			return [JobState]::UninitialisedVariables
		}
		return [JobState]::Valid
	}
	
	[boolean] HasInvalidPath()
	{
		return [youtubeDlJob]::HasInvalidPath($this.Path)
	}
	static [boolean] HasInvalidPath([string]$path)
	{
		# Check whether the file path is valid.
		if (Test-Path -Path $path)
		{
			return $false
		}
		return $true
	}
	
	[boolean] HasInputs()
	{
		return [YoutubeDlJob]::HasInputs($this.Path)
	}
	static [boolean] HasInputs([string]$path)
	{
		# Check whether there are input definitions.
		if ((Read-ConfigDefinitions -Path $path -InputDefinitions).Count -eq 0)
		{
			return $false
		}
		return $true
	}
	
	[boolean] HasMismatchedVariables()
	{
		$configVariables =  Read-ConfigDefinitions -Path $this.Path -VariableDefinitions
		if (-not($configVariables.Count -eq 0))
		{
			$differenceA = $configVariables | Where-Object { $this.Variables.Keys -notcontains $_ }
			$differenceB = $this.Variables.Keys | Where-Object { $configVariables -notcontains $_ }
			if (($null -ne $differenceA) -or ($null -ne $differenceB))
			{
				return $true
			}
		}
		return $false
	}
	
	[boolean] HasUninitialisedVariables()
	{
		# Check that each variable has a value, i.e. is not uninitialised.
		foreach ($value in $this.Variables.Values)
		{
			if (($null -eq $value) -or [system.string]::IsNullOrWhiteSpace($value))
			{
				return $true
			}
		}
		return $false
	}
	
	
	[System.Collections.Generic.List[string]] GetVariables()
	{
		# Get the definitions within the file.
		return Read-ConfigDefinitions -Path $this.Path -VariableDefinitions
	}
	
	[System.Collections.Generic.List[string]] GetMissingVariables()
	{
		# Get the variables which are missing in the object but present in  the configuration file.
		$configVariables =  Read-ConfigDefinitions -Path $this.Path -VariableDefinitions
		return $configVariables | Where-Object { $this.Variables.Keys -notcontains $_ }
	}
	
	[System.Collections.Generic.List[string]] GetUnnecessaryVariables()
	{
		# Get the variables which are present in the object but missing in the configuration file.
		$configVariables =  Read-ConfigDefinitions -Path $this.Path -VariableDefinitions
		return $this.Variables.Keys | Where-Object { $configVariables -notcontains $_ }
	}
	
	[System.Collections.Generic.List[string]] GetNullVariables()
	{
		# Get any variable names defined in this object which don't have a value.
		$returnList = New-Object -TypeName System.Collections.Generic.List[string]
		foreach ($key in $this.Variables.Keys)
		{
			if (($null -eq $this.Variables[$key]) -or [system.string]::IsNullOrWhiteSpace($this.Variables[$key]))
			{
				$returnList.Add($key)
			}
		}
		
		return $returnList
	}
	
	[hashtable] GetScriptblocks()
	{
		# Get the scriptblock hashtable.
		return Read-ConfigDefinitions -Path $this.Path -VariableScriptblocks
	}
	
	[string] GetCompletedConfigFile()
	{
		# Go through all variable definitions and substitute the stored variable value, 
		# before returning the modified file content string.
		$configFilestream = Get-Content -Path $this.Path -Raw
		foreach ($key in $this.Variables.Keys)
		{
			$configFilestream = $configFilestream -replace "v@{$key}{start{(?s)(.*?)}end}", $this.Variables[$key]
		}
		
		return $configFilestream
	}
}