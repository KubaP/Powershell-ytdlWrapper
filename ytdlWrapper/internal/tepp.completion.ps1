# Scriptblocks used for tab expansion assignments
$argCompleter_JobName = {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	
	# Import all youtube-dl.Job objects from the database file
	$jobList = Get-Jobs -Path "$script:DataPath\database.xml"
	
	if ($jobList.Count -eq 0) {
		Write-Output ""
	}
	
	# Return the names which match the currently typed in pattern
	$jobList.Name | Where-Object { $_ -like "$wordToComplete*" }
	
}

$argCompleter_JobVariable = {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	
	# Get the already typed in job name
	$jobName = $fakeBoundParameters.JobName
	
	if ($null -ne $jobName) {
		
		# Import all youtube-dl.Job objects from the database file
		$jobList = Get-Jobs -Path "$script:DataPath\database.xml"
		
		
		$job = $jobList | Where-Object { $_.Name -eq $jobName }
		
		if ($null -ne $job) {
			
			# Return the variables which match currently typed in pattern
			$job.Variables.Keys | Where-Object { $_ -like "$wordToComplete*" }
			
		}
		
	}
	
}

# Tab expansion assignements for commands
Register-ArgumentCompleter -CommandName Invoke-YoutubeDL -ParameterName JobName -ScriptBlock $argCompleter_JobName
Register-ArgumentCompleter -CommandName Remove-YoutubeDLJob -ParameterName JobName -ScriptBlock $argCompleter_JobName
Register-ArgumentCompleter -CommandName Get-YoutubeDLJob -ParameterName JobName -ScriptBlock $argCompleter_JobName
Register-ArgumentCompleter -CommandName Set-YoutubeDLJob -ParameterName JobName -ScriptBlock $argCompleter_JobName
Register-ArgumentCompleter -CommandName Set-YoutubeDLJob -ParameterName Variable -ScriptBlock $argCompleter_JobVariable

