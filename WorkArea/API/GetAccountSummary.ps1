
# /GetAccountSummary/:AccountName
# $AccountName    = 'Apex-PROD' Owner-DK-Prod. Owner-Services-PROD AVR-Guest-Payments-PROD

Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS

$Regions            = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$CurrentProfiles    = Get-AWSCredentials -ListProfileDetail

switch ($AccountName) {

    {$AccountName -eq 'AllAccounts'} { 

        $Profiles = 'DevOps*'
        $AccountProfiles    = $CurrentProfiles | Where-Object { $_.ProfileName -match $Profiles }
        $AccountSummary     = Get-DoAWSDBInformation $AccountProfiles $Regions

        return $AccountSummary
    }
    {($CurrentProfiles.ProfileName | ForEach-Object { $_ -match $AccountName }).Contains($true)} {

        $AccountProfiles    = $CurrentProfiles | Where-Object { $_.ProfileName -match $AccountName }
        $AccountSummary     = Get-DoAWSDBInformation $AccountProfiles $Regions

        return $AccountSummary
        
    }
    default {

        $ErrorMessage = [PSCustomObject]@{
            
            Error = "[$AccountName] - Invalid Account Name"
        }
            return $ErrorMessage

    }
}