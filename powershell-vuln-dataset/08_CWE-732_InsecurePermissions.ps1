
$path = "C:\App\Secrets"
New-Item -ItemType Directory -Path $path -Force

$acl  = Get-Acl $path
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Everyone", "FullControl",
    "ContainerInherit,ObjectInherit",
    "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl $path $acl


$regPath = "HKLM:\SOFTWARE\MyApp\Config"
New-Item -Path $regPath -Force | Out-Null

$regAcl  = Get-Acl $regPath
$regRule = New-Object System.Security.AccessControl.RegistryAccessRule(
    "Everyone", "FullControl",
    "ContainerInherit,ObjectInherit",
    "None", "Allow")
$regAcl.AddAccessRule($regRule)
Set-Acl $regPath $regAcl
