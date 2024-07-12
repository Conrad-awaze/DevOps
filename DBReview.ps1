Import-Module PSTeams,AWS.Tools.DynamoDBv2

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                     PARAMATERS                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region PARAMATERS

$ddbParametersTable     = 'DBA-Parameters'
$ProfileNameCommon      = 'DBA-Common'
$keyTeams               = @{ PK = 'Teams'; SK = 'ChannelGUIDs'} | ConvertTo-DDBItem
$Teams                  = Get-DDBItem -TableName $ddbParametersTable -Key $keyTeams -ProfileName $ProfileNameCommon | ConvertFrom-DDBItem
$URI                    = "https://awazecom.webhook.office.com/webhookb2/$($Teams.DBAAWSGUID1)/IncomingWebhook/$($Teams.DBAAWSGUID2)"
$Regions                = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$RegexGroup             = 'AccountNumber'
$RegexGroupAccountName  = 'AccountName'
$RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$"
$RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$" 
$RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
$Profiles               = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }
$Columns                = 'Account', 'AccountID','RDS Instances','DynamoDB Tables'

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                      FUNCTIONS                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region FUNCTIONS

function Get-AWSDBInformation {
    [CmdletBinding()]
    param (

        $Profiles,
        $Regions
    )
    
    begin {

        $Summary    = @()
        
    }
    
    process {

        Clear-Host
        $Summary    = @()
        foreach ($Profile in $Profiles) {

            foreach ($Region in $Regions) {
                
                $RDSInstances   = Get-RDSDBInstance -ProfileName $Profile.ProfileName -Region $Region
                $ddbTables      = Get-DDBTableList -ProfileName $Profile.ProfileName -Region $Region

                switch ([string]::IsNullOrEmpty($RDSInstances)) {
                    $true { 
                        if ($ddbTables) {
                            
                            $Table = $ddbTables | Select-Object -First 1
                            $ddbTable = Get-DDBTable -TableName $Table -ProfileName $Profile.ProfileName -Region $Region
                            $AccountID  = (($ddbTable.TableArn | Select-String -Pattern $RegexAccountNumberDDb).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value
                        }else {

                            $AccountID = 0
                        }
                    }
                    $false {

                        $RDSInstance   = $RDSInstances | Select-Object -First 1
                        $AccountID  = (($RDSInstance.DBInstanceArn | Select-String -Pattern $RegexAccountNumber).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value
                    }
                    default {

                        $AccountID = 0
                    }
                }

                $Sum = [PSCustomObject]@{

                    Account             = (($Profile.ProfileName | select-string -Pattern $RegexAccountName).Matches.Groups | Where-Object { $_.Name -eq $RegexGroupAccountName }).Value
                    AccountID           = $AccountID
                    Region              = $Region
                    'RDS Instances'     = ($RDSInstances.DBInstanceIdentifier | Measure-Object).Count
                    'DynamoDB Tables'   = $ddbTables.Count
                    
                }

                Write-Host "Collected Details: Account - $($Sum.Account) | Region - $Region"

                $condition = $Sum.'RDS Instances' + $Sum.'DynamoDB Tables'
                if ($condition -gt 0) {
                    $Summary += $Sum
                }
            }

        }
        
    }
    
    end {

        $Summary
        
    }
}

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                              COLLECT DATABASE DETAILS                                                              #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region COLLECT DATABASE DETAILS

$Summary    = Get-AWSDBInformation $Profiles $Regions
$Summary    | Format-Table -AutoSize

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                       TEAMS NOTIFICATION - TOP LEVEL DETAILS                                                       #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region TEAMS NOTIFICATION - TOP LEVEL DETAILS

New-AdaptiveCard -Uri $URI -VerticalContentAlignment center -FullWidth {
    New-AdaptiveContainer {

        New-AdaptiveTextBlock -Text "AWS Database Review" -Size ExtraLarge -Wrap -HorizontalAlignment Center -Color Accent
        New-AdaptiveTextBlock -Text "$((Get-Date).GetDateTimeFormats()[12])" -Subtle -HorizontalAlignment Center -Spacing None
        
    }
} -Action {

    New-AdaptiveAction -Title "eu-west-2" -Body   {
        #New-AdaptiveTextBlock -Text "Summary" -Weight Bolder -Size Large -Color Good -HorizontalAlignment Left
        New-AdaptiveTable -DataTable $($Summary  | where-object { $_.Region -eq 'eu-west-2'} | 
            Select-Object $Columns ) -HeaderColor Good -Spacing Default -HeaderHorizontalAlignment Center -Size Medium -HeaderSize Large #-Wrap Stretch
    }
    New-AdaptiveAction -Title "eu-central-1" -Body   {
        #New-AdaptiveTextBlock -Text "Summary" -Weight Bolder -Size Large -Color Accent -HorizontalAlignment Left
        New-AdaptiveTable -DataTable $($Summary | where-object { $_.Region -eq 'eu-central-1'} | 
            Select-Object $Columns  ) -HeaderColor Good -Spacing Default -HeaderHorizontalAlignment Center -Size Medium -HeaderSize Large #-Wrap Stretch
    }
}

#endregion