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

# --- MAIN FORM CANVAS SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Rocket Performance Utility (Winutil Style)"
$form.Width = 700
$form.Height = 600
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# Helper for Alerts
function Show-Msg ($text, $icon=[System.Windows.Forms.MessageBoxIcon]::Information) {
    [System.Windows.Forms.MessageBox]::Show($text, "Rocket Engine", [System.Windows.Forms.MessageBoxButtons]::OK, $icon)
}

# --- TAB CONTROL CONTAINER ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(660, 520)
$tabControl.Location = New-Object System.Drawing.Point(12, 12)

$tabTweaks = New-Object System.Windows.Forms.TabPage
$tabTweaks.Text = "  System Tweaks  "

$tabApps = New-Object System.Windows.Forms.TabPage
$tabApps.Text = "  Applications  "

$tabMisc = New-Object System.Windows.Forms.TabPage
$tabMisc.Text = "  Misc / Config  "

# Attach individual tabs to main container
$tabControl.Controls.Add($tabTweaks)
$tabControl.Controls.Add($tabApps)
$tabControl.Controls.Add($tabMisc)
$form.Controls.Add($tabControl)

# Helper Function to quickly make uniform layout buttons
function Add-ControlBtn($parentTab, $txt, $x, $y, $action) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $txt
    $btn.Size = New-Object System.Drawing.Size(280, 38)
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $btn.Add_Click($action)
    $parentTab.Controls.Add($btn)
}

# Helper Function to add headers to tab groups
function Add-TabHeader($parentTab, $txt, $x, $y) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $txt
    $lbl.Size = New-Object System.Drawing.Size(280, 25)
    $lbl.Location = New-Object System.Drawing.Point($x, $y)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $parentTab.Controls.Add($lbl)
}

# ===================================================================
# TAB 1: SYSTEM TWEAKS
# ===================================================================
Add-TabHeader $tabTweaks "Essential Optimizations" 30 20
Add-TabHeader $tabTweaks "Advanced Performance" 340 20

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
$actGameDVR = {
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -ErrorAction SilentlyContinue
    Show-Msg "Xbox GameDVR capture processes suppressed."
}

# Place Tweaks Buttons
Add-ControlBtn $tabTweaks "Create Restore Point (Safe First Step)" 30 55 $actRestorePoint
Add-ControlBtn $tabTweaks "Disable Telemetry Services" 30 105 $actTelem
Add-ControlBtn $tabTweaks "Deep Disk Cleanup & Temp Clear" 30 155 $actTemp
Add-ControlBtn $tabTweaks "Disable Mouse Acceleration" 30 205 $actMouse

Add-ControlBtn $tabTweaks "Activate Standard High Performance" 340 55 $actHighPerf
Add-ControlBtn $tabTweaks "Unlock Ultimate Performance Profile" 340 105 $actUltPerf
Add-ControlBtn $tabTweaks "Disable Windows GameDVR" 340 155 $actGameDVR


# ===================================================================
# TAB 2: APPLICATIONS (WINGET SETUP MANAGERS)
# ===================================================================
Add-TabHeader $tabApps "Web Browsers" 30 20
Add-TabHeader $tabApps "Utility & System Stripping" 340 20

# -- App deployment blocks --
$actInsFox = { Show-Msg "Deploying Firefox..."; winget install --id Mozilla.Firefox -e --silent; Show-Msg "Firefox Installed!" }
$actInsChrome = { Show-Msg "Deploying Chrome..."; winget install --id Google.Chrome -e --silent; Show-Msg "Chrome Installed!" }
$actInsBrave = { Show-Msg "Deploying Brave..."; winget install --id Brave.Brave -e --silent; Show-Msg "Brave Installed!" }
$actDelEdge = {
    taskkill /F /IM msedge.exe /T -ErrorAction SilentlyContinue
    Get-AppxPackage -AllUsers *MicrosoftEdge* | Remove-AppxPackage -ErrorAction SilentlyContinue
    Show-Msg "Microsoft Edge app dependencies removed."
}
$actIns7z = { Show-Msg "Installing 7-Zip..."; winget install --id IgorPavlov.7-Zip -e --silent; Show-Msg "7-Zip Installed!" }
$actInsDiscord = { Show-Msg "Installing Discord..."; winget install --id Discord.Discord -e --silent; Show-Msg "Discord Installed!" }

# Place App Buttons
Add-ControlBtn $tabApps "Install Mozilla Firefox" 30 55 $actInsFox
Add-ControlBtn $tabApps "Install Google Chrome" 30 105 $actInsChrome
Add-ControlBtn $tabApps "Install Brave Browser" 30 155 $actInsBrave

Add-ControlBtn $tabApps "Purge Microsoft Edge" 340 55 $actDelEdge
Add-ControlBtn $tabApps "Install 7-Zip Utilities" 340 105 $actIns7z
Add-ControlBtn $tabApps "Install Discord App" 340 155 $actInsDiscord


# ===================================================================
# TAB 3: MISC / CONFIG DEBLOAT
# ===================================================================
Add-TabHeader $tabMisc "Windows System Debloating" 30 20
Add-TabHeader $tabMisc "Network & Core Troubleshooting" 340 20

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
    netsh int ip reset; netsh winsock reset; ipconfig /flushdns
    Show-Msg "IP Config matrices and local Winsock protocols flushed!"
}

# Place Misc Buttons
Add-ControlBtn $tabMisc "Completely Uninstall OneDrive" 30 55 $actDropDrive
Add-ControlBtn $tabMisc "Remove Home & Gallery Sidebar Items" 30 105 $actDropNav

Add-ControlBtn $tabMisc "Run System Corruption Scan (SFC)" 340 55 $actSFC
Add-ControlBtn $tabMisc "Reset Network & Flush DNS Cache" 340 105 $actNetReset


# ===================================================================
# FINAL LAUNCH LOOP
# ===================================================================
$form.ShowDialog()