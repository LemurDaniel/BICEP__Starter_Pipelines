function Select-UtilsUserOption {
    <#
    .SYNOPSIS
    Opens an interactive single line menue for user confirmation.

    .DESCRIPTION
    Opens an interactive single line menue for user confirmation.

    .OUTPUTS
    The selected option by the user.



    
    .EXAMPLE

    Provides two options asking for yes or no. Will return $true on yes and $false on no.

    PS> Select-UtilsUserOption


    .EXAMPLE

    Provides the basic prompt with a custom message.

    PS> Select-UtilsUserOption "Confirm:  "

 
    .EXAMPLE

    PS> Present a simple prompt with two selections and an identation:

    Select-UtilsUserOption -Prompt "Confirm:`n" -Options "A", "B", "C" -i 2


    .EXAMPLE

    Present options via pipeline input.

    PS>  "Option A", "Option B", "Option C" | Select-UtilsUserOption -Prompt "Choose:  " -i 2


    .EXAMPLE

    Selects between two files, displaying the name and returning the full path.

    PS> Get-ChildItem -File 
        | Select-Object -First 2 
        | Select-UtilsUserOption -Display name -Return FullName

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


        <#
          The Options to display for selection

          Input as Strings:
          @("Yes", "No")

          For input as object use -Display and -Return to define the properties to display and return.
          -Return is optional and will return the whole object if not provided.
          -Display is set to 'display' by default and will use the property 'display' from the object.
          @{
              display = "Name"
              return  = "FullName"
          },
        #>
        [Parameter(
            Position = 1,
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [System.Object]
        $Options,


        # Indentation for the prompt to display.
        [Parameter(
            Position = 2,
            Mandatory = $false
        )]
        [System.Byte]
        [Alias('i')]
        $Indendation = 0,

        # Margin space between options.
        [Parameter()]
        [System.Byte]
        [Alias('m')]
        $Margin = 2,

        # When an object is provided, this property is used to display the object.
        [Parameter()]
        [System.String]
        $Display = 'display',

        # When an object is provided, this property is used to return the object.
        [Parameter()]
        [System.String]
        $Return,


        # The Default selected index, starting from left to right.
        # Either defaultValue or defaultIndex can be used.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "DefaultIndex"
        )]
        [System.Int32]
        [Alias('Default', 'DefautlIndex')]
        $Index = 0,

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

        $difference = $CustomColors.Keys | Where-Object { $_ -NOTIN $transformedColors.Keys }
        if ($difference.Count -GT 0) {
            throw [System.InvalidOperationException]::new("`nOn CustomColors, the following keys are not valid: $difference.`nPlease use the following keys: $($transformedColors.Keys)")
        }

        foreach ($key in $transformedColors.Keys) {

            $difference = $CustomColors[$key].Keys | Where-Object { $_ -NOTIN 'ForeGround', 'BackGround' }
            if ($difference.Count -GT 0) {
                throw [System.InvalidOperationException]::new("`nOn Custom Color for '$Key', the following keys are not valid: $difference`nPlease use the following keys: 'ForeGround', 'BackGround'")
            }

            $fg = $CustomColors[$key].ForeGround ?? $transformedColors[$key].ForeGround
            $transformedColors[$key].ForeGround = Convert-Color -Color $fg -Type 'ForeGround'

            $bg = $CustomColors[$key].BackGround ?? $transformedColors[$key].BackGround
            $transformedColors[$key].BackGround = Convert-Color -Color $bg -Type 'BackGround'
        }
        
        <#
            Setting up the colors for the prompt and options.
        #>
        $_LineBreak_ = [System.Environment]::NewLine

        $_Color_Reset_ = $PSStyle.Reset
        $_Color_Option_ = '' + $transformedColors.Option.ForeGround + $transformedColors.Option.BackGround
        $_Color_Selected_ = '' + $transformedColors.Selected.ForeGround + $transformedColors.Selected.BackGround
        $_Color_Prompt_ = '' + $transformedColors.Prompt.ForeGround + $transformedColors.Prompt.BackGround


        <#
            Setting up user prompt and displayed options.
            - PromptLineBreaks: The number of line after the prompt, so only the prompt is colored.
                                If you want multiple colored lines, just use Write-Host with the color you want.

            - PromptSeperation: The space between the prompt and the input text.
            - IndendationSpace: The space before the prompt.

            - $marginSpace: Space between each option.
            - $indendationSpace: Space before the prompt or options, when the options are on the next line.
            - $promptSeperation: Space between the prompt and the first option, when the prompt is on the same line.
        #>
        $promptLineBreaksStart = $_LineBreak_ * ($Prompt.TrimEnd().Length - $Prompt.TrimEnd().Replace("`n", '').Length)
        $promptLineBreaksEnd = $_LineBreak_ * ($Prompt.TrimStart().Length - $Prompt.TrimStart().Replace("`n", '').Length)
        $promptSeperation = ' ' * $($Prompt.Length - $Prompt.TrimEnd(' ').Length)
        $indendationSpace = ' ' * $Indendation 
        $marginSpace = ' ' * $Margin

        $Prompt = $Prompt.Trim().Replace("`r`n", '').Replace("`r", '')


        if ($PSBoundParameters.ContainsKey('DefaultValue')) {
            $Index = ($Options.display ?? $Options).IndexOf($DefaultValue)

            if ($Index -LT 0) {
                throw [System.InvalidOperationException]::new("The Default Value '$DefaultValue' is not part of the Options.")
            }
        }

        $wrappedOptions = @()
    }



    PROCESS {

        <#
            If the user provided the obect as a parameter,
            we pipe it to a new instance of the function.
        #>
        if (-NOT $PSCmdlet.MyInvocation.ExpectingInput) {
            <#
                When no option were provided at all, we define the default options.
            #>
            if ($Options.Count -EQ 0) {
                $null = $PSBoundParameters['Return'] = 'return'
                $null = $PSBoundParameters['Display'] = 'display'
                $Options = @(
                    @{
                        display = "No"
                        return  = $false
                        default = $true
                    },
                    @{
                        display = "Yes"
                        return  = $true
                    }
                ) 
            }

            $null = $PSBoundParameters.Remove('Options')
            return $Options | Select-UtilsUserOption @PSBoundParameters
        }


        <#
            Convert all provided entries to a list of object:
            - Strings and ValueTypes: String or Value is displayed on screen as is.
            - Powershell Objects:     A property from the object is display on screen, to identify the object.
        #>

        if (
            -NOT ($Options -IS [System.String]) -AND 
            -NOT ($Options -IS [System.ValueType])
        ) {
            if (
                -NOT [System.String]::IsNullOrEmpty($Return) -AND
                [System.String]::IsNullOrEmpty($Options."$Return")    
            ) {
                throw [System.InvalidOperationException]::new("`nThe provided object does not contain a property with the name '$Return'.`nUse the -Return parameter to specify a custom property name.`n")
            }

            if (
                -NOT [System.String]::IsNullOrEmpty($Display) -AND
                [System.String]::IsNullOrEmpty($Options."$Display")    
            ) {
                throw [System.InvalidOperationException]::new("`nThe provided object does not contain a property with the name '$Display'.`nUse the -Display parameter to specify a custom property name.`n")
            }
        }


        $optionWrapper = @{
            display = $Options."$display" ?? $Options
            value   = $Options."$return" ?? $Options
        }


        if (
            $optionWrapper.display.Contains("`n")
        ) {
            $optionWrapper.display = $optionWrapper.display.Replace("`n", "")
            Write-Warning "Linebreaks are only allowed in the Prompt. Any linebreak in the option will be removed."
        }
     
        $wrappedOptions += $optionWrapper

        if ($Options.default -EQ $true) {
            $Index = $wrappedOptions.Count - 1
        }

    }



    END {

        if (-NOT $PSCmdlet.MyInvocation.ExpectingInput) {
            return
        }
        
        # Indentation shouldn't be affected by the color for the prompt.
        [System.Console]::Write($promptLineBreaksStart)
        [System.Console]::Write($indendationSpace)
        [System.Console]::Write($_Color_Prompt_)
        [System.Console]::Write($Prompt)
        [System.Console]::Write($_Color_Reset_)

        # If the prompt contains a linebreak, 
        #   then apply the indentation again to the next line.
        #   otherwise the margin space is used to separate the option from the prompt.
        if ($promptLineBreaksEnd.Length -GT 0) {
            [System.Console]::Write($promptLineBreaksEnd)
            [System.Console]::Write($indendationSpace)
        }
        else {
            # Whitespaces at the end of the prompt are extrated and written separately,
            #  so that the are not affected by custom colors affecting the prompt background.
            [System.Console]::Write($promptSeperation)
        }

        # Save existing value and change it to true.
        $TreatControlCAsInput = [System.Console]::TreatControlCAsInput
        [System.Console]::TreatControlCAsInput = $true
        [System.Console]::CursorVisible = $false

        # Save curors position where the options will be displayed.
        $cursorPosition = [System.Numerics.Vector2]::new(
            [System.Console]::GetCursorPosition().Item1,
            [System.Console]::GetCursorPosition().Item2
        )

        do {

            <#
                Sets the cursor position to the start of the line.

                Then draws all options in a single line.
            #>
            [System.Console]::SetCursorPosition($cursorPosition.X, $cursorPosition.Y)

            for ($CurrentIndex = 0; $CurrentIndex -LT $wrappedOptions.Count; $CurrentIndex++) {

                
                # Don't write the margin space:
                # - before the first option
                # - after the last option
                if ($CurrentIndex -GT 0 -AND $CurrentIndex -LT $wrappedOptions.Count) {
                    [System.Console]::Write($marginSpace)
                }

                if ($CurrentIndex -EQ $Index) {
                    [System.Console]::Write($_Color_Selected_)
                    [System.Console]::Write($wrappedOptions[$CurrentIndex].display)
                    [System.Console]::Write($_Color_Reset_)
                }
                else {
                    [System.Console]::Write($_Color_Option_)
                    [System.Console]::Write($wrappedOptions[$CurrentIndex].display)
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
                [System.Console]::TreatControlCAsInput = $TreatControlCAsInput
                throw [System.OperationCanceledException]::new("User canceled the operation.")
            }
                
            elseif (
                $e.Key -EQ [System.ConsoleKey]::D -OR
                $e.Key -EQ [System.ConsoleKey]::RightArrow
            ) {
                $Index = ($Index + 1) % $wrappedOptions.Count
            }
            elseif (
                $e.Key -EQ [System.ConsoleKey]::A -OR
                $e.Key -EQ [System.ConsoleKey]::LeftArrow
            ) {
                $Index = ($Index + $wrappedOptions.Count - 1) % $wrappedOptions.Count
            }


            <#
                When a number is entered, select the corresponding option at the index.
            #>
            if (
                [System.Char]::IsDigit($e.KeyChar)
            ) {
                $enteredIndex = [System.Byte]::Parse($e.KeyChar) - 1
                $enteredIndex = [System.Math]::Max(0, $enteredIndex)

                if ($wrappedOptions.Count -GT $enteredIndex) {
                    $Index = $enteredIndex
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

                return $wrappedOptions[$Index].value
            }

        } while ($e.Key -NE [System.ConsoleKey]::Enter)

    }

    CLEAN {                
        # Make sure to always leave in any case function with a visible cursor again.
        [System.Console]::CursorVisible = $true 
        [System.Console]::TreatControlCAsInput = $TreatControlCAsInput
    }
}
