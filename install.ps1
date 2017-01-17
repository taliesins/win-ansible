
$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$cygWinUrl = "https://cygwin.com/setup-x86_64.exe"
if ($ENV:cygWinUrl) {
	$cygWinUrl = $ENV:cygWinUrl
}
$cygWinPath = "$scriptPath\setup-x86_64.exe"
if ($ENV:cygWinPath) {
	$cygWinPath = $ENV:cygWinPath
}
$mirrorUrl = 'http://mirrors.kernel.org/sourceware/cygwin/'
if ($ENV:mirrorUrl) {
	$mirrorUrl = $ENV:mirrorUrl
}
$rootPath = 'c:\cygwin64'
if ($ENV:rootPath) {
	$rootPath = $ENV:rootPath
}
$packagesPath = 'c:\cygwin64-packages'
if ($ENV:packagesPath) {
	$packagesPath = $ENV:packagesPath
}

if (!(Test-Path $cygWinPath)){
	$client = New-Object System.Net.WebClient
	$client.DownloadFile($cygWinUrl, $cygWinPath)
}

$arguments = "--quiet-mode  --no-admin --no-desktop --no-shortcuts --no-startmenu --disable-buggy-antivirus --site $mirrorUrl --root $rootPath --local-package-dir $packagesPath --packages coreutils,libattr1,inutils,curl,libgmp-devel,make,python-devel,python-crypto,python-openssl,python-setuptools,nano,openssl,openssl-devel,libffi-devel,wget,gcc-g++,make,diffutils,libmpfr-devel,libmpc-devel"
Write-Host "install cygwin with: $arguments"

$p = Start-Process -Wait -NoNewWindow -PassThru -FilePath $cygWinPath -ArgumentList $arguments

if ($p.ExitCode -ne 0) {
   Write-Error "Cygwin setup failed with an error!"
}

&$rootPath\bin\bash.exe $scriptPath\ansible.sh 

mkdir -f $rootPath\shim

$playBookShim = @"
@echo off
set CYGWIN=$rootPath
set SH=%CYGWIN%\bin\bash.exe
"%SH%" -c "/usr/local/bin/ansible-winpath-playbook.sh %*"
"@

Set-Content -Path $rootPath\shim\ansible-playbook.bat -Value $playBookShim

$winPathPlayBookShim = @"
#!/bin/bash
PARAMS="`$@"
WINDOWS_HOME_PATH="`cygpath ~ -w`"
# regex your user path to UNIX style path otherwise ansible fails
PARAMS_LINUX=`${PARAMS/$WINDOWS_HOME_PATH/~}
echo "$PARAMS_LINUX"
/bin/ansible-playbook $PARAMS_LINUX
"@

Set-Content -Path $rootPath\usr\local\bin\ansible-winpath-playbook.sh -Value $winPathPlayBookShim