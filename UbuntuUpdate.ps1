#!/usr/bin/env pwsh
<#
.SYNOPSIS
    PowerShell script that will update and 'clean' an Ubuntu host pc.
    !!! REQUIRES POWERSHELL INSTALLED ON HOST UBUNTU PC AND SUDO PERMISSIONS !!!

.DESCRIPTION
    Script will run menu which will provide multiple options (see end of script for Show-Menu function).
    The user can then run the script, which will use multiple items to update the host PC, and then run
    simple 'cleanup' commands on the host. The user will then be thrown back into the menu, where they can
    view the script file, log file, restart host, shutdown host or exit the script entirely.

.EXAMPLE
    $ sudo pwsh UbuntuUpdate.ps1

.NOTES
    AUTHOR: Raymond Covey (@RCovey1976)'
    VERSION:  v1.1
    LAST UPDATED: 12/29/2025
        # Minor tweaks to Run-Update function
        # Removed View-Script and View-Log functions; replaced with Get-Content in switch statement.
        # Chaged from Tee-Object to Out-File (to keep output of commands out of console).
        # Changed position of Pause function in script
        # Created Insert-Break function, for better readability of log file.
        # Removed Start-Sleep commands (to improve speed of script).
        # Added catches in both Run-Update and Run-Cleanup (to catch any errors).
#>

<# Checks if script is run w/ sudo permissions; if not,
exits the script.#>
if ((id -u) -ne 0) {
    Write-Error "Please run this script with sudo."
    exit 1
}

# Sets variable (for future reference) and makes sure the .log file is created.
$scriptPath = "/path/to/script/UbuntuUpdate.ps1"
$logPath = "/path/to/logs/$(Get-Date -Format 'MM-dd-yyyy')_pwsh.log"
New-Item -Path $logPath -ItemType File -Force

# Function to use bash commands in PowerShell
function Invoke-BashCommand {
    param([string]$Command)
    bash -c "$Command" | Out-File -FilePath $logPath -NoClobber -Append
}

<# Simple pause function to stop a section of code after running to allow
review by the user.#>
function Pause {
    Write-Output "`nPress Enter to return to the menu..."
    Read-Host
}

<# Insert-Break function; inserts a carriage return and blank line in order to
break up the logfile output (for readability)#>
function Insert-Break {
    Write-Output $("=" * 50) | Out-File -FilePath $logPath -Append
    "`r" | Out-File -FilePath $logPath -Append
}

# Run-Update function; main portion of script that will run each
# bash command on the host.
function Run-Update {

	Write-Output "Beginning update; please wait..." | Out-File -FilePath $logPath -NoClobber -Append
	Insert-Break

	# Array of bash update commands that need to be run.
	$updateCommands = @(
		"apt-get -y update",
    "apt-get -y upgrade",
    "apt-get -y dist-upgrade",
    "flatpak update -y",
		"systemctl stop clamav-freshclam.service",
		"freshclam",
		"systemctl daemon-reload",
		"tldr --update"
    "fwupdmgr refresh --force"
	  "fwupdmgr get-devices"
	  "fwupdmgr get-updates"
	  "fwupdmgr update"
	)

	# Foreach statement; for each command in array, run the following
	# code. Will run each command using bash -c.
	foreach($command in $updateCommands) {
	    Write-Output " ====> Executing command $command"
	    Invoke-BashCommand -Command $command | Out-File -FilePath $logPath -NoClobber -Append

        # Checks for any failures, and outputs these to logfile.
        $result = Invoke-BashCommand -Command $command
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Command failed: $command" | Out-File -FilePath $logPath -NoClobber -Append
            Start-Sleep 2
            Show-Menu
        }
	}

	Write-Output "`nUpdate complete. Output saved to $logPath" | Out-File -FilePath $logPath -NoClobber -Append
    Insert-Break
	Run-Cleanup
}

<# Run-Cleanup function; similar to Run-Update, except the commands are
used for cleaning orphaned packages, old logs and caches.#>
function Run-Cleanup {

    Write-Output "Beginning cleanup; please wait.." | Out-File -FilePath $logPath -NoClobber -Append
    Insert-Break

    # Array of bash commands to run to 'clean' Ubuntu host.
    $cleanupCommands = @(
        "apt-get autoremove -y",
        "apt-get clean",
        "dpkg --configure -a",
        "journalctl --rotate",
        "journalctl --vacuum-time=1d",
        "rm -rf /var/cache/apt",
        "rm -rf $env:HOME/.cache/*"  
    )

    # Foreach statement; for each command in array, run the following
	# code. Will run each command using bash -c.
	foreach($command in $cleanupCommands) {
	    Write-Output " ====> Executing command $command"
	    Invoke-BashCommand -Command $command | Out-File -FilePath $logPath -NoClobber -Append

        # Checks for any failures, and outputs these to logfile.
        $result = Invoke-BashCommand -Command $command
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Command failed: $command" | Out-File -FilePath $logPath -NoClobber -Append
            Start-Sleep 2
            Show-Menu
        }
	}

	Write-Output "`nCleanup complete. Output saved to $logPath" | Out-File -FilePath $logPath -NoClobber -Append
    Insert-Break
}

<# Show-Menu function, which will display all available options
to the user. #>
function Show-Menu {
    Clear-Host
    Write-Output "
    
    ==============================
       Ubuntu Maintenance Menu
    ==============================
    1. Run system update
    2. View update script
    3. View update log
    4. Restart system
    5. Shutdown system
    6. Exit Script
    ==============================
    
    "
}

<# Main loop; switch statement that will use function or option chosen by
the end user during the Show-Menu function. #>
do {
    Show-Menu
    $choice = Read-Host "`nEnter your choice (1-6)"

    switch ($choice) {
        '1' { Run-Update }
        '2' { Get-Content -Path $scriptPath; Pause }
        '3' { Get-Content -Path $logPath; Pause }
        '4' { Restart-Computer }
        '5' { Stop-Computer }
        '6' {
            Write-Output "Exiting..."
            exit
        }
        default {
            Write-Output "Invalid option. Please select 1-6."
            Pause
        }
    }
} while ($true)
