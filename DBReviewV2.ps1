Remove-Module DevOpsToolkit
Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS
Import-Module '/Users/conrad.gauntlett/WorkArea/Repos/DBA_MISC/PowerShell/Modules/DevOpsToolkit'

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
# $RegexGroup             = 'AccountNumber'
# $RegexGroupAccountName  = 'AccountName'
# $RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$"
# $RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$" 
# $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
$Profiles               = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }
$Columns                = 'Account', 'AccountID','RDS Instances','DynamoDB Tables'

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                      FUNCTIONS                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region FUNCTIONS

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                              COLLECT DATABASE DETAILS                                                              #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region COLLECT DATABASE DETAILS

$Summary    = Get-DoAWSDBInformation $Profiles $Regions
$Summary    | Format-Table -AutoSize

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                              COLLECT DYNAMODB DETAILS                                                              #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region COLLECT DYNAMODB DETAILS

$ddbTables = Get-DoDDBTableInformation $Profiles $Regions 
$ddbTables | Select-Object Account, Region, TableName, TableBackup, CreationDateTime, ItemCount,TableSizeBytes, TableSizeMB, TableStatus, AccountID | Format-Table -AutoSize

#endregion








# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                       TEAMS NOTIFICATION - TOP LEVEL DETAILS                                                       #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region TEAMS NOTIFICATION - TOP LEVEL DETAILS

# New-AdaptiveCard -Uri $URI -VerticalContentAlignment center -FullWidth {
#     New-AdaptiveContainer {

#         New-AdaptiveTextBlock -Text "AWS Database Review" -Size ExtraLarge -Wrap -HorizontalAlignment Center -Color Accent
#         New-AdaptiveTextBlock -Text "$((Get-Date).GetDateTimeFormats()[12])" -Subtle -HorizontalAlignment Center -Spacing None
        
#     }
# } -Action {

#     New-AdaptiveAction -Title "eu-west-2" -Body   {
#         #New-AdaptiveTextBlock -Text "Summary" -Weight Bolder -Size Large -Color Good -HorizontalAlignment Left
#         New-AdaptiveTable -DataTable $($Summary  | where-object { $_.Region -eq 'eu-west-2'} | 
#             Select-Object $Columns ) -HeaderColor Good -Spacing Default -HeaderHorizontalAlignment Center -Size Medium -HeaderSize Large #-Wrap Stretch
#     }
#     New-AdaptiveAction -Title "eu-central-1" -Body   {
#         #New-AdaptiveTextBlock -Text "Summary" -Weight Bolder -Size Large -Color Accent -HorizontalAlignment Left
#         New-AdaptiveTable -DataTable $($Summary | where-object { $_.Region -eq 'eu-central-1'} | 
#             Select-Object $Columns  ) -HeaderColor Good -Spacing Default -HeaderHorizontalAlignment Center -Size Medium -HeaderSize Large #-Wrap Stretch
#     }
# }

# #endregion