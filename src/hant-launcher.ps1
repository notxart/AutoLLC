# Progress Bar (SilentlyContinue to avoid slowing down Invoke-WebRequest)
$ProgressPreference = "SilentlyContinue"

# Function to wait for any key press
function Wait-AnyKey {
    [System.Console]::WriteLine("Press any key to continue...")
    [System.Console]::ReadKey($true) > $null
}

# Function to get Steam installation path from registry
function Get-SteamPath {
    try {
        $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
        if (-Not (Test-Path -Path $steamPath)) {
            throw "Steam path not found, script terminated."
        }
        return $steamPath
    }
    catch {
        Write-Error $_.Exception.Message
        Wait-AnyKey
        exit 1
    }
}

# Read the "libraryfolders.vdf" file to get all Steam library directories
$libraryFoldersPath = Join-Path $(Get-SteamPath) "steamapps\libraryfolders.vdf"
$libraryFoldersContent = Get-Content -Raw $libraryFoldersPath
$libraryFolders = [regex]::Matches($libraryFoldersContent, '"path"\s+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }

# Find the installation path of the game Limbus Company
$gamePath = $null
foreach ($folder in $libraryFolders) {
    $manifestPath = Join-Path $folder "steamapps\common\Limbus Company"
    if (Test-Path $manifestPath) {
        $gamePath = Resolve-Path -Path $manifestPath
        break
    }
}
if (-Not ($gamePath)) {
    Write-Error "Limbus Company game installation directory not found, script terminated."
    Wait-AnyKey
    exit 1
}
Write-Host "Limbus Company game installation directory found, Traditional Chinese language pack will be installed at: $gamePath"

# Check if the necessary module 7Zip4Powershell is installed
try {
    if (-Not (Get-Command -Module 7Zip4Powershell -ErrorAction SilentlyContinue)) {
        Install-Module -Name 7Zip4Powershell -Scope CurrentUser -Force
    }
}
catch {
    Write-Error "Unable to install required module: 7Zip4Powershell, script terminated."
    Wait-AnyKey
    exit 1
}

# Define GitHub API URLs and download targets
$apiUrls = @(
    "LocalizeLimbusCompany/BepInEx_For_LLC",
    "SmallYuanSY/LLC_ChineseFontAsset",
    "SmallYuanSY/LocalizeLimbusCompany_TW"
)
$targets = @(
    "https.*BepInEx-IL2CPP-x64.*.7z",
    "https.*chinesefont_BIE.*.7z",
    "https.*LimbusLocalize_BIE.*.7z"
)

# Define the path to the history file
$historyFilePath = Join-Path $gamePath "AutoLLC.history"

# Define functions for reading/writing history file
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

# Read the history file
$history = Read-HistoryFile

# Iterate through downloading and decompressing each target
for ($i = 0; $i -lt $apiUrls.Length; $i++) {
    $apiUrl = "https://api.github.com/repos/$($apiUrls[$i])/releases/latest"
    $target = $targets[$i]

    try {
        # Obtain the latest version of JSON data through Invoke-WebRequest
        $response = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing
        $json = $response.Content | ConvertFrom-Json

        # Search URLs with .7z using regex
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
    $fileName = Join-Path $env:TEMP "limbus_i18n_$i.7z"
    Invoke-WebRequest $url -OutFile $fileName
    try {
        Expand-7Zip -ArchiveFileName $fileName -TargetPath $gamePath -ErrorAction Stop
    }
    catch {
        Remove-Item $fileName
        Write-Error "7Zip decompression failed, script terminated."
        Wait-AnyKey
        exit 1
    }
    Remove-Item $fileName

    # Update the history with the new URL
    $history[$apiUrl] = $url
    if (($i + 1) -eq $apiUrls.Length) { Write-HistoryFile -record $history }
}

# Start the game
if (-Not (Get-Process -Name "steam" -ErrorAction SilentlyContinue)) {
    Start-Process "steam://rungameid/1973530"
}
else {
    Start-Process -FilePath (Join-Path $gamePath "LimbusCompany.exe")
}
