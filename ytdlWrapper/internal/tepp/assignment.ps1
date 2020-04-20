# Tab expansion assignements for commands
Register-ArgumentCompleter -CommandName Invoke-YoutubeDL -ParameterName JobName -ScriptBlock $argCompleter_JobName
Register-ArgumentCompleter -CommandName Remove-YoutubeDLJob -ParameterName JobName -ScriptBlock $argCompleter_JobName
Register-ArgumentCompleter -CommandName Get-YoutubeDLJob -ParameterName JobName -ScriptBlock $argCompleter_JobName
Register-ArgumentCompleter -CommandName Set-YoutubeDLJob -ParameterName JobName -ScriptBlock $argCompleter_JobName
Register-ArgumentCompleter -CommandName Set-YoutubeDLJob -ParameterName Variable -ScriptBlock $argCompleter_JobVariable

