[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Prompt Configuration
function Check-Ssh {
    if ($env:SSH_CLIENT -or $env:SSH_TTY) {
        return "`n`e[1;37m$($env:USERNAME)@$($env:COMPUTERNAME):`e[0m`n"
    } else {
        return ""
    }
}

function Relative-Path {
    param ($target, $base)
    try {
        return [System.IO.Path]::GetRelativePath($base, $target)
    } catch {
        return "."
    }
}

function Set-GitDir {
    param ($gitRoot, $gitCurrentDir, $gitRootDir)


    if ($Host.UI -and $Host.UI.SupportsVirtualTerminal -eq $true) {
      $projectIcon = " "
    } else {
      $projectIcon = "..\"
    }

    $superprojectRoot = git rev-parse --show-superproject-working-tree 2>$null

    if ($superprojectRoot) {
        $submoduleName = Split-Path $gitRoot -Leaf
        $superprojectName = Split-Path $superprojectRoot -Leaf
        $workingDir = "`e[1;34m$projectIcon$superprojectName\$submoduleName\$gitCurrentDir`e[0m"
    } else {
        $workingDir = "`e[1;34m$projectIcon$gitRootDir$gitCurrentDir`e[0m"
    }

    return $workingDir
}

function Check-Venv {
    param ($gitRoot)
    $venvIcons = ""

    $pyIcon = "py"
    $jsIcon = "js"
    $nixIcon = "nix"

    if ($Host.UI -and $Host.UI.SupportsVirtualTerminal -eq $true) {
        $pyIcon = ""
        $jsIcon = "󰌞"
        $nixIcon = ""
    }

    $pythonIcon = "`e[1;33m$pyIcon`e[0m"
    $nodeIcon = "`e[1;93m$jsIcon`e[0m"
    $nixIcon = "`e[1;34m$nixIcon`e[0m"

    if ($env:VIRTUAL_ENV) {
        $venvIcons += "$pythonIcon "
    }

    if ($env:IN_NIX_SHELL) {
      $venvIcons += "$nixIcon "
    }

    if (Test-Path -Path (Join-Path $gitRoot "node_modules")) {
        $venvIcons += "$nodeIcon "
    }

    return $venvIcons
}

function Check-Project {
    $gitRoot = git rev-parse --show-toplevel 2>$null
    if ($gitRoot) {
        $gitBranch = git branch --show-current 2>$null
        if (-not $gitBranch) {
            $gitBranch = git describe --tags --exact-match 2>$null
            if (-not $gitBranch) {
                $gitBranch = git rev-parse --short HEAD 2>$null
            }
        }

        $relativePath = Relative-Path $PWD.Path $gitRoot
        if ($relativePath -eq "." -or [string]::IsNullOrEmpty($relativePath)) {
            $gitCurrentDir = ""
        } else {
            $gitCurrentDir = "\$relativePath"
        }

        $gitRootDir = Split-Path $gitRoot -Leaf
        $gitBranchPrompt = "`e[1;31m${gitBranch}:`e[0m"
        $workingDir = Set-GitDir -gitRoot $gitRoot -gitCurrentDir $gitCurrentDir -gitRootDir $gitRootDir
        $venvIcons = Check-Venv -gitRoot $gitRoot

        return @{
            WorkingDir = $workingDir
            GitBranchPrompt = $gitBranchPrompt
            VenvIcons = $venvIcons
        }
    } else {
        $workingDir = "`e[1;34m$($PWD.Path)`e[0m"
        return @{
            WorkingDir = $workingDir
            GitBranchPrompt = ""
            VenvIcons = ""
        }
    }
}

# Define the Prompt function
function Prompt {
    $greenArrow = "`e[1;32m>> "
    $whiteText = "`e[0m"

    $sshPrompt = Check-Ssh
    $projectInfo = Check-Project

    $promptString = "$sshPrompt$($projectInfo.WorkingDir)`n$($projectInfo.VenvIcons)$greenArrow$($projectInfo.GitBranchPrompt)$whiteText"
    return $promptString
}

Set-Alias vim nvim 
Set-Alias grep Select-String

Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -BellStyle None
Set-PSReadlineKeyHandler -Chord Alt+F4 -Function ViExit
Set-PSReadlineKeyHandler -Key Tab -Function Complete
