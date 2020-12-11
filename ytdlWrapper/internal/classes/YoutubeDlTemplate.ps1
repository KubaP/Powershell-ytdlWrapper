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
	
	[hashtable] GetInputs()
	{
		$inputs = New-Object -TypeName hashtable
		
		# If the config filepath is valid, get the definitions within the file.
		if (Test-Path -Path $this.Path)
		{
			$inputDefinitions = Read-ConfigDefinitions -Path $this.Path -InputDefinitions
			
			foreach ($definition in $inputDefinitions)
			{
				$inputs[$definition] = ""
			}
		}
		
		return $inputs
	}
	
	[string] CompleteTemplate([hashtable]$inputs)
	{
		# If the config filepath is invalid, return nothing.
		if (-not (Test-Path -Path $this.Path))
		{
			return $null
		}
		
		$configFilestream = Get-Content -Path $this.Path -Raw
		$inputDefinitions = Read-ConfigDefinitions -Path $this.Path -InputDefinitions
		foreach ($definition in $inputDefinitions)
		{
			if ($inputs.ContainsKey($definition))
			{
				
				$configFilestream = $configFilestream -replace "i@{$definition}", $inputs[$definition]
				
			}
			else
			{
				return $null
			}
		}
		
		$stream = [System.IO.MemoryStream]::new([byte[]][char[]]$configFilestream)
		$hash = (Get-FileHash -InputStream $stream -Algorithm SHA256).hash
		Out-File -FilePath "$script:Folder\$hash.conf" -Force -InputObject $configFilestream
		return $hash
	}
	
}
