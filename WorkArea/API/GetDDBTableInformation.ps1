# /GetDDBTableInformation/:AccountName  /DBMonitor/GetAccountSummary/:AccountName

$AccountName    = 'Owner-Services-PROD' #Apex-PROD' Owner-Services-PROD

Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS

$Regions            = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$SelectedProfile    = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match $AccountName }

function Get-DoDDBTableInformation {
    [CmdletBinding()]
    param (

        $Profiles,
        $Regions
        
    )
    
    begin {

        $Count          = 1
        $ddbTables      = @()
        $ddbTableList   = @()
        $RegexGroup             = 'AccountNumber'
        $RegexGroupAccountName  = 'AccountName'
        #$RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$"
        $RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$" 
        $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
        
    }
    
    process {

        foreach ($Profile in $Profiles) {

            foreach ($Region in $Regions) {
                
                $ddbTableList   = Get-DDBTableList -ProfileName $Profile.ProfileName -Region $Region
                $ddbBackupList  = Get-DDBBackupList -ProfileName $Profile.ProfileName -Region $Region
            
                foreach ($ddbTable in $ddbTableList) {
                    
                    $Table = Get-DDBTable -TableName $ddbTable -ProfileName $Profile.ProfileName -Region $Region
            
                    if ($ddbBackupList) {

                        $BackupCount = ($ddbBackupList | Where-Object { $_.TableName -eq $Table.TableName } | Measure-Object).Count
                        # $BackupAvailable = $ddbBackupList.TableName.Contains("$($Table.TableName)")
                    }
                    else {
                        
                        $BackupCount = 0
                        # $BackupAvailable = $false
                    }
                          
                    $Sum = [PSCustomObject]@{

                        'No.'               = $Count++
                        Account             = (($Profile.ProfileName | select-string -Pattern $RegexAccountName).Matches.Groups | Where-Object { $_.Name -eq $RegexGroupAccountName }).Value
                        AccountID           = (($Table.TableArn | select-string -Pattern $RegexAccountNumberDDb).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value
                        Region              = $Region
                        TableName           = $Table.TableName
                        TableBackups        = $BackupCount
                        CreationDateTime    = $Table.CreationDateTime
                        ItemCount           = $Table.ItemCount
                        TableSizeBytes      = $Table.TableSizeBytes
                        TableSizeMB         = "$([math]::round($($Table.TableSizeBytes /1MB), 0)) MB"
                        TableStatus         = $Table.TableStatus
                        TableId             = $Table.TableId
                        TableARN            = $Table.TableArn
                        KeySchema           = $Table.KeySchema
                        GlobalSecondaryIndexes = $Table.GlobalSecondaryIndexes
                        
                    }
                    $ddbTables += $Sum

                    # if ($Selection -eq 0) {
                        
                    #     Write-Host "Collected Table Details : Account - $($Sum.Account) | Region - $Region | Table - $($Sum.TableName)"

                    # }

                    

                }
                
            }
            
        }
        
    }
    
    end {

        $ddbTables
        
    }
}

$DynamoDBSummary  = Get-DoDDBTableInformation $SelectedProfile $Regions
$DynamoDBSummary