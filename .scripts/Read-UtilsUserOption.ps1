function Read-UtilsUserOption  {
    <#
    .SYNOPSIS
    Opens an interactive single line menue for user confirmation.

    .DESCRIPTION
    Opens an interactive single line menue for user confirmation.

    .OUTPUTS
    The selected option by the user.



    
    .EXAMPLE

    Present a simple prompt with two selections:

    Read-UtilsUserOption "Confirm: "

 
    .EXAMPLE

    Present a simple prompt with two selections and an identation:

    Read-UtilsUserOption "Confirm: " @("A", "B", "C") -i 2


    .LINK
    
    #>

    

    [CmdletBinding(
        DefaultParameterSetName = "DefaultIndex"
    )]
    param (

        # The input prompt to ask the user.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [System.String]
        $Prompt,

        # Indentation for the prompt to display.
        [Parameter(
            Position = 2,
            Mandatory = $false
        )]
        [System.int32]
        [Alias('i')]
        $Indendation = 0,
                


        <#
          The Options to display for selection

          Input as Strings:
          @("Yes", "No")

          Input as Objects:
            $(
                @{
                    display = "Yes"
                    value   = $true
                    default = $true
                },
                @{
                    display = "No"
                    value   = $false
                }
            ),
        #>
        [Parameter(
            Position = 1,
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [System.Object[]]
        $Options = @(
            @{
                display = "Yes"
                value   = $true
                default = $true
            },
            @{
                display = "No"
                value   = $false
            }
        ),



        # The Default selected index, starting from left to right.
        # Either defaultValue or defaultIndex can be used.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "DefaultIndex"
        )]
        [System.Int32]
        [Alias('Default')]
        $DefaultIndex = 0,

        # The Default selected value.
        # Either defaultValue or defaultIndex can be used.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "DefaultValue"
        )]
        [System.String]
        $DefaultValue = "Yes",

        # Prevents a new line after finishing the method.
        [Parameter()]
        [Alias('SkipLineBreak')]
        [switch]
        $NoNewLine,



        # Define custom colors with ANSI-Escape-Sequences.
        [Parameter()]
        [System.Object]
        $CustomColors = @{
            _Prompt_   = $null
            _Option_   = $null
            _Selected_ = $null
        }
    )

    BEGIN {

        <#
            Setting up nice colors with ANSI-Escape sequences.
        #>
        $ANSI = Get-UtilsEscapeCode -AsHashtable
        $_ANSIPrompt_ = $ANSI.COLOR_CODES['BRIGHT_WHITE'].FOREGROUND
        $_ANSIOption_ = $ANSI.COLOR_CODES['BRIGHT_BLACK'].FOREGROUND 
        $_ANSISelected_ = $ANSI.COLOR_CODES['WHITE'].FOREGROUND + $ANSI.COLOR_CODES['MAGENTA'].BACKGROUND
        $_ANSIReset_ = $ANSI.COLOR_CODES['RESET']

        $_ANSIOption_ = $CustomColors._Option_ ?? $_ANSIOption_
        $_ANSISelected_ = $CustomColors._Selected_ ?? $_ANSISelected_
        $_ANSIPrompt_ = $CustomColors._Prompt_ ?? $_ANSIPrompt_


        <#
            Setting up user prompt and displayed options.
        #>
        $userPrompt = (" " * $Indendation) + $Prompt.TrimEnd()
        $processedOptions = @()
        $selectedIndex = 0 
        $marginSpace = "  "


        if ($PSBoundParameters.ContainsKey('DefaultIndex')) {
            $selectedIndex = $DefaultIndex
        }
        elseif ($PSBoundParameters.ContainsKey('DefaultValue')) {
            $selectedIndex = $Options.IndexOf($DefaultValue)

            if ($selectedIndex -LT 0) {
                throw [System.InvalidOperationException]::new("The Default Value '$DefaultValue' is not part of the Options.")
            }
        }
    }



    PROCESS {

        <#
            Convert all provided entries to a list of object:
            - Strings and ValueTypes: String or Value is displayed on screen as is.
            - Powershell Objects:     A property from the object is display on screen, to identify the object.
        #>
        foreach ($entry in $Options) {
            if (
                $entry -IS [System.String] -OR 
                $entry -IS [System.ValueType]
            ) {
                $processedOptions += @{
                    display = $entry
                    value   = $entry 
                }
            }
            else {
                $processedOptions += @{
                    display = $entry.display
                    value   = $entry.value
                }
            }
            
            if ($entry.default -EQ $true) {
                $selectedIndex = $processedOptions.Count - 1
            }
        }
    }



    END {

        $cursorX = [System.Console]::GetCursorPosition().Item1
        try {
            do {

                [System.Console]::CursorVisible = $false
                $uIwidth = $host.UI.RawUI.WindowSize.Width 
                $cursorY = [System.Console]::GetCursorPosition().Item2

                <#
                    Overwrites the previous drawn line with whitespaces.

                    Then resets the cursor and draws the Prompt.
                #>
                [System.Console]::SetCursorPosition($cursorX, $cursorY)
                [System.Console]::Write(" " * $uIwidth)

                [System.Console]::SetCursorPosition($cursorX, $cursorY)
                [System.Console]::Write($_ANSIPrompt_)
                [System.Console]::write($userPrompt)
                [System.Console]::Write($_ANSIReset_)


                for ($index = 0; $index -LT $processedOptions.Count; $index++) {

                    [System.Console]::Write($marginSpace)
                    if ($index -EQ $selectedIndex) {
                        [System.Console]::Write($_ANSISelected_)
                        [System.Console]::Write($processedOptions[$index].display)
                        [System.Console]::Write($_ANSIReset_)
                    }
                    else {
                        [System.Console]::Write($_ANSIOption_)
                        [System.Console]::Write($processedOptions[$index].display)
                        [System.Console]::Write($_ANSIReset_)
                    }

                }
 


                <#
                    Handle Key Inputs from User.

                    - Move selectedIndex to left or right, based on userinput
                #>
                $keyEvent = [System.Console]::ReadKey($true)
                
                if (
                    $keyEvent.Key -EQ [System.ConsoleKey]::D -OR
                    $keyEvent.Key -EQ [System.ConsoleKey]::RightArrow
                ) {
                    $selectedIndex = ($selectedIndex + 1) % $processedOptions.Count
                }
                elseif (
                    $keyEvent.Key -EQ [System.ConsoleKey]::A -OR
                    $keyEvent.Key -EQ [System.ConsoleKey]::LeftArrow
                ) {
                    $selectedIndex = ($selectedIndex + $processedOptions.Count - 1) % $processedOptions.Count
                }
                elseif (
                    $keyEvent.Key -EQ [System.ConsoleKey]::Enter
                ) {
                    return $processedOptions[$selectedIndex].value
                }

            } while ($keyEvent.Key -NE [System.ConsoleKey]::Escape)
        }
        finally {
            # Make sure to always leave in any case function with a visible cursor again.
            [System.Console]::CursorVisible = $true
        
            # Write a new Line to set the cursor to the next line.
            if (-NOT $NoNewLine.IsPresent) {
                Write-Host "" 
            }
        }
    }
}
