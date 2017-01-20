
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

$arguments = "--quiet-mode  --no-admin --no-desktop --no-shortcuts --no-startmenu --disable-buggy-antivirus --site $mirrorUrl --root $rootPath --local-package-dir $packagesPath --packages coreutils,libattr1,inutils,curl,libgmp-devel,make,python-devel,python-crypto,python-openssl,python-setuptools,nano,openssl,openssl-devel,libffi-devel,wget,gcc-g++,make,diffutils,libmpfr-devel,libmpc-devel,git,openssh,libkrb5-devel,krb5-workstation"
Write-Host "install cygwin with: $arguments"

$p = Start-Process -Wait -NoNewWindow -PassThru -FilePath $cygWinPath -ArgumentList $arguments

if ($p.ExitCode -ne 0) {
   Write-Error "Cygwin setup failed with an error!"
}

&$rootPath\bin\bash.exe $scriptPath\ansible.sh 

$shim=@"
@echo off
set CYGWIN=$rootPath
set SH=%CYGWIN%\bin\bash.exe
"%SH%" -c "{{CMD_PATH}} '%cd%' %*"
"@

$winShim=@"
#!/bin/bash
ANSIBLE=/opt/ansible
PATH=/bin:`$PATH:`$ANSIBLE/bin
PYTHONPATH=`$ANSIBLE/lib:
ANSIBLE_LIBRARY=`$ANSIBLE/library
C_INCLUDE_PATH=/usr/include:/usr/include/python2.7:`$C_INCLUDE_PATH
C_PLUS_INCLUDE_PATH=/usr/include:/usr/include/python2.7:`$C_PLUS_INCLUDE_PATH
LIBRARY_PATH=/usr/lib:`$LIBRARY_PATH
LD_LIBRARY_PATH=/usr/lib:`$LD_LIBRARY_PATH

cd ``cygpath `$1 -a``
shift
PARAMS="`$@"
WINDOWS_HOME_PATH="cygpath ~ -w"
# regex your user path to UNIX style path otherwise ansible fails
PARAMS_LINUX=`${PARAMS//~}
echo "pwd = ``pwd``"
echo "{{CMD_PATH}} `$PARAMS_LINUX"
{{CMD_PATH}} `$PARAMS_LINUX
"@

mkdir -f $rootPath\shim

"ansible", "ansible-console", "ansible-doc", "ansible-galaxy", "ansible-playbook", "ansible-pull", "ansible-vault" | %{
	$command = $_
	
	$commandShim = $shim.Replace("{{CMD_PATH}}", "/usr/local/bin/winpath-$($command).sh")
	$commandShimPath = "$rootPath\shim\$($command).bat"
	[IO.File]::WriteAllText($commandShimPath, $commandShim)	

	$winPathCommandShim = $winShim.Replace("{{CMD_PATH}}", "/bin/$command")
	$winPathCommandShimPath = "$rootPath\usr\local\bin\winpath-$($command).sh"
	[IO.File]::WriteAllText($winPathCommandShimPath, $winPathCommandShim)	
}

$AdController = $env:LOGONSERVER -replace "\\", ""

if ($AdController) {
	$Domain = (Get-WmiObject Win32_ComputerSystem).Domain.ToUpper()
	
	if ($Domain){
		$Krb5Conf = @"
[logging]
	default = FILE:/var/log/krb5libs.log
	kdc = FILE:/var/log/krb5kdc.log
	admin_server = FILE:/var/log/kadmind.log

[libdefaults]
	default_realm = $($Domain)
	dns_lookup_realm = true
	dns_lookup_kdc = true
	ticket_lifetime = 24h
	renew_lifetime = 7d
	forwardable = true
 
[realms]
	$($Domain) = {
		kdc = $($AdController).$($Domain.ToLower())
	}

[domain_realm]
	.$($Domain.ToLower()) = $($Domain)
	$($Domain.ToLower()) = $($Domain)
"@ -replace "`r`n", "`n"
		
		$Krb5ConfPath = "$rootPath\etc\krb5.conf"
		[IO.File]::WriteAllText($Krb5ConfPath, $Krb5Conf)
	}
}