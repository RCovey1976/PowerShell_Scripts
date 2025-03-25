<#
.SYNOPSIS
	Final update script; written after many iterations.
	
.DESCRIPTION
	PowerShell script that starts by checking that the script is running
	with elevated permissions, and exit if not. It will then check (and install)
	the Get-WindowsUpdate PowerShell module (if not installed already.)
	The script will then proceed to check for updates to Windows with said
	Get-WindowsUpdate and the WinGet CLI tool, download and install those
	updates, and save all output to a log file at a destination designated
	by the user
.EXAMPLE
	PS C:\> .\updates.ps1
.NOTES
	LAST UPDATED: v0.4 - 03/25/2025
		+ Added Format-Output function (formatting to break up output of script; better readability)
		+ Added check for log directory and log file
		+ Moved privilege check to beginning of script.
#>

# Check if the script is running with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Please run this script as an administrator." -ForegroundColor Red
    exit
}

# Define timeStamp variable
$timeStamp = (Get-Date).ToString("MM-dd-yyyy_HH:mm:ss")

# Define logFile path
$logFile = "C:\path\to\logfile\$timeStamp_updates.log"

# Ensures the log directory exists, and if not, creates the directory.
$logDir = [System.IO.Path]::GetDirectoryName($logFile)
if (-not (Test-Path -Path $logDir)) {
    Write-Host "Creating log directory at $logDir"
    New-Item -ItemType Directory -Path $logDir
}

# Function "Write-Log" to write all output to $logFile
function Write-Log {
    param(
        [string]$message
    )
    $logMessage = "$timestamp - $message"
    $logMessage | Out-File -Append -FilePath $logFile
}

# Function for formatting the output of the script.
function Format-Output {
    # Adds a carriage break (blank line) and divider to break up output, for easier reviewing.
    Write-Log "`r"
    Write-Log $("=" * 50)
}

# Check if the Get-WindowsUpdate module is installed, if not, install it
if (-not (Get-Module -ListAvailable -Name 'PSWindowsUpdate')) {
    Write-Log "PSWindowsUpdate module not found. Installing it now."
    try {
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -Confirm:$false
        Write-Log "PSWindowsUpdate module installed successfully."
	Format-Output
    } catch {
        Write-Log "Error installing PSWindowsUpdate module: $_"
	Format-Output
        exit 1
    }
}

# Import the Get-WindowsUpdate module
Import-Module PSWindowsUpdate
Write-Log "PSWindowsUpdate module imported."

# Perform Windows Update using Get-WindowsUpdate
# Will catch and log any errors that may occur.
try {
    Write-Log "Starting Windows updates using Get-WindowsUpdate..."
    Write-Log Get-WindowsUpdate -Install -AcceptAll -ErrorHandling Stop
    Write-Log "Windows updates completed successfully using Get-WindowsUpdate."
    Format-Output
} catch {
    Write-Log "Error during Windows update using Get-WindowsUpdate: $_"
    Format-Output
}

# Perform WinGet update / upgrade using Winget.
Write-Log "Starting updates via WinGet..."
try {
    Write-Log winget upgrade --all --include-unknown --silent
    Write-Log "WinGet updates completed successfully."
    Format-Output
} catch {
    Write-Log "Error updating $appName via WinGet: $_"
    Format-Output
}

# Final log entry
Write-Log "Update process completed."
Format-Output
