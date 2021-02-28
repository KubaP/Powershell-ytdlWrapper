# Scriptblocks used for tab expansion assignments
$argCompleter_ItemName = {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	
	# Import all objects from the database file depending on the switch.
	$list = if ($fakeBoundParameters.Template)
	{
		Read-Templates
	}
	elseif ($fakeBoundParameters.Job)
	{
		Read-Jobs
	}
	
	if ($list.Count -eq 0) {
		Write-Output ""
	}
	
	# Return the names which match the currently typed in pattern.
	# This first strips the string of any quotation marks, then matches it to  the valid names,
	# and then inserts the quotation marks again. This is necessary so that strings with spaces have quotes,
	# otherwise they will not be treated as one parameter.
	$list.Name | Where-Object { $_ -like "$($wordToComplete.Replace(`"`'`", `"`"))*" } | ForEach-Object { "'$_'" }
	
}

$argCompleter_JobVariable = {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	
	# Only proceed if specifying a job.
	if ($fakeBoundParameters.Template) { return }
	
	# Get the already typed in job name.
	$jobName = $fakeBoundParameters.Name
	
	if ($null -ne $jobName) {
		# Import all [YoutubeDlJob] objects from the database file.
		$jobList = Read-Jobs
		$job = $jobList | Where-Object { $_.Name -eq $jobName }
		
		if ($null -ne $job) {
			# Return the variables which match currently typed in pattern.
			$job.Variables.Keys | Where-Object { $_ -like "$($wordToComplete.Replace(`"`'`", `"`"))*" } `
				| ForEach-Object { "'$_'" }
		}
	}
}

# Tab expansion assignements for commands
Register-ArgumentCompleter -CommandName Get-YoutubeDlItem -ParameterName Names -ScriptBlock $argCompleter_ItemName
Register-ArgumentCompleter -CommandName Set-YoutubeDlItem -ParameterName Name -ScriptBlock $argCompleter_ItemName
Register-ArgumentCompleter -CommandName Set-YoutubeDlItem -ParameterName Variable -ScriptBlock $argCompleter_JobVariable
Register-ArgumentCompleter -CommandName Remove-YoutubeDlItem -ParameterName Names -ScriptBlock $argCompleter_ItemName
Register-ArgumentCompleter -CommandName Invoke-YoutubeDL -ParameterName Names -ScriptBlock $argCompleter_ItemName