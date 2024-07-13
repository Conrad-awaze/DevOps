Import-Module AWS.Tools.Common
Import-Module AWS.Tools.DynamoDBv2
Import-Module AWS.Tools.RDS

$Profiles   = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match 'DevOps-AVR-Guest-Experience-PROD' }
$Regions    = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"

function Get-AWSDBInformation {
    [CmdletBinding()]
    param (

        $Profiles,
        $Regions,
        $RegexGroup             = 'AccountNumber',
        $RegexGroupAccountName  = 'AccountName',
        $RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$",
        $RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$", 
        $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
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

$Summary    = Get-AWSDBInformation $Profiles $Regions
$Summary    | Format-Table -AutoSize



$ddbTables  = @()
$ddbTableList   = @()
$Regions | ForEach-Object   {

    $ddbTableList   = Get-DDBTableList -ProfileName $Profiles.ProfileName -Region $_
    $ddbBackupList  = Get-DDBBackupList -ProfileName $Profiles.ProfileName -Region $_

    foreach ($ddbTable in $ddbTableList) {
        
        $Table = Get-DDBTable -TableName $ddbTable -ProfileName $Profiles.ProfileName -Region $_

        if ($ddbBackupList) {
            
            $BackupAvailable = $ddbBackupList.TableName.Contains("$($Table.TableName)")
        }
        else {

            $BackupAvailable = $false
        }
        

        $Sum = [PSCustomObject]@{

            Region             = $_
            TableName           = $Table.TableName
            TableBackup         = $BackupAvailable
            CreationDateTime    = $Table.CreationDateTime
            ItemCount           = $Table.ItemCount
            # TableSizeBytes      = $Table.TableSizeBytes
            TableSizeMB         = "$([math]::round($($Table.TableSizeBytes /1MB), 0)) MB"
            #TableStatus         = $Table.TableStatus
            # TableId             = $Table.TableId
            # KeySchema           = $Table.KeySchema
            # GlobalSecondaryIndexes = $Table.GlobalSecondaryIndexes
            
        }
        $ddbTables += $Sum
    }
    
    

}
$ddbTables | Format-Table -AutoSize


