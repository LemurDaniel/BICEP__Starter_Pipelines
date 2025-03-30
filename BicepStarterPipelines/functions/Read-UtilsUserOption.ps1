function Read-UtilsUserOption {
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
        [System.Object]
        $Options = @(
            @{
                display = "No"
                value   = $false
                default = $true
            },
            @{
                display = "Yes"
                value   = $true
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
        $DefaultValue,

        # Prevents a new line after finishing the method.
        [Parameter()]
        [Alias('SkipLineBreak')]
        [switch]
        $NoNewLine,


        <#
            Custom colors for the prompt and options.

            Provide a hashtable with the following keys.
            Each key is optional and $null will be replaced with the default value.
                - Prompt
                    - ForeGround
                    - BackGround
                - Option
                    - ForeGround
                    - BackGround
                - Selected
                    - ForeGround
                    - BackGround

            Following Colors are supported:
                - HEX: #FFFFFF
                - RGB: 255, 255, 255
                - ColorName: Colors in $PSStyle.ForeGround or $PSStyle.BackGround

            Example:
                @{
                    Prompt   = @{
                        ForeGround = "White" # White in HEX
                        BackGround = $null
                    }
                    Option   = @{
                        ForeGround = "BrightBlack" # Light Gray in HEX
                        BackGround = $null
                    }
                    Selected = @{
                        ForeGround = "BrightWhite"
                        BackGround = "Magenta"
                    }
                }
        #>
        [Parameter()]
        [System.Collections.Hashtable]   
        $CustomColors = @{}
    )

    BEGIN {
        function Convert-Color {
            param(
                [System.Object] $Color,
                [System.String] $Type
            )

            if ($null -EQ $Color) {
                return $null
            }

            if ($Color -IS [System.String] -AND $Color.startswith('#')) {
                $Color = [System.Convert]::FromHexString($Color.substring(1))
            }

            if (-NOT ($Color -IS [System.String])) {
                $COLORS_24BIT = @{
                    FOREGROUND = "`e[38;2;{0};{1};{2}m"
                    BACKGROUND = "`e[48;2;{0};{1};{2}m"
                }
        
                return $COLORS_24BIT."$Type" -f $Color[0], $Color[1], $Color[2]
            }


            if ($null -EQ $PSStyle."$Type"."$Color") {
                throw [System.InvalidOperationException]::new("The provided color '$Color' is not a valid color.")
            }
            else {
                return $PSStyle."$Type"."$Color"
            }      
        }

        # These are default colors, which can be overridden by custom colors.
        $transformedColors = @{
            Prompt   = @{
                ForeGround = "White"
                BackGround = $null
            }
            Option   = @{
                ForeGround = "BrightBlack"
                BackGround = $null
            }
            Selected = @{
                ForeGround = "BrightWhite"
                BackGround = "Magenta"
            }
        }

        foreach ($key in $transformedColors.Keys) {
            $fg = $CustomColors[$key].ForeGround ?? $transformedColors[$key].ForeGround
            $transformedColors[$key].ForeGround = Convert-Color -Color $fg -Type 'ForeGround'

            $bg = $CustomColors[$key].BackGround ?? $transformedColors[$key].BackGround
            $transformedColors[$key].BackGround = Convert-Color -Color $bg -Type 'BackGround'
        }
        
        <#
            Setting up the colors for the prompt and options.
        #>
        $_Color_Reset_ = $PSStyle.Reset
        $_Color_Option_ = '' + $transformedColors.Option.ForeGround + $transformedColors.Option.BackGround
        $_Color_Selected_ = '' + $transformedColors.Selected.ForeGround + $transformedColors.Selected.BackGround
        $_Color_Prompt_ = '' + $transformedColors.Prompt.ForeGround + $transformedColors.Prompt.BackGround


        <#
            Setting up user prompt and displayed options.
        #>
        $userPrompt = (" " * $Indendation) + $Prompt.TrimEnd(' ') # Trim only whitespace, $null what also trim control like linebreaks.
        $selectedIndex = $DefaultIndex
        $marginSpace = "  "

        if ($PSBoundParameters.ContainsKey('DefaultValue')) {
            $selectedIndex = ($Options.display ?? $Options).IndexOf($DefaultValue)

            if ($selectedIndex -LT 0) {
                throw [System.InvalidOperationException]::new("The Default Value '$DefaultValue' is not part of the Options.")
            }
        }

        $processedOptions = @()
    }



    PROCESS {
        <#
            If the user provided the obect as a parameter,
            we pipe it to a new instance of the function.
        #>
        if (-NOT $PSCmdlet.MyInvocation.ExpectingInput) {
            $null = $PSBoundParameters.Remove('Options')
            return $Options | Read-UtilsUserOption @PSBoundParameters
        }


        <#
            Convert all provided entries to a list of object:
            - Strings and ValueTypes: String or Value is displayed on screen as is.
            - Powershell Objects:     A property from the object is display on screen, to identify the object.
        #>

        $optionWrapper = @{
            display = $null
            value   = $Options
        }

        $processedOptions += $optionWrapper
        if ($Options.default -EQ $true) {
            $selectedIndex = $processedOptions.Count - 1
        }

        if (
            $Options -IS [System.String] -OR 
            $Options -IS [System.ValueType]
        ) {
            $optionWrapper.display = $Options
        }
        else {
            $optionWrapper.display = $Options.display
        }

        if (
            [System.String]::IsNullOrEmpty($optionWrapper.value) -OR
            [System.String]::IsNullOrEmpty($optionWrapper.display)
        ) {
            throw [System.InvalidOperationException]::new("@
                The provided option is not a valid object. 
                Please provide a hashtable with the properties 'display' and 'value'.
                Example: 
                @{ 
                    display = 'Option1'
                    value = @{
                        file = 'test.txt'
                        path = 'C:\temp'
                    }
                }
@")
        }

        if (
            $optionWrapper.display.Contains("`n")
        ) {
            $optionWrapper.display = $optionWrapper.display.Replace("`n", "")
            Write-Warning "Linebreaks are only allowed in the Prompt. Any linebreak in the option will be removed."
        }
            
    }



    END {

        if (-NOT $PSCmdlet.MyInvocation.ExpectingInput) {
            return
        }
        
        [System.Console]::Write($_Color_Prompt_)
        [System.Console]::Write($userPrompt)
        [System.Console]::Write($_Color_Reset_)

        [System.Console]::CursorVisible = $false
        [System.Console]::TreatControlCAsInput = $true

        $cursorX = [System.Console]::GetCursorPosition().Item1
        $cursorY = [System.Console]::GetCursorPosition().Item2


        do {

            <#
                Sets the cursor position to the start of the line.

                Then draws all options in a single line.
            #>
            [System.Console]::SetCursorPosition($cursorX, $cursorY)


            for ($index = 0; $index -LT $processedOptions.Count; $index++) {

                [System.Console]::Write($marginSpace)
                if ($index -EQ $selectedIndex) {
                    [System.Console]::Write($_Color_Selected_)
                    [System.Console]::Write($processedOptions[$index].display)
                    [System.Console]::Write($_Color_Reset_)
                }
                else {
                    [System.Console]::Write($_Color_Option_)
                    [System.Console]::Write($processedOptions[$index].display)
                    [System.Console]::Write($_Color_Reset_)
                }

            }
 


            <#
            
                ////////////////////////////////////////
                /// Handle Key Inputs from User.

            #>
            
            $e = [System.Console]::ReadKey($true)

            <#
                Cancel the operation if the user presses ESC or CTRL+C.
            #>
            if (
                $e.Key -EQ [System.ConsoleKey]::Escape -OR
                ($e.Key -EQ [System.ConsoleKey]::C -AND $e.Modifiers -EQ "Control")
            ) {
                throw [System.OperationCanceledException]::new("User canceled the operation.")
            }
                
            elseif (
                $e.Key -EQ [System.ConsoleKey]::D -OR
                $e.Key -EQ [System.ConsoleKey]::RightArrow
            ) {
                $selectedIndex = ($selectedIndex + 1) % $processedOptions.Count
            }
            elseif (
                $e.Key -EQ [System.ConsoleKey]::A -OR
                $e.Key -EQ [System.ConsoleKey]::LeftArrow
            ) {
                $selectedIndex = ($selectedIndex + $processedOptions.Count - 1) % $processedOptions.Count
            }


            <#
                When a number is entered, select the corresponding optiona at the index.
            #>
            if (
                [System.Char]::IsDigit($e.KeyChar)
            ) {
                $enteredIndex = [System.Byte]::Parse($e.KeyChar) - 1
                $enteredIndex = [System.Math]::Max(0, $enteredIndex)

                if ($processedOptions.Count -GE $enteredIndex) {
                    $selectedIndex = $enteredIndex
                }
            }

            <#
                Return the selected value if the user presses ENTER.
            #>
            elseif (
                $e.Key -EQ [System.ConsoleKey]::Enter
            ) {

                # Write a new Line to set the cursor to the next line.
                if (-NOT $NoNewLine.IsPresent) {
                    [System.Console]::Write([System.Environment]::NewLine)
                }

                return $processedOptions[$selectedIndex].value
            }

        } while ($e.Key -NE [System.ConsoleKey]::Enter)

    }

    CLEAN {                
        # Make sure to always leave in any case function with a visible cursor again.
        [System.Console]::CursorVisible = $true
    }
}
