<#
  cau-hinh-zoom-shell.ps1
  Dat Zoom Rooms lam "shell" (thay Explorer) CHI cho mot tai khoan.
  Yeu cau: Windows Enterprise / Education / IoT Enterprise, chay bang quyen Administrator.

  Cach dung (PowerShell Admin):
    .\cau-hinh-zoom-shell.ps1                      # bat cho tai khoan suca
    .\cau-hinh-zoom-shell.ps1 -UserName suca       # chi dinh tai khoan
    .\cau-hinh-zoom-shell.ps1 -Remove              # go bo, tra tai khoan ve Explorer

  Neu bi chan chay script:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#>

param(
    [string]$UserName = "suca",
    [string]$ZoomPath = "C:\Program Files\ZoomRooms\bin\ZoomRooms.exe",
    [switch]$Remove
)

# 1. Kiem tra quyen Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Host "Hay chay PowerShell bang quyen Administrator." -ForegroundColor Red; exit 1 }

# 2. Bat tinh nang Shell Launcher (neu chua bat)
$feature = Get-WindowsOptionalFeature -Online -FeatureName Client-EmbeddedShellLauncher
if ($feature.State -ne "Enabled") {
    Write-Host "Dang bat Shell Launcher... (co the can khoi dong lai may)"
    Enable-WindowsOptionalFeature -Online -FeatureName Client-EmbeddedShellLauncher -All -NoRestart | Out-Null
    Write-Host "Da bat. Hay KHOI DONG LAI may, sau do chay lai script nay." -ForegroundColor Yellow
    exit 0
}

# 3. Lay SID cua tai khoan
try {
    $SID = (New-Object System.Security.Principal.NTAccount("$env:COMPUTERNAME\$UserName")).Translate(
            [System.Security.Principal.SecurityIdentifier]).Value
} catch {
    Write-Host "Khong tim thay tai khoan '$UserName'. Kiem tra bang lenh: net user" -ForegroundColor Red
    exit 1
}

$NameSpace = "root\standardcimv2\embedded"
$SL = [wmiclass]"\\localhost\${NameSpace}:WESL_UserSetting"

if ($Remove) {
    $SL.RemoveCustomShell($SID) | Out-Null
    Write-Host "Da go shell rieng cua '$UserName'. Tai khoan nay se chay Explorer binh thuong." -ForegroundColor Green
    exit 0
}

# 4. Kiem tra duong dan Zoom Rooms (sai duong dan se ra man hinh den)
if (-not (Test-Path $ZoomPath)) {
    Write-Host "Khong thay file: $ZoomPath" -ForegroundColor Red
    Write-Host "Tim duong dan that bang lenh:"
    Write-Host '  Get-ChildItem "C:\Program Files*" -Recurse -Filter "ZoomRooms.exe" -ErrorAction SilentlyContinue | Select FullName'
    exit 1
}

# 5. Dat shell rieng cho tai khoan, KHONG dung Default Shell (de tai khoan khac khong bi anh huong)
$SL.SetCustomShell($SID, $ZoomPath, $null, $null, 0) | Out-Null
$SL.SetEnabled($true) | Out-Null

Write-Host "Xong. '$UserName' se vao thang Zoom Rooms, khong chay Explorer." -ForegroundColor Green
Write-Host "Cac tai khoan khac van chay Explorer binh thuong."
Write-Host "Cau hinh hien tai:"
Get-WmiObject -Namespace $NameSpace -Class WESL_UserSetting | Select-Object Sid, Shell | Format-Table -AutoSize
