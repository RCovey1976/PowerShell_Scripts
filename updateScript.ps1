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
	LAST UPDATED: v0.1 - 03/07/2025
		# Started creation of script
		# Defined needed variables (logFile, timeStamp, etc.)
		# Setup script framework
		# First draft of script completed
		# Testing completed
		# Minor changes to variables and framework
#>

# Define timeStamp variable
$timeStamp = (Get-Date).ToString("MM-dd-yyyy_HH:mm:ss")

# Define logFile path
$logFile = "C:\path\to\logfile\$timeStamp_updates.log"

# Creates windowsUpdate and wingetUpgrade variables.
$windowsUpdate = Get-WindowsUpdate -Install -AcceptAll
$wingetUpgrade = winget upgrade --all --include-unknown --silent

# Function "Write-Log" to write all output to $logFile
function Write-Log {
    param(
        [string]$message
    )
    $logMessage = "$timestamp - $message"
    $logMessage | Out-File -Append -FilePath $logFile
}

# Check if the script is running with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Please run this script as an administrator." -ForegroundColor Red
    exit
}

# Formatting for script; adding carriage return and barrier.
Write-Log "`r"
Write-Log $("=" * 50)

# Check if the Get-WindowsUpdate module is installed, if not, install it
if (-not (Get-Module -ListAvailable -Name 'PSWindowsUpdate')) {
    Write-Log "PSWindowsUpdate module not found. Installing it now."
    try {
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -Confirm:$false
        Write-Log "PSWindowsUpdate module installed successfully."
    } catch {
        Write-Log "Error installing PSWindowsUpdate module: $_"
        exit 1
    }
}

# Import the Get-WindowsUpdate module
Import-Module PSWindowsUpdate
Write-Log "PSWindowsUpdate module imported."

# Formatting for script; adding carriage return and barrier
Write-Log "`r"
Write-Log $("=" * 50)

# Perform Windows Update using Get-WindowsUpdate
# Will catch and log any errors that may occur.
try {
    Write-Log "Starting Windows updates using Get-WindowsUpdate..."
    Write-Log $windowsUpdate
    Write-Log "Windows updates completed successfully using Get-WindowsUpdate."
} catch {
    Write-Log "Error during Windows update using Get-WindowsUpdate: $_"
}

# Perform WinGet update / upgrade using Winget.
Write-Log "Starting updates via WinGet..."
try {
    Write-Log $wingetUpgrade
    Write-Log "WinGet updates completed successfully."
} catch {
    Write-Log "Error updating $appName via WinGet: $_"
}
Write-Log "WinGet updates completed."

# Final log entry
Write-Log "Update process completed."

# Formatting for script; adding carriage return and barrier.
Write-Log "`r"
Write-Log $("=" * 50)
