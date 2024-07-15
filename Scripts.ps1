Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS
Import-Module '/Users/conrad.gauntlett/WorkArea/Repos/DBA_MISC/PowerShell/Modules/DevOpsToolkit'

$Account            = 'DevOps-AVR-Guest-Payments-PROD'
$RDSSummaryColumns  = 'AvailabilityZone', 'DBSnapshotIdentifier', 'SnapshotCreateTime', 'SnapshotType', 'Status'
$Profiles           = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match $Account }
$Regions            = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$Summary            = Get-DoAWSDBInformation $Profiles $Regions


$ddbTables = Get-DoDDBTableInformation $Profiles $Regions 
$ddbTables | Format-Table -AutoSize


$BackupsList    = Get-DDBBackupList -ProfileName $Profiles.ProfileName -Region eu-west-2
$Columns        = 'TableName', 'BackupName', 'BackupCreationDateTime',    'BackupType' #  'BackupStatus','BackupSizeBytes',
$BackupsList | Select-Object -Property $Columns | Format-Table -AutoSize

$Table = 'terraform-locks'
$Backup = $BackupsList | Where-Object { $_.TableName -eq $Table } | Sort-Object -Property BackupCreationDateTime -Descending | Select-Object -First 1
$Bk = Get-DDBBackup -BackupArn $Backup.BackupArn -ProfileName $Profiles.ProfileName
$Bk.BackupDetails.BackupArn

$Table = 'terraform-locks'
$Backup = New-DDBBackup -TableName $Table -ProfileName $Profiles.ProfileName -BackupName "$Table-$(get-date -format "yyyy-MM-dd-HH-mm-ss")" -Region eu-west-2
$Backup

Get-Command -Module AWS.Tools.DynamoDBv2

$BackupDelete = Remove-DDBBackup -BackupArn $Backup.BackupArn -ProfileName $Profiles.ProfileName -Region eu-west-2 -Confirm:$false
$BackupDelete.BackupDetails