function Initialize-BicepTemplate {
    <#
    .SYNOPSIS
    Initializes a directory with files from a predefined template library.

    .DESCRIPTION
    Generates files based on a selected template from a library of templates into a directory. 
    
    #>
    [Alias('bicep-init')]
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.IO.DirectoryInfo]
        $Target = '.',

        [Parameter()]
        [ValidateSet('deployment', 'registry')]
        [System.String]
        $Template = 'deployment',

        [Parameter()]
        [System.Collections.Hashtable]
        $InitParameter
    )

    BEGIN {
        <#

        Helper script for copying files.

        This avoids problems with existing subdirectories on Copy-Item in the staging directory.
        By only creating subdirectories when they do not exist and then copying all files.

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
                    $null = $file.CopyTo($templateFile.FullName)
                }
            }

        }

        <#

        Initialize all relevant variables:
        - targetDir where to copy files
        - sourceDir for the template
        - commonDir for common files
        - initPs1 for the template initialization script

    #>
        $common = Get-Item -Path "$PSScriptRoot/libary/common"
        $initPs1 = Get-Item -Path "$PSScriptRoot/libary/$Template/init.ps1"
        $rootDir = Get-Item -Path "$PSScriptRoot/libary/$Template/root"

        if (-NOT [System.IO.Path]::IsPathFullyQualified($Target)) {
            $rootedPath = [System.IO.Path]::Join((Get-Location).Path, $Target)
            $Target = [System.IO.DirectoryInfo]::new($rootedPath)
        }

    }

    END {

        <#    
        
            All files are copied to the staging directory,
            where they are modified and then copied to the target directory.

        #>
        
        $tempDir = "{0}/bicep-staging/{1}" -f [System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid()
        $tempDir = New-Item -ItemType Directory -Path $tempDir

        Copy-Helper -sourceDir $rootDir -targetDir $tempDir
        Copy-Helper -sourceDir $common -targetDir $tempDir

        . $initPs1 @InitParameter -StagingDir $tempDir

        <#

            This is the final copy operation from staging to the user directory
            Uses the copy dialog for Windows and the shell copy for Linux.

        #>

        if (-NOT $Target.Exists) {
            $Target.Create()
        }
        
        if ($IsWindows) {
            $destination = New-Object -ComObject "Shell.Application"
            $destination = $destination.NameSpace($Target.FullName)
            $destination.CopyHere("$tempDir/*")
            return
        }

        try {
            Copy-Item -Path "$tempDir/*" -Recurse -Destination $Target
            Get-ChildItem -Path $tempDir -Hidden | Copy-Item -Recurse -Destination $Target -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host -ForegroundColor RED "`n`nTarget: $Target"
            Write-Host -ForegroundColor RED "`Files already exist in the target directory."
            $overwrite = Read-UtilsUserOption -Prompt "Overwrite?"

            if ($overwrite) {
                Copy-Item -Path "$tempDir/*" -Recurse -Force -Destination $Target
                Get-ChildItem -Path $tempDir -Hidden | Copy-Item -Recurse -Force -Destination $Target -ErrorAction SilentlyContinue
            }
            else {
                Write-Host -ForegroundColor RED "`n`nAborting the operation."
            }
        }
    }

    CLEAN {

        # This cleans up staging directory from directories older than 10 minutes.
        # In case of a crash, when the staging directory was not deleted.
        Get-ChildItem -Path $tempDir.Parent -Directory
        | Where-Object -Property CreationTime -LT (Get-Date).AddMinutes(-10)
        | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

        
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        # To make sure that the staging directory is definitly deleted.
        for ($tries = 1; $tries -LE 5; $tries++) {
            try {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue
            }
            catch {
                Start-Sleep -Milliseconds 50
            }
        }

    }
}