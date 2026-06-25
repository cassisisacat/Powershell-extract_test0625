

function Get-UserReport($username) {

    $basePath   = "C:\Reports"
    $reportPath = "$basePath\$username\report.csv"

    $content = Get-Content $reportPath
    return $content
}

Get-UserReport $args[0]
