<#
.SYNOPSIS
	Windows update/upgrade script
.DESCRIPTION
	PowerShell script that starts by checking that the script is running
	with elevated permissions, and exit if not. It will then check (and install)
	the Get-WindowsUpdate PowerShell module (if not installed already.)
	The script will then proceed to check for updates with said
	Get-WindowsUpdate and the WinGet CLI tool, download and install those
	updates, and save all output to a log file at a destination designated
	by the user
.EXAMPLE
	PS C:\> .\UpdateScript.ps1
.NOTES
	LAST UPDATED: v0.4 - 12/29/2025
        + Moved Write-Log function to beginning of script
        + Added Format-Output and Get-Setup functions
        + Cleaned up Show-Menu function
#>

# Adding for verbose output of script (testing); commented out as testing completed.
# $PSDefaultParameterValues['*:Verbose'] = $true

# Function "Write-Log" to write all output to $logFile
function Write-Log {
    param(
        [string]$message
    )
    # Define timeStamp, logTime and logFile variables.
    $script:timeStamp = (Get-Date).ToString("HH:mm:ss")
    $script:logTime= (Get-Date).ToString("MM-dd-yyyy")
    $script:logFile = "C:\path\to\logfiles\$logTime.log"

    $logMessage = "$timeStamp - $message"
    $logMessage | Out-File -Append -FilePath $logFile
}

# Check if the script is running with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Please run this script as an administrator." -ForegroundColor Red
    exit
}

# Format-Output function; adds carriage return and break to log file, for better readability.
function Format-Output {
    "`r" | Out-File -FilePath $logFile -Append
    Write-Output $("=" * 50) | Out-File -FilePath $logFile -Append
}

<# Get-Setup function; checks for prerequisites and completes any necessary tasks
to fulfill said prerequisites #>
function Get-Setup {
    # Check for 
    if (-not (Test-Path $LogRoot)) {
        New-Item -ItemType Directory -Path $LogRoot | Out-Null
    }

    # First, check for PSWindowsUpdate Module, and if not installed,
    # install to host PC.
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Install-Module PSWindowsUpdate -Force -Confirm:$false
    }
    Import-Module PSWindowsUpdate
}

# New function Update-Func.
# Runs both PSWindowsUpdate and WinGet updates, and catches any errors.
function Update-Func {
    # Begin update process; catch any errors that may appear
    try {
        Write-Log "Starting updates. Please wait while updates complete..."
        Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot | Out-String | Write-Log
        Format-Output
        winget upgrade --all --include-unknown --silent | Out-String | Write-Log
        Format-Output
        Show-Menu
    } catch {
        Write-Log "Error occured during update phase: $_"
        Format-Output
        Show-Menu
    }
}

# New Show-Menu Function
# Provides script with a menu for user friendliness
function Show-Menu {
    param([string]$Title)
    Write-Host "
    ================ $Title ================
    1. Run Script
    2. Print Log File
    3. Print Script
    4. Restart Host
    5. Shutdown Host
    Q. Quit
    ===============================================
    "
}

do {
    Show-Menu -Title "Update Script"
    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            Write-Host "Running script, please wait..."
            Get-Setup
            break
        }
        "2" {
            Write-Host "Printing log file, please wait..."
            Get-Content -Path $logFile
            break
        }
        "3" {
            Write-Host "Printing script file, please wait..."
            Get-Content -Path $PSCommandPath
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
