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
	hidden [hashtable]$_Variables
	
	# Constructor.
	YoutubeDlJob ([string]$name, [string]$path, [hashtable]$variableValues)
	{
		$this.Name = $name
		$this.Path = $path
		$this._Variables = $variableValues
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
		if ((Read-ConfigDefinitions -Path $path -InputDefinitions).Count -gt 0)
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
			$differenceA = $configVariables | Where-Object { $this._Variables.Keys -notcontains $_ }
			$differenceB = $this._Variables.Keys | Where-Object { $configVariables -notcontains $_ }
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
		foreach ($value in $this._Variables.Values)
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
	
	[System.Collections.Generic.List[string]] GetStoredVariables()
	{
		# Get the variable names defined in this object.
		$returnList = New-Object -TypeName System.Collections.Generic.List[string]
		foreach ($key in $this._Variables.Keys)
		{
			$returnList.Add($key)
		}
		
		return $returnList
	}
	
	[System.Collections.Generic.List[string]] GetNullVariables()
	{
		# Get any variable names defined in this object which don't have a value.
		$returnList = New-Object -TypeName System.Collections.Generic.List[string]
		foreach ($key in $this._Variables.Keys)
		{
			if (($null -eq $this._Variables[$key]) -or [system.string]::IsNullOrWhiteSpace($this._Variables[$key]))
			{
				$returnList.Add($key)
			}
		}
		
		return $returnList
	}
	
	[string] GetCompletedConfigFile()
	{
		# Go through all variable definitions and substitute the stored variable
		# value, before returning the modified file content string.
		$configFilestream = Get-Content -Path $this.Path -Raw
		foreach ($key in $this._Variables.Keys)
		{
			$configFilestream = $configFilestream -replace "v@{$key}{start{(?s)(.*?)}end}", $this._Variables[$key]
		}
		
		return $configFilestream
	}
	
	[string] UpdateVariableValues()
	{
		$scriptblockDefinitions = Read-ConfigDefinitions -Path $this.Path -VariableScriptblocks
		# Iterate through all scriptblock definitions and execute them.
		foreach ($key in $scriptblockDefinitions.Keys)
		{
			$scriptblock = [scriptblock]::Create($scriptblockDefinitions[$key])
			$returnResult = Invoke-Command -ScriptBlock $scriptblock
			# If no value is returned, return the variable name to the invocation
			# cmdlet to warn the user.
			if ($null -eq $returnResult)
			{
				return $key
			}
			
			$this._Variables[$key] = $returnResult
		}
		
		return $null
	}
}