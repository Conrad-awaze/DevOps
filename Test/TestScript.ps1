Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS

$Regions        = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$AccountName    = 'Apex-PROD'
$AccountProfile        = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match $AccountName }

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

$AccountSummary    = Get-DoAWSDBInformation $AccountProfile $Regions
return $AccountSummary 

$Account = [PSCustomObject]@{
    Name = $AccountName
}
$Account