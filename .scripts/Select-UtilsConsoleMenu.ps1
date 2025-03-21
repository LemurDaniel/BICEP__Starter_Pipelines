function Select-UtilsConsoleMenu {
    <#
    .SYNOPSIS
    Write a Menue to the Console with interactive selection.

    .DESCRIPTION
    Write a Menue to the Console with interactive selection.

    Supports several Pages.
        => Switchable via Left- and Right-Keyboard Keys.

    Chosen Element is Highlighted.
        => Switchable via Up- and Down-Keyboard Keys.

    Wirting a Text highlights every entry with the specifed text.
        => Pressing Backspace will remove the last letter from the text.

    .OUTPUTS
    The Selected Item.



    
    .EXAMPLE

    Select a File to open in the Current Path:
    
    PS> $selected = Get-ChildItem -File | Select-UtilsConsoleMenu -Display name


    .EXAMPLE 

    Get color coded inputs: 

    PS> Get-ChildItem 
    | ForEach-Object `
        -Begin { $index = 0 } { `
            New-UtilsEscapeSequence $_.Name -Colormode 24bit -Foreground ($index++ % 2 -EQ 0 ? "#00FFFF" : "#FFFF00") 
        } 
    | Select-UtilsConsoleMenu

    .LINK
    
    #>

    

    [CmdletBinding()]
    param (
        # A list of options to choose from.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.Object]
        $Options,

        # The property to display in the menu. In case of a string, the string itself will be displayed.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        [Alias('Property')]
        $Display = 'display',

        # The description to display above the menu.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Description = 'Please Choose from the Menu:',

        # Custom color coding. Use ANSI-Color Codes.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $CustomColors = @{
            _highlightPage_   = $null
            _highlightSelect_ = $null
            _highlightSearch_ = $null
        }
    )

    BEGIN {
        # [System.Console]::WriteLine seems a bit more performent

        $ANSI = Get-UtilsEscapeCode -AsHashtable

        $_reset_ = $ANSI.graphics.RESET_ALL
        $_linebreak_ = $ANSI.general.LINE_FEED
        $_highlightPage_ = $ANSI.COLOR_CODES['BRIGHT_BLACK'].FOREGROUND + $ANSI.COLOR_CODES['WHITE'].BACKGROUND
        $_highlightSelect_ = $ANSI.COLOR_CODES['BRIGHT_WHITE'].FOREGROUND + $ANSI.COLOR_CODES['BRIGHT_BLACK'].BACKGROUND
        $_highlightSearch_ = $ANSI.COLOR_CODES['CYAN'].FOREGROUND  #+ $ANSI.COLOR_CODES['BLACK'].BACKGROUND

        $_highlightPage_ = $CustomColors._highlightPage_ ?? $_highlightPage_
        $_highlightSelect_ = $CustomColors._highlightSelect_ ?? $_highlightSelect_
        $_highlightSearch_ = $CustomColors._highlightSearch_ ?? $_highlightSearch_

        $_colorUnevenLine_ = $ANSI.COLOR_CODES['WHITE'].FOREGROUND
        $_colorEvenLine_ = $ANSI.COLOR_CODES['BRIGHT_WHITE'].FOREGROUND

        $reservedLines = 8 # Reserved Lines for Description, Page-Count, Search-String, etc.
        $initialSelectionSize = [System.Math]::Max($Host.UI.RawUI.WindowSize.Height, 10)
        $selectionIndexOnPage = 0
        $currentPage = 0

        $searchString = ''
        $prefixSelected = ' => '
        $prefixNonSelected = '    '
        $shortendSuffix = '... '

        $reservedWidth = [System.Math]::Max($prefixSelected.length, $prefixNonSelected.length) + 4
        $initialSelectionWitdh = $Host.UI.RawUI.WindowSize.Width - $reservedWidth - $shortendSuffix.Length

        $SelectionOptions = @()
    }

    PROCESS {
        $SelectionOptions += $Options 
        | Where-Object { $_ -NE $null }
        | ForEach-Object {
            if ($_ -IS [System.String] -OR $_ -IS [System.ValueType]) {
                return @{
                    name         = $_
                    returnValue  = $_
                    ignoreSearch = $_.ignoreSearch ?? $false
                }
            }
            else {
                return @{
                    name         = $_."$Display"
                    returnValue  = $_
                    ignoreSearch = $_.ignoreSearch ?? $false
                }
            }
        }
    }

    END {

        try {

            do {
                [System.Console]::CursorTop = 0
                [System.Console]::CursorVisible = $false
                Clear-Host
        
                if (-NOT [System.String]::IsNullOrEmpty($Description)) {
                    $DescriptionEndocded = "`e[1m$Description`e[0m`n"
                    [System.Console]::WriteLine($DescriptionEndocded)
                }

                # Define filtered options as an array, to avoid powershell unpacking single array element.
                [System.Object[]]$filteredOptions = $SelectionOptions
                | Where-Object {
                    $_.ignoreSearch -EQ $true -OR $_.name -ILIKE "*$searchString*"
                }

                # Do page and selection calculations.
                $maxSelectionsPerPage = $initialSelectionSize - $reservedLines
                $totalCountOfPages = [System.Math]::Ceiling($filteredOptions.Count / $maxSelectionsPerPage)
                $lastPageMaxIndex = $filteredOptions.Count % $maxSelectionsPerPage - 1

                # Fix if current Page is out-of-range.
                $currentPage = $currentPage -GE $totalCountOfPages ? $totalCountOfPages - 1 : $currentPage

                # Caluclation for current Page.
                $isLastPage = $currentPage -EQ ($totalCountOfPages - 1)
                $selectionPageOffset = $currentPage * $maxSelectionsPerPage

                # This is a special case, when swapping to the last page.
                # The selection index from the previous page may exceed the last page.
                if ($selectionIndexOnPage -GT $lastPageMaxIndex -AND $isLastPage) {
                    $selectionIndexOnPage = $lastPageMaxIndex
                }

                $index = 0
                $filteredOptions 
                | Select-Object -Skip $selectionPageOffset 
                | Select-Object -First $maxSelectionsPerPage 
                | ForEach-Object {

                    $displayedText = $_.Name
                    $_colorText_ = $index % 2 -EQ 0 ? $_colorEvenLine_ : $_colorUnevenLine_

                    # This shorthens any option to not exceed the terminal width.
                    # Dynamic resizing of the terminal is NOT taken into account, therefore will fail in that case!
                    if ($displayedText.Length -GT $initialSelectionWitdh) {
                        $maximumLineLength = [System.Math]::Min($_.Name.length, $initialSelectionWitdh)
                        $displayedText = $_.Name.Substring(0, $maximumLineLength)
                        $displayedText = $displayedText + $shortendSuffix
                    }
                
                    # Draws the selected option as highlighted text.
                    if ($index -EQ $selectionIndexOnPage) {
                        $displayedText = $prefixSelected + $_highlightSelect_ + $displayedText + $_reset_
                    } 

                    # This draws any normal appearing text.
                    elseif (-NOT ($displayedText -ILIKE "*$searchString*") ) {
                        $displayedText = $prefixNonSelected + $_colorText_ + $displayedText + $_reset_
                    }

                    # This highlights the part of each option that matches the search string.
                    else {
                        $startIndex = $displayedText.toLower().IndexOf($searchString.toLower())
                        $startIndex = [System.Math]::Max($startIndex, 0)
                        
                        $beforeHighlight = $displayedText.Substring(0, $startIndex)
                        $highlightedPart = $displayedText.Substring($startIndex, [System.Math]::Max($searchString.Length, 0))
                        $afterHighlight = $displayedText.Substring($startIndex + $searchString.Length)
                        $displayedText = @(
                            $prefixNonSelected, 
                            $_colorText_ + $beforeHighlight + $_reset_ ,
                            $_highlightSearch_ + $highlightedPart + $_reset_, 
                            $_colorText_ + $afterHighlight + $_reset_
                        ) -join ""
                    } 

                    [System.Console]::WriteLine($displayedText)

                    $index++
                }

                if ($totalCountOfPages -GT 0) {
                    $displayPageCount = $_linebreak_ + $_highlightPage_ + "$($currentPage+1)/$totalCountOfPages" + $_reset_
                    [System.Console]::Write($displayPageCount)
                }
    
                if ($searchString.Length -GT 0) {
                    $displaySearchData = [System.String]::Format("     Searching For: {0}'{1}'{2} | Remaining {3} of {4} Elements",
                        $_highlightSearch_, $SearchString, $_reset_, $filteredOptions.Count, $SelectionOptions.Count)
                    [System.Console]::Write($displaySearchData)
                }
                            
                [System.Console]::WriteLine()


                # Process and switch key presses
                $e = [System.Console]::ReadKey($true)
                if (
                    $e.Key -EQ [System.ConsoleKey]::Enter
                ) {
                    return $filteredOptions[$currentPage * $maxSelectionsPerPage + $selectionIndexOnPage].returnValue
                }
                elseif (
                    $e.Key -EQ [System.ConsoleKey]::Escape
                ) {
                    throw "Operation was Cancelled due to pressing '$($e.Key)'"
                }

                elseif (
                    $e.Key -EQ [System.ConsoleKey]::UpArrow 
                ) {
                    $selectionIndexOnPage = $selectionIndexOnPage - 1
                    if ($selectionIndexOnPage -LT 0) {
                        $currentPage = ($currentPage + $totalCountOfPages - 1) % $totalCountOfPages
                        $selectionIndexOnPage = $maxSelectionsPerPage - 1
                    }
                }
      
                elseif (
                    $e.Key -EQ [System.ConsoleKey]::DownArrow 
                ) {
                    $selectionIndexOnPage = $selectionIndexOnPage + 1
                    # Loop back to first index when maximum index downwards is reached
                    if (
                        $selectionIndexOnPage -GT $maxSelectionsPerPage - 1 -OR 
                        ($selectionIndexOnPage -GT $lastPageMaxIndex -AND $isLastPage)
                    ) {
                        $currentPage = ($currentPage + $totalCountOfPages + 1) % $totalCountOfPages
                        $selectionIndexOnPage = 0
                    }
                }
                
                elseif (
                    $e.Key -EQ [System.ConsoleKey]::LeftArrow 
                ) {
                    $currentPage = ($currentPage + $totalCountOfPages - 1) % $totalCountOfPages
                }
                elseif (
                    $e.Key -EQ [System.ConsoleKey]::RightArrow 
                ) {
                    $currentPage = ($currentPage + $totalCountOfPages + 1) % $totalCountOfPages
                }

                elseif (
                    $e.Key -EQ [System.ConsoleKey]::Backspace
                ) {
                    $searchString = $searchString.Substring(0, [System.Math]::Max(0, $searchString.Length - 1))
                }

                <#
                    This adds characters to the search string, when a keychar is provided. (Non-Null)
                    - Search string is only extended when remaining options > 0
                #>
                elseif ($null -NE $e.Key) {
                    $temporarySearchString = $searchString + $e.KeyChar
                    $remaining = $SelectionOptions 
                    | Where-Object -Property name -ILike "*$($temporarySearchString.ToLower())*"

                    $searchString = $remaining.Length -gt 0 ? $temporarySearchString  : $searchString
                }

                else {
                    $hint = ('**Use on of the Following Keys: (ArrowUP | ArrowDown | W | S | Enter)**' | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString
                    Write-Host 
                    Write-Host -ForegroundColor Magenta -Separator ' ' $hint, '... '
                    $null = [System.Console]::ReadKey($true)
                }

      
            } while ($e.KeyDownEvent.Key -NE [System.ConsoleKey]::Enter)

        }
        finally {
            [System.Console]::CursorVisible = $true
        } 
    }
}


