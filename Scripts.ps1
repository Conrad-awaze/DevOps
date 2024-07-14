Remove-Module DevOpsToolkit
Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS
Import-Module '/Users/conrad.gauntlett/WorkArea/Repos/DBA_MISC/PowerShell/Modules/DevOpsToolkit'

$Profiles   = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match 'DevOps-Owner-Services-PROD' }
$Regions    = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$Summary    = Get-DoAWSDBInformation $Profiles $Regions
$Summary    | Format-Table -AutoSize

$ddbTables = Get-DoDDBTableInformation $Profiles $Regions 
$ddbTables | Format-Table -AutoSize

Get-DoRDSDBSummary $Profiles $Regions | Format-Table -AutoSize

# function Get-DoRDSDBSummary {
#     [CmdletBinding()]
#     param (

#         $Profiles,
#         $Regions
        
#     )
    
#     begin {

#         $Inst       = @()
#         # $Snap       = @()
#         # $Snapshots  = @()
        
#     }
    
#     process {

#         $Regions | ForEach-Object {
    
#             $RDSInstances = Get-RDSDBInstance -ProfileName $Profiles.ProfileName -Region $_
        
#             if ($RDSInstances) {
                
#                 foreach ($Instance in $RDSInstances) {
                
#                     $DBInstanceArn      = $Instance.DBInstanceArn
#                     # $Tags               = Get-RDSTagForResource -ResourceName $DBInstanceArn -ProfileName $Profile.ProfileName
#                     $Shots              = Get-RDSDBSnapshot -ProfileName $Profiles.ProfileName -DBInstanceIdentifier $DBInstanceArn
#                     #$DBClusterSnapshots = Get-RDSDBClusterSnapshot -ProfileName $Profile.ProfileName -DBClusterIdentifier $DBInstanceArn
            
#                     $Sum = [PSCustomObject]@{
            
#                         Region                 = $_
#                         DBInstanceIdentifier    = $Instance.DBInstanceIdentifier
#                         Engine                  = $Instance.Engine
#                         Version                 = $Instance.EngineVersion
#                         InstanceCreateTime      = $Instance.InstanceCreateTime
#                         #DBInstanceClass         = $Instance.DBInstanceClass
#                         BackupRetention         = $Instance.BackupRetentionPeriod
#                         #StorageThroughput       = $Instance.StorageThroughput
#                         #Tags                    = $Tags
#                         Snapshots               = ($Shots | Measure-Object).Count
#                         #DBClusterSnapshots      = ($DBClusterSnapshots | Measure-Object).Count
            
#                     }
#                     $Inst += $Sum
#                     #$Snapshots += $Shots
            
#                 }
            
#                 # $Snapshots | ForEach-Object {
            
#                 #     $Sum = [PSCustomObject]@{
            
#                 #         DBInstanceIdentifier    = $_.DBInstanceIdentifier
#                 #         DBSnapshotIdentifier    = $_.DBSnapshotIdentifier
#                 #         SnapshotCreateTime      = $_.SnapshotCreateTime
#                 #         Engine                  = $_.Engine
#                 #         SnapshotType            = $_.SnapshotType
#                 #         Status                  = $_.Status
            
#                 #     }
#                 #     $Snap += $Sum
#                 # }
#             }
         
#         }
        
#     }
    
#     end {

#         $Inst
        
#     }
# }




# $RDSInstances = Get-RDSDBInstance -ProfileName $Profiles.ProfileName -Region eu-west-2

# $Inst = @()
# $Snap = @()
# $Snapshots = @()
# foreach ($Instance in $RDSInstances) {
    
#     $DBInstanceArn      = $Instance.DBInstanceArn
#     # $Tags               = Get-RDSTagForResource -ResourceName $DBInstanceArn -ProfileName $Profile.ProfileName
#     $Shots          = Get-RDSDBSnapshot -ProfileName $Profiles.ProfileName -DBInstanceIdentifier $DBInstanceArn
#     #$DBClusterSnapshots = Get-RDSDBClusterSnapshot -ProfileName $Profile.ProfileName -DBClusterIdentifier $DBInstanceArn

#     $Sum = [PSCustomObject]@{

#         #DBName                  = $Instance.DBName
#         DBInstanceIdentifier    = $Instance.DBInstanceIdentifier
#         Engine                  = $Instance.Engine
#         EngineVersion           = $Instance.EngineVersion
#         InstanceCreateTime      = $Instance.InstanceCreateTime
#         #DBInstanceClass         = $Instance.DBInstanceClass
#         BackupRetention         = $Instance.BackupRetentionPeriod
#         #StorageThroughput       = $Instance.StorageThroughput
#         #Tags                    = $Tags
#         Snapshots               = ($Shots | Measure-Object).Count
#         #DBClusterSnapshots      = ($DBClusterSnapshots | Measure-Object).Count
        
#     }
#     $Inst += $Sum
#     $Snapshots += $Shots
    
# }

# $Snapshots | ForEach-Object {

#     $Sum = [PSCustomObject]@{

#         DBInstanceIdentifier    = $_.DBInstanceIdentifier
#         DBSnapshotIdentifier    = $_.DBSnapshotIdentifier
#         SnapshotCreateTime      = $_.SnapshotCreateTime
#         Engine                  = $_.Engine
#         SnapshotType            = $_.SnapshotType
#         Status                  = $_.Status
        
#     }
#     $Snap += $Sum
# }
# $Inst | Format-Table -AutoSize




