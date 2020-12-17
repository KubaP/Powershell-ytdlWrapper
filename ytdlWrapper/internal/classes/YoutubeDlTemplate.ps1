enum TemplateState {
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
	
	[TemplateState] GetState() {
		return [YoutubeDlTemplate]::GetState($this.Path)
	}
	
	static [TemplateState] GetState([string]$path) {
		
		# Check for an invalid path.
		if (-not (Test-Path -Path $path))
		{
			return [TemplateState]::InvalidPath
		}
		
		# Check that the template has at least one input.
		if ((Read-ConfigDefinitions -Path $path -InputDefinitions).Count -eq 0)
		{
			return [TemplateState]::NoInputs
		}
		
		# After these checks, this template should be valid.
		return [TemplateState]::Valid
	}
	
	[hashtable] GetInputs()
	{
		$inputs = New-Object -TypeName hashtable
		
		# Get the definitions within the file.
		$inputDefinitions = Read-ConfigDefinitions -Path $this.Path -InputDefinitions
		foreach ($definition in $inputDefinitions)
		{
			$inputs[$definition] = ""
		}
		
		return $inputs
	}
	
	[string] CompleteTemplate([hashtable]$inputs)
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
