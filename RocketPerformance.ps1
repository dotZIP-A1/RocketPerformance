# ===================================================================
# INITIALIZATION & ADMIN CHECK
# ===================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    [System.Windows.Forms.MessageBox]::Show("This utility requires Administrator privileges to modify system settings. The script will now attempt to restart as Admin.", "Admin Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Ensure required UI components are loaded
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- THEME COLORS ---
$bgDark = [System.Drawing.Color]::FromArgb(255, 15, 15, 15)   # Deep Black/Gray
$bgPanel = [System.Drawing.Color]::FromArgb(255, 25, 25, 25)  # Slightly lighter for buttons
$accentBlue = [System.Drawing.Color]::DeepSkyBlue             # Neon Blue Accent

# --- FETCH & SET CUSTOM ICON ---
$iconUrl = "https://raw.githubusercontent.com/dotZIP-A1/RocketPerformance/main/icon.ico"
$iconPath = Join-Path $env:TEMP "rocket_icon.ico"
try {
    Invoke-WebRequest -Uri $iconUrl -OutFile $iconPath -UseBasicParsing -ErrorAction SilentlyContinue
} catch {}

# --- MAIN FORM CANVAS SETUP (720p) ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Rocket Performance Utility Tool"
$form.Width = 1280
$form.Height = 720
$form.BackColor = $bgDark
$form.ForeColor = $accentBlue
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

if (Test-Path $iconPath) {
    $form.Icon = New-Object System.Drawing.Icon($iconPath)
}

# Helper for Alerts
function Show-Msg ($text, $icon=[System.Windows.Forms.MessageBoxIcon]::Information) {
    [System.Windows.Forms.MessageBox]::Show($text, "Rocket Engine", [System.Windows.Forms.MessageBoxButtons]::OK, $icon)
}

# --- TAB CONTROL CONTAINER ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(1240, 630)
$tabControl.Location = New-Object System.Drawing.Point(12, 12)

$tabTweaks = New-Object System.Windows.Forms.TabPage
$tabTweaks.Text = "  System Tweaks  "
$tabTweaks.BackColor = $bgDark

$tabApps = New-Object System.Windows.Forms.TabPage
$tabApps.Text = "  Applications  "
$tabApps.BackColor = $bgDark

$tabMisc = New-Object System.Windows.Forms.TabPage
$tabMisc.Text = "  Misc / Config  "
$tabMisc.BackColor = $bgDark

# Attach individual tabs to main container
$tabControl.Controls.Add($tabTweaks)
$tabControl.Controls.Add($tabApps)
$tabControl.Controls.Add($tabMisc)
$form.Controls.Add($tabControl)

# Helper Function to quickly make uniform layout buttons with Black/Blue theme
function Add-ControlBtn($parentTab, $txt, $x, $y, $action) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $txt
    $btn.Size = New-Object System.Drawing.Size(350, 45) # Increased button size
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.BackColor = $bgPanel
    $btn.ForeColor = $accentBlue
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderColor = $accentBlue
    $btn.FlatAppearance.BorderSize = 1
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Add_Click($action)
    $parentTab.Controls.Add($btn)
}

# Helper Function to add headers to tab groups
function Add-TabHeader($parentTab, $txt, $x, $y) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $txt
    $lbl.Size = New-Object System.Drawing.Size(350, 25)
    $lbl.Location = New-Object System.Drawing.Point($x, $y)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = [System.Drawing.Color]::White
    $parentTab.Controls.Add($lbl)
}

# ===================================================================
# TAB 1: SYSTEM TWEAKS
# ===================================================================
# 3-Column Layout: X=30, X=430, X=830
Add-TabHeader $tabTweaks "Essential Optimizations" 30 30
Add-TabHeader $tabTweaks "Advanced Performance" 430 30
Add-TabHeader $tabTweaks "Power & Boot" 830 30

# -- Essential Logic --
$actRestorePoint = {
    Show-Msg "Creating System Restore Point..."
    Checkpoint-Computer -Description "RocketUtilRestore" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
    Show-Msg "System Restore Point Created Successfully!"
}
$actTelem = {
    Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
    Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName "Consolidator", "UsermodePowerServiceCdf", "DmClient", "DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Show-Msg "Telemetry & Customer Experience tasks permanently stopped."
}
$actTemp = {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Show-Msg "Temp Directories and Recycle Bin Emptied!"
}
$actMouse = {
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"
    Show-Msg "Mouse Acceleration killed. 1-to-1 processing baseline active!"
}

# -- Advanced Logic --
$actGameDVR = {
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -ErrorAction SilentlyContinue
    Show-Msg "Xbox GameDVR capture processes suppressed."
}

# -- Power Logic --
$actHighPerf = {
    powercfg -setactive SCHEME_MIN
    Show-Msg "Power Grid configured to High Performance."
}
$actUltPerf = {
    $ultGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    powercfg -duplicatescheme $ultGUID 2>&1 > $null
    powercfg -setactive $ultGUID
    Show-Msg "Ultimate Performance Plan spawned and forced active!"
}
$actHibernation = {
    powercfg.exe /hibernate off
    Show-Msg "Hibernation & Fast Startup Disabled (Saves SSD life and fixes boot bugs)."
}

# Column 1
Add-ControlBtn $tabTweaks "Create Restore Point (Safe First Step)" 30 70 $actRestorePoint
Add-ControlBtn $tabTweaks "Disable Telemetry Services" 30 130 $actTelem
Add-ControlBtn $tabTweaks "Deep Disk Cleanup & Temp Clear" 30 190 $actTemp
Add-ControlBtn $tabTweaks "Disable Mouse Acceleration" 30 250 $actMouse

# Column 2
Add-ControlBtn $tabTweaks "Disable Windows GameDVR" 430 70 $actGameDVR

# Column 3
Add-ControlBtn $tabTweaks "Activate Standard High Performance" 830 70 $actHighPerf
Add-ControlBtn $tabTweaks "Unlock Ultimate Performance Profile" 830 130 $actUltPerf
Add-ControlBtn $tabTweaks "Disable Hibernation / Fast Startup" 830 190 $actHibernation


# ===================================================================
# TAB 2: APPLICATIONS (WINGET SETUP MANAGERS)
# ===================================================================
Add-TabHeader $tabApps "Web Browsers" 30 30
Add-TabHeader $tabApps "System Utilities" 430 30
Add-TabHeader $tabApps "Removal & Media" 830 30

# -- App deployment blocks --
$actInsFox = { Show-Msg "Deploying Firefox..."; winget install --id Mozilla.Firefox -e --silent --accept-source-agreements; Show-Msg "Firefox Installed!" }
$actInsChrome = { Show-Msg "Deploying Chrome..."; winget install --id Google.Chrome -e --silent --accept-source-agreements; Show-Msg "Chrome Installed!" }
$actInsBrave = { Show-Msg "Deploying Brave..."; winget install --id Brave.Brave -e --silent --accept-source-agreements; Show-Msg "Brave Installed!" }

$actIns7z = { Show-Msg "Installing 7-Zip..."; winget install --id IgorPavlov.7-Zip -e --silent --accept-source-agreements; Show-Msg "7-Zip Installed!" }
$actInsWinRar = { Show-Msg "Installing WinRAR..."; winget install --id RARLab.WinRAR -e --silent --accept-source-agreements; Show-Msg "WinRAR Installed!" }
$actInsHWiNFO = { Show-Msg "Installing HWiNFO..."; winget install --id REALiX.HWiNFO -e --silent --accept-source-agreements; Show-Msg "HWiNFO Installed!" }

$actDelEdge = {
    taskkill /F /IM msedge.exe /T -ErrorAction SilentlyContinue
    Get-AppxPackage -AllUsers *MicrosoftEdge* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Show-Msg "Microsoft Edge app dependencies removed."
}
$actInsDiscord = { Show-Msg "Installing Discord..."; winget install --id Discord.Discord -e --silent --accept-source-agreements; Show-Msg "Discord Installed!" }

# Column 1
Add-ControlBtn $tabApps "Install Mozilla Firefox" 30 70 $actInsFox
Add-ControlBtn $tabApps "Install Google Chrome" 30 130 $actInsChrome
Add-ControlBtn $tabApps "Install Brave Browser" 30 190 $actInsBrave

# Column 2
Add-ControlBtn $tabApps "Install 7-Zip Extractor" 430 70 $actIns7z
Add-ControlBtn $tabApps "Install WinRAR Archiver" 430 130 $actInsWinRar
Add-ControlBtn $tabApps "Install HWiNFO Sensor Monitor" 430 190 $actInsHWiNFO

# Column 3
Add-ControlBtn $tabApps "Purge Microsoft Edge" 830 70 $actDelEdge
Add-ControlBtn $tabApps "Install Discord App" 830 130 $actInsDiscord


# ===================================================================
# TAB 3: MISC / CONFIG DEBLOAT
# ===================================================================
Add-TabHeader $tabMisc "Windows System Debloating" 30 30
Add-TabHeader $tabMisc "Network & Core Troubleshooting" 430 30

# -- Misc Custom Core Executions --
$actDropDrive = {
    taskkill /f /im OneDrive.exe -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    if (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") { Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" "/uninstall" -NoNewWindow -Wait }
    if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") { Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -NoNewWindow -Wait }
    Show-Msg "OneDrive Setup binaries and active engines uninstalled."
}

$actDropNav = {
    # Blocks Home & Gallery folders from Explorer Namespace root tree listings
    New-Item -Path "HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Name "System.IsPinnedToNameSpaceTree" -Value 0
    New-Item -Path "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Name "System.IsPinnedToNameSpaceTree" -Value 0
    Stop-Process -Name explorer -Force
    Show-Msg "Home and Gallery dropped from File Explorer navigation sidebar!"
}

$actSFC = {
    Show-Msg "Running System Corruption Scan (SFC)... This takes a minute."
    sfc /scannow
    Show-Msg "SFC Integrity Check sequence evaluated."
}

$actNetReset = {
    netsh int ip reset
    netsh winsock reset
    ipconfig /release
    ipconfig /renew
    ipconfig /flushdns
    Show-Msg "IP Config matrices, DNS caches, and local Winsock protocols flushed!"
}

# Column 1
Add-ControlBtn $tabMisc "Completely Uninstall OneDrive" 30 70 $actDropDrive
Add-ControlBtn $tabMisc "Remove Home & Gallery Sidebar Items" 30 130 $actDropNav

# Column 2
Add-ControlBtn $tabMisc "Run System Corruption Scan (SFC)" 430 70 $actSFC
Add-ControlBtn $tabMisc "Full Network Reset & Flush DNS" 430 130 $actNetReset


# ===================================================================
# FINAL LAUNCH LOOP
# ===================================================================
# Garbage collection to free up memory from icon temp files
[System.GC]::Collect()
$form.ShowDialog()