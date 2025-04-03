<#
.SYNOPSIS
	Windows update/upgrade script, using both PSWindowsUpdate module and WinGet cli package tool.
.DESCRIPTION
	PowerShell script that starts by checking that the script is running
	with elevated permissions, and exit if not. It will then check (and install)
	the Get-WindowsUpdate PowerShell module (if not installed already.)
	The script will then proceed to check for updates with said
	Get-WindowsUpdate and the WinGet CLI tool, download and install those
	updates, and save all output to a log file at a destination designated
	by the user
.EXAMPLE
	PS C:\> .\updates.ps1
.NOTES
	LAST UPDATED: v0.7 - 04/05/2025
	# Full review of script, as running script did not complete actions as planned.
	# Reviewed functions and consolidated, where possible.
        # Updated both Get-WindowsUpdate and winget commands
        # Tested on Windows 11 - confirmed working
#>

# Adding for verbose output of script (testing); commented out as testing completed.
# $PSDefaultParameterValues['*:Verbose'] = $true
# Check if the script is running with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Please run this script as an administrator." -ForegroundColor Red
    exit
}

# Define timeStamp, logTime and logFile variables.
$timeStamp = (Get-Date).ToString("HH:mm:ss")
$logTime= (Get-Date).ToString("MM-dd-yyyy")
$logFile = "C:\path\to\logfiles\$logTime.log"

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
    $logMessage = "$timeStamp - $message"
    $logMessage | Out-File -Append -FilePath $logFile
}

# Function for formatting the output of the script.
function Format-Output {
    # Adds a carriage break (blank line) and divider to break up output, for easier reviewing.
    Write-Log "`r"
    Write-Log $("=" * 50)
}

# New function GetDependencies.
# Checks for PSWindowsUpdate module, and imports said module before continuing to update system.
function Get-Dependencies {
    # If PSWindowsUpdate isn't installed, pull and install from Microsoft repositories.
    if (-not (Get-Module -ListAvailable -Name 'PSWindowsUpdate')) {
		Write-Log "PSWindowsUpdate module not found. Installing it now."
		try {
			Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -Confirm:$false
			Write-Log "PSWindowsUpdate module installed successfully."
			Format-Output
		} catch {
			Write-Log "Error installing PSWindowsUpdate module: $_"
			Format-Output
			exit 0
        }
	}

    # Imports said module, and continues script
	Import-Module PSWindowsUpdate
	Write-Log "PSWindowsUpdate module imported."
    Format-Output
    Win-Update
}

# New function Win-Update
# Run Get-WindowsUpdate module to download and install all updates silently.
function Win-Update {
	# Perform Windows Update using Get-WindowsUpdate
	# Will catch and log any errors that may occur.
    Write-Log "Starting Windows updates using Get-WindowsUpdate..."
	try {
		Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -Verbose | Write-Log
		Write-Log "Windows updates completed successfully using Get-WindowsUpdate."
		Write-Log "Update process completed."
		Format-Output
		WinGet-Update
	} catch {
		Write-Log "Error during Windows update using Get-WindowsUpdate: $_"
		Format-Output
		exit 0
	}
}

# New function wingetUpdate
# Perform WinGet update / upgrade using Winget.
function WinGet-Update {
	Write-Log "Starting updates via WinGet..."
	try {
		winget upgrade --all --include-unknown --silent | Write-Log
		Write-Log "WinGet updates completed successfully."
		Format-Output
        Show-Menu
	} catch {
		Write-Log "Error updating $appName via WinGet: $_"
		Format-Output
        Show-Menu
	}
}

# New Show-Menu Function
# Provides script with a menu for user friendliness
function Show-Menu {
    param([string]$Title = "Menu")
    Write-Host ""
    Write-Host "================ $Title ================"
    Write-Host "1. Run Script"
    Write-Host "2. Print Log File"
    Write-Host "3. Print Script"
    Write-Host "4. Restart Host"
    Write-Host "5. Shutdown Host"
    Write-Host "Q. Quit"
    Write-Host "==============================================="
    Write-Host ""
}

do {
    Show-Menu -Title "Update Script"
    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            Write-Host "Running script, please wait..."
            Get-Dependencies
            break
        }
        "2" {
            Write-Host "Printing log file, please wait..."
            Get-Content -Path $logFile
            break
        }
        "3" {
            Write-Host "Printing script file, please wait..."
            Get-Content -Path "G:\My Drive\Documents\UpgradeTest.ps1"
            break
        }
        "4" {
            Write-Host "Restarting host, please wait..."
            shutdown /r /f /t 00
            break
        }
        "5" {
            Write-Host "Shutting down host, please wait..."
            shutdown /f /t 00
            break
        }
		"Q" {
			Write-Host "Quitting script, please wait..."
			exit 0
		}
        default {
            Write-Host "Invalid choice. Please try again."
        }
    }
    pause
} until ($choice -eq "Q")

# Start script
Show-Menu
