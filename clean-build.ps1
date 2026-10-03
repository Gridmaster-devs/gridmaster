<#
.SYNOPSIS
Removes files from each subdirectory of grid-master-app\build while keeping
the directory structure and .gitignore files.

.EXAMPLE
.\clean-build.ps1
Removes the files.

.EXAMPLE
.\clean-build.ps1 -WhatIf
Lists the files that would be removed without deleting them.
#>
Param(
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$buildRoot = Join-Path $scriptRoot 'grid-master-app\build'

if (-not (Test-Path $buildRoot)) {
    Write-Error "Build directory not found: $buildRoot"
    exit 1
}

if ($WhatIf) {
    Write-Host "WhatIf: Listing files that would be removed under each subdirectory of $buildRoot (preserving directories and .gitignore files)..."
}
else {
    Write-Host "Cleaning files under each subdirectory of $buildRoot (preserving directories and .gitignore files)..."
}

Get-ChildItem -Path $buildRoot -Directory -Force | ForEach-Object {
    $sub = $_.FullName
    if ($WhatIf) {
        Write-Host "Would clean: $sub"
    }
    else {
        Write-Host "Cleaning: $sub"
    }

    Get-ChildItem -Path $sub -Recurse -Force -File |
        Where-Object { $_.Name.ToLower() -ne '.gitignore' } |
        ForEach-Object {
            if ($WhatIf) {
                Write-Host "Would remove: $($_.FullName)"
            }
            else {
                try {
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to remove $($_.FullName): $($_.Exception.Message)"
                }
            }
        }
}

Write-Host "Done."
