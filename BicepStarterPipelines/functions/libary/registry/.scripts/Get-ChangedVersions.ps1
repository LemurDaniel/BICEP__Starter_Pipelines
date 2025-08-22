function Get-ChangedVersions {
    param(
        <#
        [Required]
        Specifies the name of the event to process (e.g., 'push', 'pull_request').
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $EventName,

        <#
        [Required]
        Specifies the folder prefix to filter or target specific directories.
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $FolderPrefix
    )

    if ($EventName -EQ "pull_request") {
        git fetch --all
        $gitChanges = git --no-pager diff --name-only origin/master...origin/dev
    }
    elseif ($EventName -EQ "push") {
        git fetch --all
        git checkout master
        git pull origin master
        $gitChanges = git --no-pager show --name-only --first-parent origin/master
    }
    else {
        Write-Host "Unsupported event: $EventName"
        return
    }

    $gitChanges = $gitChanges -split "`n"

    $changedVersions = $gitChanges 
    | Where-Object { 
        $_ -like "*/version.json" 
    } 
    | Where-Object { 
        Test-Path $_ 
    } 
    | ForEach-Object { 
        $_.Replace($FolderPrefix, "").Replace('version.json', "") 
    }

    $changedVersionsJson = $changedVersions | ConvertTo-Json -Compress -AsArray

    # Debug output
    Write-Host "Module Folder: $FolderPrefix"
    Write-Host "Version.json changes: $changedVersionsJson"

    return [PSCustomObject]@{
        FolderPrefix = $FolderPrefix
        ModuleChanges = $changedVersionsJson
    }

}