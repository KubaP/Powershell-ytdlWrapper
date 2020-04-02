[CmdletBinding()]
Param (
	
	# Skips all psscriptanalyzer tests
	[switch]
	$SkipTest,
	
	# Paths in which the files to be tested are located
	[string[]]
	$CommandPath = @("$PSScriptRoot\..\..\functions", "$PSScriptRoot\..\..\internal\functions")
	
)

if ($SkipTest) { return }

$list = New-Object System.Collections.ArrayList

Describe 'Invoking PSScriptAnalyzer against commandbase' {
	
	# Get all script files to be tested
	$commandFiles = Get-ChildItem -Path $CommandPath -Recurse | Where-Object Name -like "*.ps1"
	$scriptAnalyzerRules = Get-ScriptAnalyzerRule
	
	foreach ($file in $commandFiles) {
		
		Context "Analyzing $($file.BaseName)" {
			
			# Run psscriptanalyzer on each file
			$analysis = Invoke-ScriptAnalyzer -Path $file.FullName -ExcludeRule PSAvoidTrailingWhitespace, PSShouldProcess, PSAvoidUsingWriteHost
			
			foreach ($rule in $scriptAnalyzerRules) {
				
				# Check that the file passes all rules
				It "Should pass $rule" {
					
					If ($analysis.RuleName -contains $rule) {
						
						$analysis | Where-Object RuleName -EQ $rule -OutVariable failures | ForEach-Object { $list.Add($_) }						
						1 | Should Be 0
						
					}else {
						
						0 | Should Be 0
						
					}
					
				}
				
			}
			
		}
		
	}
	
}

$list | Out-Default