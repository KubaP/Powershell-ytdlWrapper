enum TemplateState
{
	Valid
	InvalidPath
	NoInputs
}

class YoutubeDlTemplate
{
	[string]$Name
	[string]$Path
	
	# Constructor.
	YoutubeDlTemplate([string]$name, [string]$path)
	{
		$this.Name = $name
		$this.Path = $path
	}
	
	[TemplateState] GetState()
	{
		# Check through all the invalid states for a template.
		if ($this.HasInvalidPath())
		{
			return [TemplateState]::InvalidPath
		}
		if ($this.HasNoInput())
		{
			return [TemplateState]::NoInputs
		}
		return [TemplateState]::Valid
	}
	
	[boolean] HasInvalidPath()
	{
		return [YoutubeDlTemplate]::HasInvalidPath($this.Path)
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
	
	[boolean] HasNoInput()
	{
		return [YoutubeDlTemplate]::HasNoInput($this.Path)
	}
	static [boolean] HasNoInput([string]$path)
	{
		# Check whether the template has no inputs.
		if ((Read-ConfigDefinitions -Path $path -InputDefinitions).Count -gt 0)
		{
			return $false
		}
		return $true
	}
	
	
	[System.Collections.Generic.List[string]] GetInputs()
	{
		# Get the definitions within the file.
		return Read-ConfigDefinitions -Path $this.Path -InputDefinitions
	}
	
	[string] GetCompletedConfigFile([hashtable]$inputs)
	{
		# Go through all input definitions and substitute the user provided
		# value, before returning the modified file content string.
		$configFilestream = Get-Content -Path $this.Path -Raw
		foreach ($key in $inputs.Keys)
		{
			$configFilestream = $configFilestream -replace "i@{$key}", $inputs[$key]
		}
		
		return $configFilestream
	}
	
}
