# Function to check if the session is an SSH session
function Check-Ssh {
    if ($env:SSH_CLIENT -or $env:SSH_TTY) {
        $global:sshPrompt = "$([char]27)[1;37m$($env:USERNAME)@$($env:COMPUTERNAME):$([char]27)[0m`n"
        return $true
    }
    $global:sshPrompt = ""
    return $false
}

# Function to manage virtual environment icons and project status
function Check-Venv {
    $global:venvIcons = ""

    function Add-Icon {
        param([string]$icon)
        if (-not ($global:venvIcons -contains $icon)) {
            $global:venvIcons += "$icon "
        }
    }

    function Remove-Icon {
        param([string]$icon)
        $global:venvIcons = $global:venvIcons.Replace("$icon ", "")
    }

    $py = "py"
    $js = "js"
    $nix = "nix"

    if ($env:DISPLAY) {
        $py = ""
        $js = "󰌞"
        $nix = ""
    }

    $pythonIcon = "$([char]27)[1;33m$py$([char]27)[0m"
    $nodeIcon = "$([char]27)[1;93m$js$([char]27)[0m"
    $nixIcon = "$([char]27)[1;34m$nix$([char]27)[0m"

    if ($env:IN_NIX_SHELL) {
        Add-Icon $nixIcon
    } else {
        Remove-Icon $nixIcon
    }

    if ($env:VIRTUAL_ENV) {
        Add-Icon $pythonIcon
    } else {
        Remove-Icon $pythonIcon
    }

    if (Test-Path -Path "$PWD\node_modules") {
        Add-Icon $nodeIcon
    } else {
        Remove-Icon $nodeIcon
    }
}

# Function to set the Git directory status in the prompt
function Set-GitDir {
    if ($env:DISPLAY) {
        $global:projectIcon = " "
    } else {
        $global:projectIcon = "../"
    }

    $gitRoot = git rev-parse --show-toplevel 2>$null

    if ($gitRoot) {
        $gitBranch = git branch --show-current 2>$null

        if (-not $gitBranch) {
            $gitBranch = git describe --tags --exact-match 2>$null
            if (-not $gitBranch) {
                $gitBranch = git rev-parse --short HEAD 2>$null
            }
        }

        $gitCurrentDir = Resolve-Path -Relative . -RelativeBase $gitRoot
        $gitRootDir = Split-Path -Leaf $gitRoot

        if ($env:DISPLAY) {
            $global:gitBranchPrompt = "$([char]27)[1;31m$gitBranch 󰘬:$([char]27)[0m"
        } else {
            $global:gitBranchPrompt = "$([char]27)[1;31m${gitBranch}:$([char]27)[0m"
        }
    }
}

# Function to check if the current project is in Git
function Check-Project {
    $gitRoot = git rev-parse --show-toplevel 2>$null

    if ($gitRoot) {
        Set-GitDir
        Check-Venv
        return $true
    }
    return $false
}

# Function to set the PowerShell prompt
function prompt {
    $greenArrow = "$([char]27)[1;32m>> "
    $whiteText = "$([char]27)[0m"
    $workingDir = "$([char]27)[1;34m$PWD$([char]27)[0m"

    $global:sshPrompt = ""
    [void](Check-Ssh)

    $global:venvIcons = ""
    $global:gitBranchPrompt = ""
    [void](Check-Project)

    return "$global:sshPrompt$workingDir`n$global:venvIcons$greenArrow$global:gitBranchPrompt$whiteText"
}

Set-Alias vim nvim 
Set-Alias grep Select-String

Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -BellStyle None
Set-PSReadlineKeyHandler -Chord Alt+F4 -Function ViExit
