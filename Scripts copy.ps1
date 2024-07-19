docker cp '/Users/conrad.gauntlett/.local/share/powershell/Modules/AWS.Tools.DynamoDBv2' PSU:/opt/microsoft/powershell/7/Modules/AWS.Tools.DynamoDBv2/

docker cp '/Users/conrad.gauntlett/.local/share/powershell/Modules/AWS.Tools.Common' PSU:/opt/microsoft/powershell/7/Modules/AWS.Tools.Common/

docker cp '/Users/conrad.gauntlett/.local/share/powershell/Modules/AWS.Tools.RDS' PSU:/opt/microsoft/powershell/7/Modules/AWS.Tools.RDS/
docker cp '/Users/conrad.gauntlett/WorkArea/aws' PSU:/root/.aws/

docker run --name 'PSU' -it -p 5000:5000 ironmansoftware/universal

# # Remove-Module DevOpsToolkit
# Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS
# Import-Module '/Users/conrad.gauntlett/WorkArea/Repos/DBA_MISC/PowerShell/Modules/DevOpsToolkit'

# $Account            = 'DevOps-Novosol-PROD'

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                   ACCOUNT SUMMARY                                                                  #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Account Summary

# $RDSSummaryColumns  = 'AvailabilityZone', 'DBInstanceIdentifier', 'DBSnapshotIdentifier', 'SnapshotCreateTime', 'SnapshotType', 'Status'
# $Profiles           = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match $Account }
# $Regions            = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
# $Summary            = Get-DoAWSDBInformation $Profiles $Regions
# $Summary | Format-Table -AutoSize

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                   DYNAMODB TABLES                                                                  #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region DynamoDB Tables

# $ddbTables = Get-DoDDBTableInformation $Profiles $Regions 
# $ddbTables | Format-Table -AutoSize

# #endregion

# # $Region = 'eu-central-1'

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                LIST DYNAMODB BACKUPS                                                               #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region DynamoDB Backups

# $BackupsList = @()
# $RegexRegion = '(?<region>\w+-\w+-\d+)'
# $Regions | ForEach-Object {

#     $BkList    = Get-DDBBackupList -ProfileName $Profiles.ProfileName -Region $_
    
#     $BkList | ForEach-Object {

#         $Bk = [PSCustomObject]@{

#             Region = (($_.BackupArn | Select-String -Pattern $RegexRegion).Matches.Groups | Where-Object { $_.Name -eq 'region' }).Value
#             BackupArn = $_.BackupArn
#             BackupCreationDateTime = $_.BackupCreationDateTime
#             BackupName = $_.BackupName
#             BackupSizeBytes = $_.BackupSizeBytes
#             BackupStatus = $_.BackupStatus
#             BackupType = $_.BackupType
#             TableArn = $_.TableArn
#             TableId = $_.TableId
#             TableName = $_.TableName
#         }
#         $BackupsList += $Bk
#     }
# }

# $Columns        = 'Region', 'TableName', 'BackupName', 'BackupCreationDateTime',    'BackupType' #  'BackupStatus','BackupSizeBytes',
# $BackupsList | Sort-Object BackupCreationDateTime -Descending | Select-Object -Property $Columns | Format-Table -AutoSize

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                          GET THE LATEST BACKUP FOR A TABLE                                                         #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Get the latest backup for a table

# # $RegexRegion = '(?<region>\w+-\w+-\d+)'
# # $Region = (($BackupsList.BackupArn | Select-String -Pattern $RegexRegion).Matches.Groups | Where-Object { $_.Name -eq 'region' }).Value

# $Table = 'terraform-locks'

# if($BackupsList){

#     $Backup = $BackupsList | Where-Object { $_.TableName -eq $Table } | Sort-Object -Property BackupCreationDateTime -Descending | Select-Object -First 1
#     $Bk = Get-DDBBackup -BackupArn $Backup.BackupArn -ProfileName $Profiles.ProfileName -Region $Backup.Region
#     $Bk.BackupDetails

# }

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                          CREATE A NEW BACKUP FOR THE TABLE                                                         #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Create a new backup for the table

# $Table = 'terraform-locks'
# $BackupNew = New-DDBBackup -TableName $Table -ProfileName $Profiles.ProfileName -BackupName "$Table-$(get-date -format "yyyy-MM-dd-HH-mm-ss")" -Region eu-central-1
# $BackupNew

# #endregion


# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                              CHECK NEW BACKUP DETAILS                                                              #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Check the new backup details

# $Bk = Get-DDBBackup -BackupArn $BackupNew.BackupArn -ProfileName $Profiles.ProfileName -Region eu-central-1
# $Bk.BackupDetails

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                  LIST ALL BACKUPS                                                                  #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region List all backups

# $BackupsList = @()
# $RegexRegion = '(?<region>\w+-\w+-\d+)'
# $Regions | ForEach-Object {

#     $BkList    = Get-DDBBackupList -ProfileName $Profiles.ProfileName -Region $_
    
#     $BkList | ForEach-Object {

#         $Bk = [PSCustomObject]@{

#             Region = (($_.BackupArn | Select-String -Pattern $RegexRegion).Matches.Groups | Where-Object { $_.Name -eq 'region' }).Value
#             BackupArn = $_.BackupArn
#             BackupCreationDateTime = $_.BackupCreationDateTime
#             BackupName = $_.BackupName
#             BackupSizeBytes = $_.BackupSizeBytes
#             BackupStatus = $_.BackupStatus
#             BackupType = $_.BackupType
#             TableArn = $_.TableArn
#             TableId = $_.TableId
#             TableName = $_.TableName
#         }
#         $BackupsList += $Bk
#     }
# }

# $Columns        = 'Region', 'TableName', 'BackupName', 'BackupCreationDateTime',    'BackupType' #  'BackupStatus','BackupSizeBytes',
# $BackupsList | Sort-Object BackupCreationDateTime -Descending | Select-Object -Property $Columns | Format-Table -AutoSize

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                GET THE OLDEST BACKUP                                                               #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Get the oldest backup

# $Table = 'terraform-locks'
# $BackupOLDEST = $BackupsList | Where-Object { $_.TableName -eq $Table } | Sort-Object -Property BackupCreationDateTime  | Select-Object -First 1
# $Bk = Get-DDBBackup -BackupArn $BackupOLDEST.BackupArn -ProfileName $Profiles.ProfileName -Region $BackupOLDEST.Region
# $Bk.BackupDetails

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                              DELETE THE OLDEST BACKUP                                                              #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region Delete the oldest backup

# $BackupDelete = Remove-DDBBackup -BackupArn $BackupOLDEST.BackupArn -ProfileName $Profiles.ProfileName -Region $BackupOLDEST.Region -Confirm:$false
# $BackupDelete.BackupDetails

# #endregion


# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                    RDS INSTANCES                                                                   #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region RDS Instances

# $RDS        = Get-DoRDSDBSummary $Profiles $Regions 
# $Snapshots  = Get-DoRDSSnapshotSummary $Profiles $Regions
# $RDS | Format-Table -AutoSize

# #endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                                    RDS SNAPSHOTS                                                                   #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region RDS Snapshots

# $DB  = 'novasol-db-prod'
# $Snapshots | Where-Object {$_.DBInstanceIdentifier -eq $DB} | Select-Object $RDSSummaryColumns |
# Sort-Object SnapshotCreateTime -Descending  |Format-Table -AutoSize

# #endregion