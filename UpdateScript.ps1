<#
.SYNOPSIS
    Update script that uses both PSWindowsUpdate and WinGet updates, and output results to log file.
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
    LAST UPDATED: v0.8 - 05/04/2025
        + Updated $logFile variable to dynamic user profile
        + Updated $BaseUpdate and $WingetUpdate to Out-String | Write-Log to cleanup output in log file.
#>

# Function "Write-Log" to write all output to $script:logFile
function Write-Log {
    param(
        [string]$message
    )
    <# Define timeStamp, logTime and logFile variables. Set log file variable to $script so that Show-Menu can
    call back to it at a later time.#>
    $timeStamp = (Get-Date).ToString("HH:mm:ss")
    $logTime= (Get-Date).ToString("MM-dd-yyyy")
    $script:logFile = "$env:USERPROFILE\$logTime.log"

    # Define how logging should be formatted, and command to push to log file.
    $logMessage = "$timeStamp - $message"
    $logMessage | Out-File -Append -FilePath $logFile
}

# Function for formatting the output of the script.
function Format-Output {
    # Adds a carriage break (blank line) and divider to break up output, for easier reviewing.
    Write-Log "`r"
    Write-Log $("=" * 50)
}

# Check if the script is running with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Please run this script as an administrator." -ForegroundColor Red
    exit
}

<#New function GetDependencies. Checks for PSWindowsUpdate module, and imports said module before
continuing to update system.#>
function Get-Dependency {
    # If PSWindowsUpdate isn't installed, pull and install from Microsoft repositories.
    if (-not (Get-Module -ListAvailable -Name 'PSWindowsUpdate')) {
        Write-Log "PSWindowsUpdate module not found. Installing it now."
        try {
            Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -Confirm:$false
            Write-Log "PSWindowsUpdate module installed successfully."
            Format-Output
            Update-Function
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
    Update-Function
}

function Update-Function {
    # Define the update variables for each command needed.
    $BaseUpdate = Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
    $WinGetUpdate = winget upgrade --all --include-unknown --silent

    <# Add formatting to break up output of script, and attempt the updates with try statement,
    and write to log file any errors that occur using catch. #>
    Format-Output
    Write-Host "Starting updates..."

    try {
        $BaseUpdate | Out-String | Write-Log
        Write-Log "Windows updates completed successfully using Get-WindowsUpdate."
        Format-Output
        Show-Menu
    } catch {
        Write-Log "Error during Windows update using Get-WindowsUpdate: $_"
        Format-Output
        exit 0
    }

    try {
        $WinGetUpdate | Out-String | Write-Log
        Write-Log "WinGet updates completed successfully."
        Format-Output
        Show-Menu
    } catch {
        Write-Log "Error during WinGet update: $_"
        Format-Output
        exit 0
    }
}

# New Show-Menu Function
# Provides script with a menu for user friendliness
function Show-Menu {
    param([string]$Title = "Menu")
    Write-Host ""
    Write-Host "================ $Title ================"
    Write-Host "1. Run Script"
    Write-Host "2. View Log File"
    Write-Host "3. View Script"
    Write-Host "4. Restart Host"
    Write-Host "5. Shutdown Host"
    Write-Host "Q. Quit"
    Write-Host "=================================================="
    Write-Host ""
}

do {
    Show-Menu -Title "UpdateScript.ps1"
    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            Write-Host "Running script, please wait..."
            # Commenting out for testing.
            Get-Dependency
            Update-Function
            break
        }
        "2" {
            Write-Host "Printing log file, please wait..."
            Get-Content -Path $logFile
            break
        }
        "3" {
            Write-Host "Printing script file, please wait..."
            Get-Content -Path "\path\to\script\UpdateScript.ps1"
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
