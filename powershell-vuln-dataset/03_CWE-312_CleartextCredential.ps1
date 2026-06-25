
$password   = "SuperSecret99"
$securePass = ConvertTo-SecureString $password -AsPlainText -Force

$cred = New-Object PSCredential("admin", $securePass)
Invoke-Command -ComputerName "server01" -Credential $cred -ScriptBlock {
    Get-Service
}
