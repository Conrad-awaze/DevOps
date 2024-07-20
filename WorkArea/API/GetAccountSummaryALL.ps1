# /DBMonitor/GetAccountSummaryALL/

Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS

$Regions        = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$AccountProfiles = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }

$AccountSummaryALL    = Get-DoAWSDBInformation $AccountProfiles $Regions

return $AccountSummaryALL