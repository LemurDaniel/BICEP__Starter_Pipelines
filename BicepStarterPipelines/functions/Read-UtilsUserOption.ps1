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
                    - Background
                - Option
                    - ForeGround
                    - Background
                - Selected
                    - ForeGround
                    - Background

            Following Colors are supported:
                - HEX: #FFFFFF
                - RGB: 255, 255, 255
                - ColorName: Colors in $PSStyle.Foreground or $PSStyle.Background

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

        $transformedColors = @{
            Prompt   = @{
                ForeGround = "White"
                Background = $null
            }
            Option   = @{
                ForeGround = "BrightBlack"
                Background = $null
            }
            Selected = @{
                ForeGround = "BrightWhite"
                Background = "Magenta"
            }
        }

        foreach ($key in $transformedColors.Keys) {
            $fg = $CustomColors[$key].ForeGround ?? $transformedColors[$key].ForeGround
            $transformedColors[$key].ForeGround = Convert-Color -Color $fg -Type 'Foreground'

            $bg = $CustomColors[$key].BackGround ?? $transformedColors[$key].Background
            $transformedColors[$key].BackGround = Convert-Color -Color $bg -Type 'Background'
        }
        
        <#
            Setting up the colors for the prompt and options.
        #>
        $_Color_Reset_ = $PSStyle.Reset
        $_Color_Option_ = '' + $transformedColors.Option.ForeGround + $transformedColors.Option.Background
        $_Color_Selected_ = '' + $transformedColors.Selected.ForeGround + $transformedColors.Selected.Background
        $_Color_Prompt_ = '' + $transformedColors.Prompt.ForeGround + $transformedColors.Prompt.Background


        <#
            Setting up user prompt and displayed options.
        #>
        $userPrompt = (" " * $Indendation) + $Prompt.TrimEnd()
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
        if (
            $Options -IS [System.String] -OR 
            $Options -IS [System.ValueType]
        ) {
            $processedOptions += @{
                display = $Options
                value   = $Options 
            }
        }
        else {
            $processedOptions += @{
                display = $Options.display
                value   = $Options.value
            }

            if ($null -EQ $Options.display -OR $null -EQ $Options.display) {
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
        }
            
        if ($Options.default -EQ $true) {
            $selectedIndex = $processedOptions.Count - 1
        }
    }



    END {

        if (-NOT $PSCmdlet.MyInvocation.ExpectingInput) {
            return
        }
        
        [System.Console]::TreatControlCAsInput = $true
        $cursorX = [System.Console]::GetCursorPosition().Item1
        
        do {

            [System.Console]::CursorVisible = $false
            $uIwidth = $Host.UI.RawUI.BufferSize.Width 
            $cursorY = [System.Console]::GetCursorPosition().Item2

            <#
                Overwrites the previous drawn line with whitespaces.

                Then resets the cursor and draws the Prompt.
            #>
            [System.Console]::SetCursorPosition($cursorX, $cursorY)
            [System.Console]::Write(" " * $uIwidth)

            [System.Console]::SetCursorPosition($cursorX, $cursorY)
            [System.Console]::Write($_Color_Prompt_)
            [System.Console]::write($userPrompt)
            [System.Console]::Write($_Color_Reset_)


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
