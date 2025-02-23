# Enable the built-in Administrator account
$adminAccount = Get-LocalUser -Name "Administrator"
$adminAccount.Enabled = $true
$adminAccount | Set-LocalUser

# Set the password of the Administrator account to never expire
Get-LocalUser -Name "Administrator" | Set-LocalUser -PasswordNeverExpires $true

# Prompt for the Administrator account password
$password = Read-Host -AsSecureString "Enter new password for the Administrator account"

# Set the password
$adminAccount | Set-LocalUser -Password $password

# Prompt for the IP address for mstsc
$ipAddress = Read-Host "Enter the IP address for mstsc connection"

# Set current user to auto login
$userName = $env:UserName
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty -Path $regPath -Name "DefaultUsername" -Value $userName
$secureStringPassword = $password | ConvertFrom-SecureString
Set-ItemProperty -Path $regPath -Name "DefaultPassword" -Value $secureStringPassword

# Create a universal script location
$scriptPath = "C:\Scripts"
if (-not (Test-Path $scriptPath)) {
    New-Item -ItemType Directory -Path $scriptPath
}

# Create the LaunchRDP.ps1 script
$rdpScriptPath = Join-Path $scriptPath "LaunchRDP.ps1"
$rdpScriptContent = @"
while (`$true) {
    try {
        Start-Process 'mstsc' -ArgumentList '/f /v:$ipAddress' -Wait
    } catch {
        Start-Sleep -Seconds 2
    }
}
"@
$rdpScriptContent.Replace("`$ipAddress", $ipAddress) | Out-File -FilePath $rdpScriptPath -Encoding UTF8

# Set the new PowerShell script as the shell
$shellCommand = "powershell.exe -WindowStyle Hidden -File `"$rdpScriptPath`""
Set-ItemProperty -Path $regPath -Name "Shell" -Value $shellCommand

# Enable Remote Desktop
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

# Allow Remote Desktop through the Firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Configure the system to allow logins to the Administrator account over RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0

Write-Host "Configuration complete. Please restart your computer for changes to take effect."
