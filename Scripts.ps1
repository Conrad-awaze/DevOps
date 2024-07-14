Remove-Module DevOpsToolkit
Import-Module AWS.Tools.Common
Import-Module AWS.Tools.DynamoDBv2
Import-Module AWS.Tools.RDS
Import-Module '/Users/conrad.gauntlett/WorkArea/Repos/DBA_MISC/PowerShell/Modules/DevOpsToolkit'


$Profiles   = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match 'DevOps-AVR-Guest-Experience-PROD' }
$Regions    = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"

$Summary    = Get-DoAWSDBInformation $Profiles $Regions
$Summary    | Format-Table -AutoSize

$ddbTables = Get-DoDDBTableInformation $Profiles $Regions # | Format-Table -AutoSize
$ddbTables | Format-Table -AutoSize





