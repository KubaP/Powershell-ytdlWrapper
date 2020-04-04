# Scriptblocks used for tab expansion assignments
$argCompleter_JobName = {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    # Import all PMPackage objects from the database file
	$jobList = Read-Jobs -Path "$script:DataPath\database.xml"	
	
	if ($jobList.Count -eq 0) {
		Write-Output ""
	}
	
    $jobList.Name | Where-Object { $_ -like "$wordToComplete*" }
	
}