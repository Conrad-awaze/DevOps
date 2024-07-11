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

$RegexGroup             = 'AccountNumber'
$RegexGroupAccountName  = 'AccountName'
$RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$"
$RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$" 
$RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
$Profiles               = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }

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
                    RDSInstances        = ($RDSInstances.DBInstanceIdentifier | Measure-Object).Count
                    DynamoDBTables      = $ddbTables.Count
                    
                }

                $condition = $Sum.RDSInstances + $Sum.DynamoDBTables
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








New-AdaptiveCard -Uri $URI -VerticalContentAlignment center -FullWidth {
    New-AdaptiveContainer {

        New-AdaptiveTextBlock -Text "Database Restore Progress" -Size Large -Wrap -HorizontalAlignment Center -Color Accent
        New-AdaptiveTextBlock -Text "$((Get-Date).GetDateTimeFormats()[12])" -Subtle -HorizontalAlignment Center -Spacing None
        #New-AdaptiveTable -DataTable $RestoreStatusResults -HeaderColor Good -Spacing Default -HeaderHorizontalAlignment Center -Size Small -Wrap Stretch

    }
}