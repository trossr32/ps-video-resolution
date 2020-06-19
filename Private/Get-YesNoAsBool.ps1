<# 
.Description
Prompts the user with a yes/no option and returns the result as a boolean where 'yes' equals true
.Parameter header
Header text to display in the Host.ChoiceDescription control
.Parameter question
Question text to display in the Host.ChoiceDescription control
.Outputs
Result of the user's yes/no choice, true if yes and false if no
#>
Function Get-YesNo-As-Bool($header, $question) {
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&yes"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&no"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($header, $question, $options, 0) 

    switch ($result) {
        0 { return $true }
        1 { return $false }
    }
}