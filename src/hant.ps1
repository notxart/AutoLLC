# Debug
param([switch]$Debug = $false)
if ($Debug) { $DebugPreference = "Continue" }

# Function to get Steam installation path from registry
function Get-SteamPath {
    try {
        $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam").SteamPath
        if (-Not (Test-Path -Path $steamPath)) {
            throw "未找到有效的 Steam 路徑，腳本已終止。"
        }
        return $steamPath
    }
    catch {
        Write-Error $_.Exception.Message
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
    Write-Error "未找到遊戲 Limbus Company 的安裝目錄，腳本已終止。"
    exit 1
}
Write-Host "已找到遊戲 Limbus Company 的安裝目錄，繁體中文語言包將安裝於: $gamePath"

# Check if the necessary module 7Zip4Powershell is installed
try {
    if (-Not (Get-Command -Module 7Zip4Powershell -ErrorAction SilentlyContinue)) {
        Install-Module -Name 7Zip4Powershell -Scope CurrentUser -Force
    }
}
catch {
    Write-Error "無法安裝腳本必要模組: 7Zip4Powershell，腳本已終止。"
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
    # Progress Bar (SilentlyContinue to avoid slowing down Invoke-WebRequest)
    $ProgressPreference = "Continue"
    Write-Progress -Activity "Update Modules:" -Status "$($apiUrls[$i])" -PercentComplete (($i + 1) / $apiUrls.Length * 100)
    $ProgressPreference = "SilentlyContinue"

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
                Write-Debug "Download URL:`t$url"
                break
            }
        }
    }
    catch {
        Write-Warning "取得 GitHub API 資料時發生異常，很可能是頻繁使用該腳本導致。若您已安裝繁體中文語言包，請忽略該警告；若您尚未安裝，請稍後嘗試。詳細資訊:`n$_"
        break
    }

    # Check if the current URL matches the one in the history file
    if ($history.ContainsKey($apiUrl) -and $history[$apiUrl] -eq $url) {
        if ($Debug) { Write-Debug "Match API URL:`t$apiUrl" } else { continue }
    }

    # Download, unzip, and remove compressed files
    $fileName = "limbus_i18n_$i.7z"
    Invoke-WebRequest $url -OutFile $fileName
    Expand-7Zip -ArchiveFileName $fileName -TargetPath $gamePath
    if (-Not $Debug) { Remove-Item $fileName }

    # Update the history with the new URL
    $history[$apiUrl] = $url
    if (($i + 1) -eq $apiUrls.Length) { Write-HistoryFile -record $history }
}

# Start the game
Write-Host "Limbus Company 繁體中文語言包已順利安裝，即將為您啟動遊戲。"
if ($Debug) { exit 0 }
if (-Not (Get-Process -Name "steam" -ErrorAction SilentlyContinue)) {
    Start-Process "steam://rungameid/1973530"
}
else {
    Start-Process -FilePath (Join-Path $gamePath "LimbusCompany.exe")
}
