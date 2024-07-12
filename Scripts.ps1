Import-Module AWS.Tools.Common
Import-Module AWS.Tools.DynamoDBv2
Import-Module AWS.Tools.RDS
Import-Module AWS.Tools.Backup

$RegexGroup             = 'AccountNumber'
$RegexGroupAccountName  = 'AccountName'
$RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$"
$RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$" 
$RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
$Profiles                = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match 'DevOps-Owner-Services-PROD' }
$Regions                = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"

$ddbBackupList          = Get-DDBBackupList -ProfileName $Profile.ProfileName 
$ddbTableList           = Get-DDBTableList -ProfileName $Profile.ProfileName


$RDSInstances = Get-RDSDBInstance -ProfileName $Profiles.ProfileName -Region eu-west-2

$Inst = @()
$Snapshots = @()
foreach ($Instance in $RDSInstances) {
    
    $DBInstanceArn      = $Instance.DBInstanceArn
    # $Tags               = Get-RDSTagForResource -ResourceName $DBInstanceArn -ProfileName $Profile.ProfileName
    $Shots          = Get-RDSDBSnapshot -ProfileName $Profiles.ProfileName -DBInstanceIdentifier $DBInstanceArn
    #$DBClusterSnapshots = Get-RDSDBClusterSnapshot -ProfileName $Profile.ProfileName -DBClusterIdentifier $DBInstanceArn

    $Sum = [PSCustomObject]@{

        #DBName                  = $Instance.DBName
        DBInstanceIdentifier    = $Instance.DBInstanceIdentifier
        Engine                  = $Instance.Engine
        EngineVersion           = $Instance.EngineVersion
        InstanceCreateTime      = $Instance.InstanceCreateTime
        #DBInstanceClass         = $Instance.DBInstanceClass
        BackupRetention         = $Instance.BackupRetentionPeriod
        #StorageThroughput       = $Instance.StorageThroughput
        #Tags                    = $Tags
        Snapshots               = ($Shots | Measure-Object).Count
        #DBClusterSnapshots      = ($DBClusterSnapshots | Measure-Object).Count
        
    }
    $Inst += $Sum
    $Snapshots += $Shots
    
}
$Inst | Format-Table -AutoSize

$Snap = @()
$Snapshots | ForEach-Object {

    $Sum = [PSCustomObject]@{

        DBInstanceIdentifier    = $_.DBInstanceIdentifier
        DBSnapshotIdentifier    = $_.DBSnapshotIdentifier
        SnapshotCreateTime      = $_.SnapshotCreateTime
        Engine                  = $_.Engine
        SnapshotType            = $_.SnapshotType
        Status                  = $_.Status
        
    }
    $Snap += $Sum
}
$Snap | Format-Table -AutoSize










$SnapshotColumns = @(
    #'AvailabilityZone',
    'DBInstanceIdentifier',
    'DBSnapshotIdentifier',
    'InstanceCreateTime',
    'SnapshotCreateTime',
    'Engine',
    'SnapshotType',
    'Status'
)
$Snapshots | Select-Object -Property $SnapshotColumns | Sort-Object SnapshotCreateTime -Descending| Format-Table -AutoSize


Get-Command -Module AWS.Tools.RDS

$SnapshotColumns = @(
    #'AvailabilityZone',
    'DBInstanceIdentifier',
    'DBSnapshotIdentifier',
    'InstanceCreateTime',
    'SnapshotCreateTime',
    'Engine',
    'SnapshotType',
    'Status'
)
$Snapshots | Select-Object -Property $SnapshotColumns | Sort-Object SnapshotCreateTime -Descending| Format-Table -AutoSize







$Snap = @()
$Snapshots | ForEach-Object {

    $DBInstanceIdentifier    = $_.DBInstanceIdentifier
    $DBSnapshotIdentifier    = $_.DBSnapshotIdentifier
    $SnapshotCreateTime      = $_.SnapshotCreateTime
    $Engine                  = $_.Engine
    $SnapshotType            = $_.SnapshotType
    $Status                  = $_.Status

    $Sum = [PSCustomObject]@{

        DBInstanceIdentifier    = $DBInstanceIdentifier
        DBSnapshotIdentifier    = $DBSnapshotIdentifier
        SnapshotCreateTime      = $SnapshotCreateTime
        Engine                  = $Engine
        SnapshotType            = $SnapshotType
        Status                  = $Status
        
    }
    $Snap += $Sum
}
$Snap | Format-Table -AutoSize

Get-RDSDBSnapshot -ProfileName DevOps-Owner-Services-PROD -DBInstanceIdentifier 'notificationdbprod'


$RDSInstances = Get-RDSDBInstance -ProfileName $Profiles.ProfileName -Region eu-west-2

$RDSInstances.DBInstanceArn[0]
$Shots = Get-RDSDBSnapshot -ProfileName $Profiles.ProfileName -DBInstanceIdentifier $RDSInstances.DBInstanceArn[0]



# $BackupSummary  = @()

# foreach ($Backup in $BackupsList) {
    
#     $Backup = [PSCustomObject]@{

#     TableName           = $BackupsList.TableName
#     BackupName          = $BackupsList.BackupName
#     CreationDateTime    = $BackupsList.BackupCreationDateTime
#     BackupSizeBytes     = $BackupsList.BackupSizeBytes
#     BackupType          = $BackupsList.BackupType
#     BackupStatus        = $BackupsList.BackupStatus
    
#     }
#     $BackupSummary += $Backup
# }

# $BackupSummary #| Format-Table -AutoSize

# $Summary    = @()
# foreach ($Profile in $Profiles) {

#     $Regions | ForEach-Object {

#         $RDSInstances   = Get-RDSDBInstance -ProfileName $Profile.ProfileName -Region $_
#         $ddbTables      = Get-DDBTableList -ProfileName $Profile.ProfileName -Region $_

#         $Sum = [PSCustomObject]@{

#             Account             = $Profile.ProfileName
#             Region              = $_
#             RDSInstances        = ($RDSInstances.DBInstanceIdentifier | Measure-Object).Count
#             DynamoDBTables      = $ddbTables.Count
            
            
#         }

#         $condition = $Sum.RDSInstances + $Sum.DynamoDBTables
#         if ($condition -gt 0) {
#             $Summary += $Sum
#         }
#         # $Summary += $Sum

#     }

# }
# $Summary 


# $Summary | Where-Object { $($_.RDSInstances) + $($_.DynamoDBTables) -ge 0 } | Format-Table -AutoSize 

# $ddbTableList = Get-DDBTableList -ProfileName DevOps-Apex-PROD
# Get-DDBTable -TableName 'prod-accommodation' -ProfileName DevOps-Apex-PROD
# $ddbTables  = @()
# foreach ($ddbTable in $ddbTableList) {
    
#     $Table = Get-DDBTable -TableName $ddbTable -ProfileName DevOps-Apex-PROD

#     $Sum = [PSCustomObject]@{

#         TableName           = $Table.TableName
#         #TableArn            = $Table.TableArn
#         TableStatus         = $Table.TableStatus
#         CreationDateTime    = $Table.CreationDateTime
#         ItemCount           = $Table.ItemCount
#         TableSizeBytes      = $Table.TableSizeBytes
#         #BillingModeSummary  = $Table.BillingModeSummary
        
#     }
#     $ddbTables += $Sum
# }
# $ddbTables | Format-Table -AutoSize


# $RDSInstances = Get-RDSDBInstance -ProfileName DevOps-Owner-Services-PROD
# $RDSInstances | Where-Object { $_.DBInstanceIdentifier -eq 'notificationdbprod' } 
# $RDSInstances.DBInstanceArn[0]
# $RegexGroup = 'AccountNumber'
# $RegexAccountNumber = "(?<$RegexGroup>\d+):db.+$"
# (($RDSInstances.DBInstanceArn[0] | Select-String -Pattern $RegexAccountNumber).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value 











# $Summary    = @()
# foreach ($Profile in $Profiles) {

#     $Regions | ForEach-Object {

#         $RDSInstances   = Get-RDSDBInstance -ProfileName $Profile.ProfileName -Region $_
#         $ddbTables      = Get-DDBTableList -ProfileName $Profile.ProfileName -Region $_
#         $AccountID      = (($RDSInstances.DBInstanceArn[0] | Select-String -Pattern $RegexAccountNumber).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value

#         $Sum = [PSCustomObject]@{

#             Account             = $Profile.ProfileName
#             Region              = $_
#             RDSInstances        = ($RDSInstances.DBInstanceIdentifier | Measure-Object).Count
#             DynamoDBTables      = $ddbTables.Count
#             AccountID           = (($RDSInstances.DBInstanceArn[0] | Select-String -Pattern $RegexAccountNumber).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value 
            
            
#         }

#         $condition = $Sum.RDSInstances + $Sum.DynamoDBTables
#         if ($condition -gt 0) {
#             $Summary += $Sum
#         }
#         # $Summary += $Sum

#     }

# }
# $Summary 
# Find-Module -Name AWS.Tools.Acc*
# Install-Module -Name AWS.Tools.Account -Force -AllowClobber -Scope CurrentUser
# Get-AWSCredentials -ListProfileDetail
# Install-Module AWS.Tools.Installer ; Update-AWSToolsModule

# Import-Module AWS.Tools.Common
# Import-Module AWS.Tools.DynamoDBv2
# Import-Module AWS.Tools.RDS

# Get-Module -ListAvailable -Name AWS.Tools.* | Format-Table -AutoSize

# Get-ACCTRegionOptStatus -ProfileName DevOps-Owner-Services-PROD
# Get-Command -Module AWS.Tools.RDS

# $Tags = Get-RDSTagForResource -ResourceName $($RDSInstances[0].DBInstanceArn) -ProfileName DevOps-Owner-Services-PROD
# $Tags
# $Snapshots = Get-RDSDBSnapshot -ProfileName DevOps-Owner-Services-PROD -DBInstanceIdentifier $($RDSInstances[1].DBInstanceArn)
# $Snapshots | Sort-Object SnapshotCreateTime -Descending 

# Get-RDSDBClusterAutomatedBackup -DBClusterIdentifier 'places-api' -ProfileName DevOps-Owner-Services-PROD

# $RDSInstances = Get-RDSDBInstance -ProfileName DevOps-Owner-Services-PROD

# $RDSInstances[0].DBInstanceArn
# $Summary = @()
# $RDSInstances | ForEach-Object {

#     $Sum = [PSCustomObject]@{

#         DBName              = $_.DBName
#         Engine              = $_.Engine
#         EngineVersion       = $_.EngineVersion
#         #DBInstanceIdentifier= $_.DBInstanceIdentifier
#         InstanceCreateTime  = $_.InstanceCreateTime
#         DBInstanceClass     = $_.DBInstanceClass
#         #BackupRetention = $_.BackupRetentionPeriod
#         #StorageThroughput   = $_.StorageThroughput
        
#     }
#     $Summary += $Sum

# } 
# $Summary | Format-Table -AutoSize




# $DB = Get-RDSDBCluster -ProfileName 'DevOps-Owner-DK - Prod'
# $DB.DBClusterIdentifier
# Get-RDSDBInstance -DBInstanceIdentifier
# $DB.DatabaseName

# Get-DDBTableList -ProfileName 'DevOps-Apex-PROD'

# $ddbTable = Get-DDBTable -TableName 'prod-accommodation' -ProfileName DevOps-Apex-PROD

# $ddbTable | gm

# Import-Module AWS.Tools.RDS
# Install-Module -Name AWS.Tools.RDSDataService -Scope CurrentUser -Force -AllowClobber
# install-module -Name AWS.Tools.Backup -Force -AllowClobber -Scope CurrentUser


# Get-Command -Module AWS.Tools.Common
# Get-Command -Module AWS.Tools.RDS
# $RDSInstances = Get-RDSDBInstance -ProfileName DevOps-AVR-Guest-Experience-PROD
# find-module -Name AWS.Tools.* | sort Name | Format-Table -AutoSize

# Get-RDSDBInstance -ProfileName DevOps-AVR-Guest-Experience-PROD
# Get-RDSDBLogFiles -DBInstanceIdentifier 'places-api' -ProfileName DevOps-AVR-Guest-Experience-PROD
# Get-RDSDBCluster -ProfileName DevOps-AVR-Guest-Experience-PROD

# Get-Help Get-BAKReportJobList -Full
# Get-BAKBackupJobList -ProfileName DevOps-AVR-Guest-Experience-PROD

# Get-AWSRegion
# Get-AWSService -Service RDS | gm





