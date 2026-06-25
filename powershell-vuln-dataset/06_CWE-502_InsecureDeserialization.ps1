
function Load-Config($configPath) {

    $config = Import-CliXml -Path $configPath
    return $config
}


$userSuppliedUrl = $args[0]
$response = Invoke-WebRequest -Uri $userSuppliedUrl
$obj      = $response.Content | ConvertFrom-Clixml

Load-Config $args[1]
