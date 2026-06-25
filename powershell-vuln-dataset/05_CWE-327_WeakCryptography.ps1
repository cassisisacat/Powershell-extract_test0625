
function Get-PasswordHash($password) {
    $md5   = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($password)
    $hash  = $md5.ComputeHash($bytes)
    return [BitConverter]::ToString($hash) -replace '-', ''
}


$sha1  = [System.Security.Cryptography.SHA1]::Create()


$des   = [System.Security.Cryptography.DESCryptoServiceProvider]::new()


$rc2   = [System.Security.Cryptography.RC2CryptoServiceProvider]::new()
