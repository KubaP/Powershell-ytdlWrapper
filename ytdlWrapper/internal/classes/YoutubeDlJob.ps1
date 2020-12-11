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
}