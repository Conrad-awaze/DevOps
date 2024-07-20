function Get-DoAWSDBInformation {

    [CmdletBinding()]
    param (

        $Profiles,
        $Regions 
        
    )
    
    begin {

        $Summary                = @()
        $RegexGroup             = 'AccountNumber'
        $RegexGroupAccountName  = 'AccountName'
        $RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$"
        $RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$" 
        $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
        
    }
    
    process {

        Clear-Host
        $Count     = 1
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

                    # 'No.'               = $Count++
                    Account             = (($Profile.ProfileName | select-string -Pattern $RegexAccountName).Matches.Groups | Where-Object { $_.Name -eq $RegexGroupAccountName }).Value
                    AccountID           = $AccountID
                    Region              = $Region
                    RDSInstances        = ($RDSInstances.DBInstanceIdentifier | Measure-Object).Count
                    DynamoDBTables      = $ddbTables.Count
                    
                }

                # Write-Host "Collected Details: Account - $($Sum.Account) | Region - $Region"

                $condition = $Sum.RDSInstances + $Sum.DynamoDBTables
                if ($condition -gt 0) {
                    $Number = $Count++
                    $Sum | Add-Member -MemberType NoteProperty -Name 'No.' -Value $Number
                    $Summary += $Sum
                }
            }

        }
        
    }
    
    end {

        $Summary
        
    }
}

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