if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an administrator. Please restart PowerShell as Administrator."
    exit
}

$AppDataPath = "$env:USERPROFILE\AppData"
$DesktopPath = "$env:USERPROFILE\Desktop"
$CopyFolderPath = Join-Path -Path $DesktopPath -ChildPath "AppDataCopy"
$ZipFilePath = Join-Path -Path $DesktopPath -ChildPath "AppDataBackup.zip"

if (-not (Test-Path $AppDataPath)) {
    Write-Error "AppData folder not found at $AppDataPath."
    exit
}

Write-Host "Starting to copy AppData folder to Desktop..." -ForegroundColor Cyan

try {
    if (Test-Path $CopyFolderPath) {
        Remove-Item -Path $CopyFolderPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $CopyFolderPath | Out-Null

    $files = Get-ChildItem -Path $AppDataPath -Recurse -Force -ErrorAction SilentlyContinue
    $totalFiles = $files.Count
    $currentFile = 0

    foreach ($file in $files) {
        $currentFile++
        $relativePath = $file.FullName.Substring($AppDataPath.Length + 1)
        $destinationPath = Join-Path -Path $CopyFolderPath -ChildPath $relativePath

        try {
            if ($file.PSIsContainer) {
                New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                Write-Host "Created directory: $relativePath" -ForegroundColor Yellow
            } else {
                Copy-Item -Path $file.FullName -Destination $destinationPath -Force -ErrorAction Stop
                Write-Host "Copied file: $relativePath" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Skipping locked or in-use file: $relativePath" -ForegroundColor Red
        }

        Write-Progress -Activity "Copying Files" -Status "Processing: $relativePath" -PercentComplete (($currentFile / $totalFiles) * 100)
    }

    Write-Host "Copy completed. All files from AppData copied to: $CopyFolderPath" -ForegroundColor Green

    Write-Host "Starting to compress copied AppData folder..." -ForegroundColor Cyan

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    [System.IO.Compression.ZipFile]::CreateFromDirectory($CopyFolderPath, $ZipFilePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

    Write-Host "Compression completed. Zip file saved at: $ZipFilePath" -ForegroundColor Green

    Remove-Item -Path $CopyFolderPath -Recurse -Force
    Write-Host "Temporary copied folder removed." -ForegroundColor Green

} catch {
    Write-Error "An error occurred: $_"
}
