function shutdown {
	param ([string]$arg)
	if ($arg -eq "now") {
		shutdown /s /f /t 0
	}
}

Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -BellStyle None
Set-PSReadlineKeyHandler -Chord Alt+F4 -Function ViExit
