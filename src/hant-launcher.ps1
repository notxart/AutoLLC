# Progress Bar (SilentlyContinue to avoid slowing down Invoke-WebRequest)
$ProgressPreference = "SilentlyContinue"

# Function to wait for any key press
function Wait-AnyKey {
    [System.Console]::WriteLine("Press any key to continue...")
    [System.Console]::ReadKey($true) > $null
}

# Function to remove old installation files
function Remove-OldInstallation {
    param (
        [string]$gamePath
    )
    $itemsToRemove = @(
        "BepInEx",
        "dotnet",
        "AutoLLC.history",
        "doorstop_config.ini",
        "winhttp.dll",
        ".doorstop_version",
        "changelog.txt"
    )
    foreach ($item in $itemsToRemove) {
        $fullPath = Join-Path -Path $gamePath -ChildPath $item
        if (Test-Path $fullPath) {
            try {
                if (Test-Path $fullPath -PathType Container) {
                    Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                }
                else {
                    Remove-Item -Path $fullPath -Force -ErrorAction Stop
                }
            }
            catch {
                Write-Error "Failed to remove $fullPath : $_"
                Wait-AnyKey
                exit 1
            }
        }
    }
}

# Function to get Steam installation path from registry
function Get-SteamPath {
    try {
        $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
        if (-Not (Test-Path -Path $steamPath)) {
            throw "Steam installation path not found."
        }
        return $steamPath
    }
    catch {
        Write-Error $_.Exception.Message
        Wait-AnyKey
        exit 1
    }
}

# Show installation menu
Write-Host "========================================"
Write-Host " Limbus Company Chinese Patch Installer"
Write-Host "========================================"
Write-Host "1. Normal Installation (Default - Press Enter or 1)"
Write-Host "2. Force Reinstall"
Write-Host "3. Exit Installer (Press 3 or Q)"
Write-Host ""

$choice = $null
[System.Console]::Write("Please select an option (1/2/3): ")
do {
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    switch ($key.VirtualKeyCode) {
        13 { $choice = "1" }  # Code 13 = Enter
        49 { $choice = "1" }  # Code 49 = 1
        50 { $choice = "2" }  # Code 50 = 2
        51 { $choice = "3" }  # Code 51 = 3
        81 { $choice = "3" }  # Code 81 = Q
        97 { $choice = "1" }  # Code 97 = Num 1
        98 { $choice = "2" }  # Code 98 = Num 2
        99 { $choice = "3" }  # Code 99 = Num 3
        default {
            [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop)
            [System.Console]::Write("Invalid input. Please enter 1, 2 or 3: ")
        }
    }
} while ($choice -notin @("1", "2", "3"))
[System.Console]::Write("`n`n")

# Handle exit choice
if ($choice -eq "3") {
    Write-Host "Installation canceled by user."
    Wait-AnyKey
    exit 0
}

# Read Steam library configuration
$libraryFoldersPath = Join-Path $(Get-SteamPath) "steamapps\libraryfolders.vdf"
$libraryFoldersContent = Get-Content -Raw $libraryFoldersPath
$libraryFolders = [regex]::Matches($libraryFoldersContent, '"path"\s+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }

# Find game installation path
$gamePath = $null
foreach ($folder in $libraryFolders) {
    $manifestPath = Join-Path $folder "steamapps\common\Limbus Company"
    if (Test-Path $manifestPath) {
        $exePath = Join-Path $manifestPath "LimbusCompany.exe"
        if (Test-Path $exePath) {
            $gamePath = Resolve-Path -Path $manifestPath
            break
        }
    }
}
if (-Not ($gamePath)) {
    Write-Error "Limbus Company installation directory was not found, or LimbusCompany.exe is missing from the directory."
    Wait-AnyKey
    exit 1
}

# Handle reinstall choice
if ($choice -eq "2") {
    Write-Host "`nRemoving previous installation..."
    Remove-OldInstallation -gamePath $gamePath
    Write-Host "Old files cleaned successfully.`n"
}

Write-Host "Limbus Company game installation path found, Traditional Chinese language pack will be installed at: $gamePath"

# Define resource targets
$apiUrls = @(
    "BepInEx/BepInEx",
    "LimbusTraditionalMandarin/font",
    "LimbusTraditionalMandarin/storyline"
)
$targets = @(
    "https.*BepInEx-Unity.IL2CPP-win-x64-6.*.zip",
    "https.*LTM_font.*.zip",
    "https.*LTM_.*.zip"
)
$historyFilePath = Join-Path $gamePath "AutoLLC.history"

# History file functions
function Read-HistoryFile {
    $historyHashTable = @{}
    if (Test-Path $historyFilePath) {
        $historyData = Get-Content -Path $historyFilePath -Raw | ConvertFrom-Json
        foreach ($key in $historyData.PSObject.Properties.Name) {
            $historyHashTable[$key] = $historyData.$key
        }
    }
    return $historyHashTable
}

function Write-HistoryFile {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$record
    )
    $record | ConvertTo-Json -Compress | Set-Content -Path $historyFilePath
}

$history = Read-HistoryFile

# Main installation process
for ($i = 0; $i -lt $apiUrls.Length; $i++) {
    Write-Host "Updating module: $($apiUrls[$i])"

    $apiUrl = "https://api.github.com/repos/$($apiUrls[$i])/releases"
    $target = $targets[$i]

    try {
        # Obtain the latest version of JSON data through Invoke-WebRequest
        $response = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing
        $json = $response.Content | ConvertFrom-Json

        # Search URLs with .zip using regex
        foreach ($asset in $json.assets) {
            if ($asset -match $target) {
                $url = $asset.browser_download_url
                break
            }
        }
    }
    catch {
        Write-Warning "An error occurred while obtaining GitHub API data, possibly due to frequent usage of the script.`nIf you have already installed the Traditional Chinese language pack, please ignore this warning and press any key to continue; if you haven't installed it, please try again later!"
        Wait-AnyKey
        break
    }

    # Check if the current URL matches the one in the history file
    if ($history.ContainsKey($apiUrl) -and $history[$apiUrl] -eq $url) {
        continue
    }

    # Download, unzip, and remove compressed files
    $fileName = Join-Path $env:TEMP "limbus_i18n_$i.zip"
    (New-Object Net.WebClient).Downloadfile($url, $fileName)
    try {
        # Handle the root directory problem that the ZIP may contain
        $tempExtractDir = Join-Path $env:TEMP "limbus_extract_$i"
        New-Item -ItemType Directory -Path $tempExtractDir -Force | Out-Null

        Expand-Archive -Path $fileName -DestinationPath $tempExtractDir -Force -ErrorAction Stop

        # Merge the decompressed content into the game directory
        Get-ChildItem -Path $tempExtractDir | Copy-Item -Destination $gamePath -Recurse -Force
    }
    catch {
        Remove-Item $fileName -ErrorAction SilentlyContinue
        Remove-Item $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Error "ZIP extraction failed: $_"
        Wait-AnyKey
        exit 1
    }
    finally {
        Remove-Item $fileName -ErrorAction SilentlyContinue
        Remove-Item $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Update the history with the new URL
    $history[$apiUrl] = $url
    if (($i + 1) -eq $apiUrls.Length) { Write-HistoryFile -record $history }
}

# Launch game
if (-Not (Get-Process -Name "steam" -ErrorAction SilentlyContinue)) {
    Start-Process "steam://rungameid/1973530"
}
else {
    Start-Process -FilePath (Join-Path $gamePath "LimbusCompany.exe")
}
