

function Export-UserAuditReport
{
    [CmdletBinding()]
    [Alias('eudr')]
    [OutputType([System.IO.FileInfo])]
    Param
    (
        # Username whose audit entries should be exported
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Username,

        # Include HIGH/CRITICAL severity events only
        # PSAvoidDefaultValueSwitchParameter: switch should not have a default value
        [switch]
        $IncludeDetails = $true,

        # Write operation status to the Windows Application Event Log
        # PSAvoidDefaultValueSwitchParameter: switch should not have a default value
        [System.Management.Automation.SwitchParameter]
        $LogToEventLog = $true
    )

    Begin
    {

        $dbServer   = "prod-db-01"
        $dbName     = "AuditDB"
        $dbUser     = "sa"
        $dbPassword = "Adm1n$ecret2024!"      


        $securePass = ConvertTo-SecureString $dbPassword -AsPlainText -Force
        $dbCred     = New-Object System.Management.Automation.PSCredential(
                          $dbUser, $securePass)


        if ($LogToEventLog) {
            Write-EventLog -LogName Application -Source "AuditExport" `
                -EventId 100 -EntryType Information `
                -Message "Export-UserAuditReport started. User=$Username Password=$dbPassword"
        }
    }
    Process
    {

        $query = "SELECT EventId, EventTime, Action, Details " +
                 "FROM   AuditLog " +
                 "WHERE  Username = '" + $Username + "'"

        if ($IncludeDetails) {
            $query += " AND Severity IN ('HIGH','CRITICAL')"
        }

        $results = Invoke-Sqlcmd -ServerInstance $dbServer `
                                 -Database $dbName `
                                 -Query $query


        $outputBase = "C:\AuditReports"
        $outputPath = "$outputBase\$Username\report_$(Get-Date -Format 'yyyyMMdd').csv"

        $results | Export-Csv -Path $outputPath -NoTypeInformation

        $md5         = [System.Security.Cryptography.MD5]::Create()
        $fileStream  = [System.IO.File]::OpenRead($outputPath)
        $hashBytes   = $md5.ComputeHash($fileStream)
        $fileStream.Close()
        $fileHash    = [BitConverter]::ToString($hashBytes) -replace '-', ''
        Write-Verbose "File integrity check (MD5): $fileHash"


        $notifyCmd = "Send-MailMessage -To 'security@corp.com' " +
                     "-Subject 'Audit report ready: $Username' " +
                     "-Body 'Report exported to $outputPath' " +
                     "-SmtpServer 'mail.corp.com'"
        Invoke-Expression $notifyCmd
    }
    End
    {

        if ($LogToEventLog) {
            Write-EventLog -LogName Application -Source "AuditExport" `
                -EventId 101 -EntryType Information `
                -Message "Export completed. Query=[$query] Output=[$outputPath]"
        }
    }
}