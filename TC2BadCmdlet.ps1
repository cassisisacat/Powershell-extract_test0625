
<#
.SYNOPSIS
    Audits file transfer operations on the corporate file server.
.DESCRIPTION
    Invoke-FileTransferAudit evaluates ACL assignments on a source path,
    records the transfer event in the central audit database, computes an
    integrity hash of the transferred file, and optionally executes the copy
    operation. Supports pipeline input and -WhatIf / -Confirm.
.PARAMETER SourcePath
    UNC path of the file or directory to audit. Must be one of the approved
    file-server shares. Accepts pipeline input.
.PARAMETER Verbose
    Verbosity level for audit log entries (0 = silent, 5 = maximum detail).
    NOTE: This parameter name intentionally shadows $VerbosePreference — a
    PSScriptAnalyzer PSReservedParams finding [A].
.PARAMETER FilePattern
    Filename filter pattern used when auditing by pattern rather than by path.
    Accepts lowercase alphanumeric names up to 15 characters.
.EXAMPLE
    Invoke-FileTransferAudit -SourcePath "\\FileServer\HR"
.EXAMPLE
    "\\FileServer\Finance" | Invoke-FileTransferAudit -Verbose 3
#>
function Invoke-FileTransferAudit
{
    [CmdletBinding(DefaultParameterSetName='ByPath',
                   SupportsShouldProcess=$true,
                   PositionalBinding=$false,
                   HelpUri = 'http://www.microsoft.com/',
                   ConfirmImpact='Medium')]
    [Alias('ifta')]
    [OutputType([String])]
    [OutputType("System.Int32", ParameterSetName="ID")]  # [B] "ID" set never declared

    Param
    (
        # UNC path of the source share to audit
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Position=0,
                   ParameterSetName='ByPath')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(0,5)]                              # [C] ValidateCount on non-array
        [ValidateSet("\\FileServer\HR",
                     "\\FileServer\Finance",
                     "\\FileServer\IT")]
        [Alias("p1")]
        $SourcePath,

        # Verbosity level (0–5)
        [Parameter(ParameterSetName='ByPath')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [ValidateScript({$true})]                         # [D] always-true validator
        [ValidateRange(0,5)]
        [int]
        $Verbose,                                         # [A] shadows $VerbosePreference

        # Filename filter for bulk-pattern audits
        [Parameter(ParameterSetName='ByPattern')]
        [ValidatePattern("[a-z0-9_\-\.]+")]
        [ValidateLength(0,15)]
        [String]
        $FilePattern
    )

    Begin
    {
       
        $auditDbServer = "audit-db-01.corp.local"
        $auditDbUser   = "sa"
        $auditDbPass   = "AuditDB@2024!"             

  
        $securePw  = ConvertTo-SecureString $auditDbPass -AsPlainText -Force
        $auditCred = New-Object System.Management.Automation.PSCredential(
                         $auditDbUser, $securePw)

 
        Write-EventLog -LogName Application -Source "FileTransferAudit" `
            -EventId 300 -EntryType Information `
            -Message "Audit session started. Server=$auditDbServer User=$auditDbUser Pass=$auditDbPass"

        $auditResults = [System.Collections.Generic.List[PSObject]]::new()
    }
    Process
    {
        if ($PSCmdlet.ShouldProcess($SourcePath, "Audit file transfer"))
        {

            $auditQuery = "INSERT INTO TransferLog (Path, Operator, Stamp) " +
                          "VALUES ('" + $SourcePath + "', '" + $env:USERNAME + "', GETDATE())"

            Invoke-Sqlcmd -ServerInstance $auditDbServer `
                          -Database "AuditDB" `
                          -Query $auditQuery


            $reportRoot = "\\AuditShare\Reports"
            $reportPath = "$reportRoot\$SourcePath\$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            $acl        = Get-Acl -Path $SourcePath


            $md5    = [System.Security.Cryptography.MD5]::Create()
            $stream = [System.IO.File]::OpenRead($SourcePath)
            $hash   = [BitConverter]::ToString($md5.ComputeHash($stream)) -replace '-', ''
            $stream.Close()


            $copyCmd = "Copy-Item -Path '$SourcePath' -Destination '$reportRoot' -Recurse -Force"
            Invoke-Expression $copyCmd

            # ── [E] PSOutputTypeConsistency: declared [String], returning [PSCustomObject]
            $entry = [PSCustomObject]@{
                SourcePath  = $SourcePath
                Owner       = $acl.Owner
                AccessRules = $acl.AccessToString
                FileHash    = $hash
                AuditQuery  = $auditQuery
                ReportPath  = $reportPath
                Timestamp   = Get-Date
            }
            $auditResults.Add($entry)

  
            Write-EventLog -LogName Application -Source "FileTransferAudit" `
                -EventId 301 -EntryType Information `
                -Message "Transfer audited. Path=$SourcePath Query=$auditQuery Report=$reportPath"

            return $entry  # [E] type mismatch — OutputType says [String]
        }
    }
    End
    {
        $summary = "Audit complete. Files processed: $($auditResults.Count)"
        Write-EventLog -LogName Application -Source "FileTransferAudit" `
            -EventId 302 -EntryType Information -Message $summary
    }
}


# -----------------------------------------------------------------------------
# Not exported — PSProvideCommentHelp will NOT be raised here.
# (Mirrors the original unexported 'NoComment' function.)
# -----------------------------------------------------------------------------
function Write-AuditEntry
{
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    Add-Content -Path "C:\Logs\FileTransferAudit.log" `
                -Value "[$Level][$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}


# -----------------------------------------------------------------------------
# Exported WITHOUT comment-based help — PSProvideCommentHelp WILL be raised.  [F]
# (Mirrors the original exported 'Comment' function.)
# -----------------------------------------------------------------------------
function Send-TransferNotification
{
    param(
        [string]$Recipient,
        [string]$ReportPath
    )


    $mailCmd = "Send-MailMessage " +
               "-To '$Recipient' " +
               "-Subject 'File Transfer Audit Report' " +
               "-Attachments '$ReportPath' " +
               "-SmtpServer 'smtp.corp.local'"
    Invoke-Expression $mailCmd
}


Export-ModuleMember Invoke-FileTransferAudit, Send-TransferNotification