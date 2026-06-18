# Ensure the required Windows Forms assemblies are loaded
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main Form window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Rocket Performance"
$form.Width = 400
$form.Height = 300
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# -------------------------------------------------------------------
# Script Logic (Functions)
# -------------------------------------------------------------------

# Function: Clean Temp Files
$CleanTemp = {
    try {
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show("Temporary files cleared successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to clean temp files: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Function: Enable Gaming Mode (High Performance Power Plan)
$GamingMode = {
    try {
        powercfg -setactive SCHEME_MIN
        [System.Windows.Forms.MessageBox]::Show("Power plan set to High Performance!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to switch power plans.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Function: Disable Telemetry Services
$DisableTelemetry = {
    try {
        Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
        Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show("Telemetry services disabled!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to stop telemetry. Make sure you ran PowerShell as Admin.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# -------------------------------------------------------------------
# UI Components (Buttons)
# -------------------------------------------------------------------

# Button 1: Clean Temp Files
$tempButton = New-Object System.Windows.Forms.Button
$tempButton.Text = "Clean Temp Files"
$tempButton.Width = 200
$tempButton.Height = 30
$tempButton.Top = 40
$tempButton.Left = 100
$tempButton.Add_Click($CleanTemp)

# Button 2: Gaming Mode
$gamingButton = New-Object System.Windows.Forms.Button
$gamingButton.Text = "Gaming Mode (High Perf)"
$gamingButton.Width = 200
$gamingButton.Height = 30
$gamingButton.Top = 90
$gamingButton.Left = 100
$gamingButton.Add_Click($GamingMode)

# Button 3: Disable Telemetry
$privacyButton = New-Object System.Windows.Forms.Button
$privacyButton.Text = "Disable Telemetry"
$privacyButton.Width = 200
$privacyButton.Height = 30
$privacyButton.Top = 140
$privacyButton.Left = 100
$privacyButton.Add_Click($DisableTelemetry)

# Add all components to the Form window
$form.Controls.Add($tempButton)
$form.Controls.Add($gamingButton)
$form.Controls.Add($privacyButton)

# Display the GUI window
$form.ShowDialog()