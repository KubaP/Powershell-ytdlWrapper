enum JobState
{
	Valid
	InvalidPath
	MismatchedVariables
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
		return [YoutubeDlJob]::GetState($this.Path, $this._Variables.Keys)
	}
	
	static [JobState] GetState([string]$path, [System.Collections.Generic.List[string]]$variablesList)
	{
		# Check for an invalid path.
		if (-not (Test-Path -Path $path))
		{
			return [JobState]::InvalidPath
		}
		
		# Check that there are no input definitions in the config file
		# since this is a job object.
		if ((Read-ConfigDefinitions -Path $path -InputDefinitions).Count -gt 0)
		{
			return [JobState]::HasInputs
		}
		
		# Check that the variables stored in the job object match the
		# variables defined in the configuration file, as long as there 
		# actually is a variable defined in the file.
		$configVariables =  Read-ConfigDefinitions -Path $path -VariableDefinitions
		if (-not($configVariables.Count -eq 0))
		{
			$differenceA = $configVariables | Where-Object { $variablesList -notcontains $_ }
			$differenceB = $variablesList | Where-Object { $configVariables -notcontains $_ }
			if (($null -ne $differenceA) -or ($null -ne $differenceB))
			{
				return [JobState]::MismatchedVariables
			}
		}
		
		# After these checks, this template should be valid.
		return [JobState]::Valid
	}
	
	[System.Collections.Generic.List[string]] GetVariables()
	{
		# Get the definitions within the file.
		return Read-ConfigDefinitions -Path $this.Path -VariableDefinitions
	}
	
	[string] CompleteJob()
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
	
	[string] ExecuteScriptblocks()
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