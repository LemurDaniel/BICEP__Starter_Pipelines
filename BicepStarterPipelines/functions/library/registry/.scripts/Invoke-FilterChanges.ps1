function Invoke-FilterChanges {
    param(
        <#
        [Required]
        Specifies all changes to filter or target specific directories.
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Changes,

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

    $Changes = $Changes -split "`n"

    $changedVersions = $Changes 
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