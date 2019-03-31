$hugoVersion = "0.54.0"  # Feb 1, 2019
$hugoDownloadPath = "https://github.com/gohugoio/hugo/releases/download/v{0}/hugo_extended_{0}_Windows-64bit.zip" -f $hugoVersion

# Returns the path where Hugo is installed.
function Get-HugoPath($version=$hugoVersion) {
	# Hard-coded for now. Perhaps this should use an env variable?
	return "D:\home\site\deployments\tools\hugo\v$version\"
}

# Returns the path to hugo.exe itself
function Get-HugoExe($version=$hugoVersion) {
	return Join-Path (Get-HugoPath($version)) "hugo.exe"
}

# Downloads Hugo from GitHub and installs it if needed. By default installation will be
# skipped if Hugo is already installed but this can be overridden by setting the $force
# parameter to $true.
function Install-Hugo($version=$hugoVersion, $force=$false) {
	# Check if Hugo is installed
	$hugoPath = Get-HugoPath($version)
	$isInstalled = Test-Path (Get-HugoExe($version))

	if(-not $isInstalled -or $force) {
		# Download and install Hugo
		mkdir $hugoPath -Force
		Push-Location $hugoPath

		Write-Output "Downloading Hugo v$hugoVersion"

		# This is to address an error: "Invoke-WebRequest : The request was aborted: Could
		# not create SSL/TLS secure channel." See this answer on StackOverflow for more:
		# https://stackoverflow.com/a/48030563
		[Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls"

		# Prevent the progress meter from trying to access the console mode
		$ProgressPreference = "SilentlyContinue"
		$null | Invoke-WebRequest -OutFile hugo.zip -Uri $hugoDownloadPath

		Write-Output "Installing Hugo..."
		# I don't know if 7zip's presence in Azure is guaranteed or documented...
		d:\7zip\7za x hugo.zip
		Write-Output "Done!"
		Pop-Location
	} else {
		Write-Output "Skipping Hugo installation."
	}
}

# Builds the site by running hugo.exe on the server
function Invoke-SiteBuild($version=$hugoVersion) {
	# Build the site
	Write-Output "Building site..."
	Push-Location d:\home\site\repository\
	& $(Get-HugoExe($version)) --destination D:\home\site\temp --verbose
	robocopy.exe D:\home\site\temp D:\home\site\wwwroot /mir
	Pop-Location
	Write-Output "Done!"
}
