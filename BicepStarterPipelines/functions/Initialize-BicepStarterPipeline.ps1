function Initialize-BicepStarterPipeline {
    <#
    .SYNOPSIS
    Initializes a directory with files from a predefined template library.

    .DESCRIPTION
    Generates files based on a selected template from a library of templates into a directory. 


    .OUTPUTS
    

    .LINK
    
    #>
    [Alias('bicep-init')]
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                return Get-ChildItem -Directory
                | Where-Object -Property Name -Like "*$wordToComplete*"
                | Select-Object -ExpandProperty Name
            }
        )]
        [System.IO.DirectoryInfo]
        $Target = '.',

        [Parameter()]
        [ValidateSet('Normal Deployment', 'Deployment Stack')]
        [System.String]
        $Method = $null,

        [Parameter()]
        [ValidateSet('Resource Group', 'Subscription')]
        [System.String]
        $Scope = $null,

        [Parameter()]
        [ValidateSet('PowerShell', 'Azure CLI')]
        [System.String]
        $Script = $null,

        [Parameter()]
        [ValidateSet('Github', 'Azure DevOps')]
        [System.String]
        $Pipeline = $null
    )

    <#

        Helper script for copying files.

    #>
    function Copy-Helper {

        param(
            [System.IO.DirectoryInfo] $sourceDir,
            [System.IO.DirectoryInfo] $targetDir
        )
        
        $sourceDirs = Get-ChildItem -Recurse -Directory -Path $sourceDir
        foreach ($dir in $sourceDirs) {
            $relativePath = Resolve-Path -Relative -Path $dir.FullName -RelativeBasePath $sourceDir
            $templateDir = [System.IO.DirectoryInfo]::new("$targetDir/$relativePath")
    
            if (-NOT $templateDir.Exists) {
                $null = $templateDir.Create()
            }
        }

        $sourceFiles = Get-ChildItem -Recurse -File -Path $sourceDir
        foreach ($file in $sourceFiles) {
            $relativePath = Resolve-Path -Relative -Path $file.FullName -RelativeBasePath $sourceDir
            $templateFile = [System.IO.FileInfo]::new("$targetDir/$relativePath")
    
            if ($templateFile.Exists) {
                throw [System.InvalidOperationException]::new("$relativePath already exists!")
            }
            else {
                $file.CopyTo($templateFile)
            }
        }

    }

    <#

        Initialize all relevant variables:
        - targetDir where to copy files
        - sourceDir for the template
        - commonDir and metaPsd for common templates

    #>

    $sourceDir = [System.IO.DirectoryInfo]::new("$PSScriptRoot/libary/")

    $rootDir = [System.IO.DirectoryInfo]::new("$sourceDir/root")
    $tempDir = [System.IO.DirectoryInfo]::new("$sourceDir/staging")
    $initPs1 = [System.IO.FileInfo]::new("$sourceDir/init.ps1")


    $targetDir = $null

    if ([System.IO.Path]::IsPathFullyQualified($Target)) {
        $targetDir = [System.IO.DirectoryInfo]::new($Target)
    }
    else {
        $targetDir = [System.IO.DirectoryInfo]::new("$((Get-Location).Path)/$Target")
    }

    if (-NOT $targetDir.Exists) {
        $targetDir.Create()
    }

    <#
    
        Performing copy operations
    
    #>

    if ($tempDir.Exists) {
        $tempDir.Delete($true)
    }

    $tempDir.Create()

    try {
        $null = Copy-Helper -sourceDir $rootDir -targetDir $tempDir

        $initParams = @{
            stagingDir = $tempDir
            Target     = $Target
            Method     = $Method
            Scope      = $Scope
            Script     = $Script
            Pipeline   = $Pipeline
        }

        . $initPs1.FullName @initParams

        if ($IsWindows) {
            <#
                This is the final copy operation from staging to the user directory
                Shows the windows dialog in case of duplicate files.
            #>
            $destination = New-Object -ComObject "Shell.Application"
            $destination = $destination.NameSpace($targetDir.FullName)
            $destination.CopyHere("$tempDir/*")
        }
        else {
            Copy-Item -Path "$tempDir/*" -Recurse -Destination $targetDir -ErrorAction Continue
            Get-ChildItem -Path $tempDir -Hidden | Copy-Item -Recurse -Destination $targetDir -ErrorAction SilentlyContinue
        }
    }
    finally {
        $tempDir.Delete($true)
    }
}