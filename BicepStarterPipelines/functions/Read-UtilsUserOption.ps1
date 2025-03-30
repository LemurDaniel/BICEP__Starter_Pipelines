function Read-UtilsUserOption {
    <#
    .SYNOPSIS
    Opens an interactive single line menue for user confirmation.

    .DESCRIPTION
    Opens an interactive single line menue for user confirmation.

    .OUTPUTS
    The selected option by the user.



    
    .EXAMPLE

    Provides two options asking for yes or no. Will return $true on yes and $false on no.

    PS> Read-UtilsUserOption


    .EXAMPLE

    Provides the basic prompt with a custom message.

    PS> Read-UtilsUserOption "Confirm: "

 
    .EXAMPLE

    PS> Present a simple prompt with two selections and an identation:

    Read-UtilsUserOption -Prompt "Confirm: `n" -Options "A", "B", "C" -i 2


    .EXAMPLE

    Present options via pipeline input.

    PS>  "Option A", "Option B", "Option C" | Read-UtilsUserOption -Prompt "Choose:  " -i 2


    .EXAMPLE

    Selects between two files, displaying the name and returning the full path.

    PS> Get-ChildItem -File 
        | Select-Object -First 2 
        | Read-UtilsUserOption -Display name -Return FullName

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
        $_Color_Reset_ = $PSStyle.Reset
        $_Color_Option_ = '' + $transformedColors.Option.ForeGround + $transformedColors.Option.BackGround
        $_Color_Selected_ = '' + $transformedColors.Selected.ForeGround + $transformedColors.Selected.BackGround
        $_Color_Prompt_ = '' + $transformedColors.Prompt.ForeGround + $transformedColors.Prompt.BackGround


        <#
            Setting up user prompt and displayed options.
        #>
        $userPrompt = (" " * $Indendation) + $Prompt
        $selectedIndex = $DefaultIndex
        $marginSpace = " " * $Margin

        if ($PSBoundParameters.ContainsKey('DefaultValue')) {
            $selectedIndex = ($Options.display ?? $Options).IndexOf($DefaultValue)

            if ($selectedIndex -LT 0) {
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
            return $Options | Read-UtilsUserOption @PSBoundParameters
        }


        <#
            Convert all provided entries to a list of object:
            - Strings and ValueTypes: String or Value is displayed on screen as is.
            - Powershell Objects:     A property from the object is display on screen, to identify the object.
        #>

        $optionWrapper = $null

        <#
            If the user provided a string or value type,
            we wrap it in a hashtable with the properties 'display' and 'value'.
        #>
        if (
            $Options -IS [System.String] -OR 
            $Options -IS [System.ValueType]
        ) {
            $optionWrapper = @{
                display = $Options
                value   = $Options
            }
        }

        <#
            If the user provided a hashtable or object,
            we add it and check if the hashtable is valid.
        #>
        else {
            if (
                -NOT [System.String]::IsNullOrEmpty($Return) -AND
                [System.String]::IsNullOrEmpty($Options."$Return")    
            ) {
                throw [System.InvalidOperationException]::new("`nThe provided object does not contain a property with the name '$Return'.`n$Options")
            }

            if (
                -NOT [System.String]::IsNullOrEmpty($Display) -AND
                [System.String]::IsNullOrEmpty($Options."$Display")    
            ) {
                throw [System.InvalidOperationException]::new("`nThe provided object does not contain a property with the name '$Display'.`n$Options")
            }

            $optionWrapper = @{
                display = $Options."$display"
                value   = $Options."$return" ?? $Options
            }
        }


        if (
            $optionWrapper.display.Contains("`n")
        ) {
            $optionWrapper.display = $optionWrapper.display.Replace("`n", "")
            Write-Warning "Linebreaks are only allowed in the Prompt. Any linebreak in the option will be removed."
        }
     
        $wrappedOptions += $optionWrapper

        if ($Options.default -EQ $true) {
            $selectedIndex = $wrappedOptions.Count - 1
        }

    }



    END {

        if (-NOT $PSCmdlet.MyInvocation.ExpectingInput) {
            return
        }
        
        [System.Console]::Write($_Color_Prompt_)
        [System.Console]::Write($userPrompt)
        [System.Console]::Write($_Color_Reset_)

        # If the prompt contains a linebreak, apply the indentation again to the next line.
        if ($userPrompt.Contains("`n")) {
            [System.Console]::Write((" " * $Indendation))
        }

        # Save existing value and change it to true.
        $TreatControlCAsInput = [System.Console]::TreatControlCAsInput
        [System.Console]::TreatControlCAsInput = $true
        [System.Console]::CursorVisible = $false

        # Save curors position where the options will be displayed.
        $cursorX = [System.Console]::GetCursorPosition().Item1
        $cursorY = [System.Console]::GetCursorPosition().Item2


        do {

            <#
                Sets the cursor position to the start of the line.

                Then draws all options in a single line.
            #>
            [System.Console]::SetCursorPosition($cursorX, $cursorY)

            for ($index = 0; $index -LT $wrappedOptions.Count; $index++) {

                
                # Don't write the margin space:
                # - before the first option
                # - after the last option
                if ($index -GT 0 -AND $index -LT $wrappedOptions.Count) {
                    [System.Console]::Write($marginSpace)
                }

                if ($index -EQ $selectedIndex) {
                    [System.Console]::Write($_Color_Selected_)
                    [System.Console]::Write($wrappedOptions[$index].display)
                    [System.Console]::Write($_Color_Reset_)
                }
                else {
                    [System.Console]::Write($_Color_Option_)
                    [System.Console]::Write($wrappedOptions[$index].display)
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
                $selectedIndex = ($selectedIndex + 1) % $wrappedOptions.Count
            }
            elseif (
                $e.Key -EQ [System.ConsoleKey]::A -OR
                $e.Key -EQ [System.ConsoleKey]::LeftArrow
            ) {
                $selectedIndex = ($selectedIndex + $wrappedOptions.Count - 1) % $wrappedOptions.Count
            }


            <#
                When a number is entered, select the corresponding optiona at the index.
            #>
            if (
                [System.Char]::IsDigit($e.KeyChar)
            ) {
                $enteredIndex = [System.Byte]::Parse($e.KeyChar) - 1
                $enteredIndex = [System.Math]::Max(0, $enteredIndex)

                if ($wrappedOptions.Count -GE $enteredIndex) {
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

                return $wrappedOptions[$selectedIndex].value
            }

        } while ($e.Key -NE [System.ConsoleKey]::Enter)

    }

    CLEAN {                
        # Make sure to always leave in any case function with a visible cursor again.
        [System.Console]::CursorVisible = $true 
        [System.Console]::TreatControlCAsInput = $TreatControlCAsInput
    }
}
