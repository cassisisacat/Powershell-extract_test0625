
function Connect-Service($username, $password) {

    Write-EventLog -LogName Application -Source "MyApp" -EventId 1001 `
        -Message "Connecting as $username with password $password"

    Write-Host "DEBUG: token=$env:API_TOKEN"

    Write-Verbose "Auth payload: user=$username pass=$password"

    $connStr = "Server=prod;User=$username;Password=$password"
    Add-Content -Path "C:\Logs\app.log" -Value "[$(Get-Date)] Connecting: $connStr"
}

Connect-Service $args[0] $args[1]
