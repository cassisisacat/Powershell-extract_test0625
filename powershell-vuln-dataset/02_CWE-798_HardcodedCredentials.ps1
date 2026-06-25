
$dbUser     = "sa"
$dbPassword = "P@ssw0rd123!"
$apiToken   = "ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ123456"

$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=prod-db;User=$dbUser;Password=$dbPassword"
$conn.Open()
