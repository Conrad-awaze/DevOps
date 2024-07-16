Remove-Module DevOpsToolkit
Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS
Import-Module '/Users/conrad.gauntlett/WorkArea/Repos/DBA_MISC/PowerShell/Modules/DevOpsToolkit'

$Account            = 'DevOps-Novosol-PROD'

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                   ACCOUNT SUMMARY                                                                  #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region Account Summary

$RDSSummaryColumns  = 'AvailabilityZone', 'DBInstanceIdentifier', 'DBSnapshotIdentifier', 'SnapshotCreateTime', 'SnapshotType', 'Status'
$Profiles           = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match $Account }
$Regions            = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$Summary            = Get-DoAWSDBInformation $Profiles $Regions
$Summary | Format-Table -AutoSize

#endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                   DYNAMODB TABLES                                                                  #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region DynamoDB Tables

# $ddbTables = Get-DoDDBTableInformation $Profiles $Regions 
# $ddbTables | Format-Table -AutoSize

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                LIST DYNAMODB BACKUPS                                                               #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region DynamoDB Backups

# $BackupsList    = Get-DDBBackupList -ProfileName $Profiles.ProfileName -Region eu-west-2
# $Columns        = 'TableName', 'BackupName', 'BackupCreationDateTime',    'BackupType' #  'BackupStatus','BackupSizeBytes',
# $BackupsList | Sort-Object BackupCreationDateTime -Descending | Select-Object -Property $Columns | Format-Table -AutoSize

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                          GET THE LATEST BACKUP FOR A TABLE                                                         #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Get the latest backup for a table

# $Table = 'terraform-locks'

# if($BackupsList){

#     $Backup = $BackupsList | Where-Object { $_.TableName -eq $Table } | Sort-Object -Property BackupCreationDateTime -Descending | Select-Object -First 1
#     $Bk = Get-DDBBackup -BackupArn $Backup.BackupArn -ProfileName $Profiles.ProfileName
#     $Bk.BackupDetails

# }

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                          CREATE A NEW BACKUP FOR THE TABLE                                                         #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Create a new backup for the table

# $Table = 'terraform-locks'
# $BackupNew = New-DDBBackup -TableName $Table -ProfileName $Profiles.ProfileName -BackupName "$Table-$(get-date -format "yyyy-MM-dd-HH-mm-ss")" -Region eu-west-2
# $BackupNew

# #endregion


# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                              CHECK NEW BACKUP DETAILS                                                              #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Check the new backup details

# $Bk = Get-DDBBackup -BackupArn $BackupNew.BackupArn -ProfileName $Profiles.ProfileName -Region eu-west-2
# $Bk.BackupDetails

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                  LIST ALL BACKUPS                                                                  #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region List all backups

# $BackupsList    = Get-DDBBackupList -ProfileName $Profiles.ProfileName -Region eu-west-2
# $Columns        = 'TableName', 'BackupName', 'BackupCreationDateTime',    'BackupType' #  'BackupStatus','BackupSizeBytes',
# $BackupsList | Sort-Object BackupCreationDateTime -Descending | Select-Object -Property $Columns | Format-Table -AutoSize

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                GET THE OLDEST BACKUP                                                               #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Get the oldest backup

# $Table = 'terraform-locks'
# $BackupOLDEST = $BackupsList | Where-Object { $_.TableName -eq $Table } | Sort-Object -Property BackupCreationDateTime  | Select-Object -First 1
# $Bk = Get-DDBBackup -BackupArn $BackupOLDEST.BackupArn -ProfileName $Profiles.ProfileName
# $Bk.BackupDetails

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                              DELETE THE OLDEST BACKUP                                                              #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Delete the oldest backup

# $BackupDelete = Remove-DDBBackup -BackupArn $BackupOLDEST.BackupArn -ProfileName $Profiles.ProfileName -Region eu-west-2 -Confirm:$false
# $BackupDelete.BackupDetails

# #endregion


# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                    RDS INSTANCES                                                                   #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region RDS Instances

$RDS        = Get-DoRDSDBSummary $Profiles $Regions 
$Snapshots  = Get-DoRDSSnapshotSummary $Profiles $Regions
$RDS | Format-Table -AutoSize

#endregion

# $DB = ($RDS | Where-Object { $_.Snapshots -gt 0 } | Select-Object -First 1).DBInstanceIdentifier
$DB  = 'drupal-db-prod'
$Snapshots | Where-Object {$_.DBInstanceIdentifier -eq $DB} | Select-Object $RDSSummaryColumns |
Sort-Object SnapshotCreateTime -Descending  |Format-Table -AutoSize