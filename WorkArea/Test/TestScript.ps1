Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS, AWS.Tools.SecurityToken
Import-Module AWS.Tools.SecurityToken, AWS.Tools.Backup
Install-Module AWS.Tools.Backup -Scope AllUsers -Force -AllowClobber
# Get-Command -Module AWS.Tools.DynamoDBv2 
Invoke-RestMethod https://devops-db-monitor.sandbox.devops.awaze.com/DatabaseMonitor/GetRDSSummary/AVR-Pricing-PROD -Method GET
Invoke-RestMethod https://devops-db-monitor.sandbox.devops.awaze.com/DatabaaseMonitor/GetDDBTableInformation/Apex-PROD -Method GET

$General        = Get-DatabaseMonitorParameters 'General'
$Regions        = $General.Regions.Split(',').Trim()
$AccountList    = Get-DatabaseMonitorParameters 'Account' 

$Accounts       = $AccountList | Where-Object { $_.AccountName -match $AccountName }

$DynamoDBSummary  = Get-DDBTableDetails $Accounts $Regions
$DynamoDBSummary

function Get-DDBTableDetails {
    [CmdletBinding()]
    param (

        $Accounts,
        $Regions
        
    )
    
    begin {

        $Count                  = 1
        $ddbTables              = @()
        $ddbTableList           = @()
        $RegexGroup             = 'AccountNumber'
        $RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$"
        
    }
    
    process {

        foreach ($Account in $Accounts) {

            $AssumedRole    = Use-STSRole -RoleArn $Account.MonitorRoleARN -RoleSessionName $Account.AccountName

            foreach ($Region in $Regions) {
                
                $LatestBackup   = $null
                $ddbTableList   = Get-DDBTableList -Credential $AssumedRole.Credentials -Region $Region
                $ddbBackupList  = Get-DDBBackupList -Credential $AssumedRole.Credentials -Region $Region
                
                foreach ($ddbTable in $ddbTableList) {
                    
                    $LatestBackup = $null
                    $Table          = Get-DDBTable -TableName $ddbTable -Credential $AssumedRole.Credentials -Region $Region
            
                    if ($ddbBackupList) {

                        $LatestBackup   = $ddbBackupList | Where-Object { $_.TableName -eq $Table.TableName } | Sort-Object BackupCreationDateTime -Descending | Select-Object -First 1
                        $BackupCount    = ($ddbBackupList | Where-Object { $_.TableName -eq $Table.TableName } | Measure-Object).Count
                        
                    }
                    else {
                        
                        $BackupCount    = 0
                        
                    }

                    if ([string]::IsNullOrEmpty($LatestBackup)) {

                        $Latest = ''

                    }else {

                        $Latest = ($LatestBackup.BackupCreationDateTime).ToString("dd/MM/yyyy HH:mm:ss")
                    }
                         
                    $Sum = [PSCustomObject]@{

                        'No.'               = $Count++
                        Account             = $Account.AccountName
                        AccountID           = (($Table.TableArn | select-string -Pattern $RegexAccountNumberDDb).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value
                        Region              = $Region
                        TableName           = $Table.TableName
                        TableBackups        = $BackupCount
                        LatestBackup        = $Latest
                        DeletionProtection  = $Table.DeletionProtectionEnabled
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

                }
                
            }
            
        }
        
    }
    
    end {

        $ddbTables
        
    }
}




function Get-RDSDatabaseSummary {
    [CmdletBinding()]
    param (

        $Accounts,
        $Regions
        
    )
    
    begin {

        $Inst                   = @()
        $AccountName            = $Accounts.AccountName
        $AssumedRole            = Use-STSRole -RoleArn $Accounts.MonitorRoleARN -RoleSessionName $Accounts.AccountName
        
    }
    
    process {

        $Regions | ForEach-Object {
    
            $RDSInstances = Get-RDSDBInstance -Credential $AssumedRole.Credentials -Region $_
        
            if ($RDSInstances) {
                
                foreach ($Instance in $RDSInstances) {
                    
                    $Region         = $_
                    $DBInstanceArn  = $Instance.DBInstanceArn
                    $Shots          = Get-RDSDBSnapshot -Credential $AssumedRole.Credentials -DBInstanceIdentifier $DBInstanceArn -Region $Region
                    
                    if ($Shots) {
                        
                        $LastestSnap = ($Shots | Sort-Object -Property SnapshotCreateTime -Descending | Select-Object -First 1).SnapshotCreateTime.ToString("dd/MM/yyyy HH:mm:ss")
                    }else {

                        $LastestSnap = ''
                    }

                    if ($($Instance.LatestRestorableTime -ne '01/01/0001 00:00:00')) {

                        $LatestRestorableTime = ($Instance.LatestRestorableTime).ToString("dd/MM/yyyy HH:mm:ss")

                    } else {

                        $LatestRestorableTime = ""

                    } 

                    $ExpireTimeSpan  = $( New-TimeSpan $(Get-Date) $($Instance.CertificateDetails.ValidTill)).ToString("dd' days'")
                    # $ExpireTimeSpan  = $( New-TimeSpan $(Get-Date) $($Instance.CertificateDetails.ValidTill)).ToString("dd' days 'hh' hrs'")

                    $Sum = [PSCustomObject]@{
                        
                        AccountName             = $AccountName
                        Region                  = $_
                        DBInstanceIdentifier    = $Instance.DBInstanceIdentifier
                        Engine                  = $Instance.Engine
                        Version                 = $Instance.EngineVersion
                        InstanceCreateTime      = $Instance.InstanceCreateTime
                        DBInstanceClass         = $Instance.DBInstanceClass
                        LatestRestorableTime    = $LatestRestorableTime
                        StorageThroughput       = $Instance.StorageThroughput
                        DeletionProtection      = $Instance.DeletionProtection
                        CertificateAuthority    = $Instance.CertificateDetails.CAIdentifier
                        CertificateExpiration   = ($Instance.CertificateDetails.ValidTill).ToString("dd/MM/yyyy HH:mm:ss")
                        ExpireDuration          = $ExpireTimeSpan
                        Snapshots               = ($Shots | Measure-Object).Count
                        LatestSnapshot          = $LastestSnap
                        Retention               = $Instance.BackupRetentionPeriod
                        DBClusterSnapshots      = ($DBClusterSnapshots | Measure-Object).Count
            
                    }
                    $Inst += $Sum
            
                }

            }

        }
         
    }
    
    end {

        $Inst
           
    }
}



Get-DDBTableList -ProfileName  DevOps-Apex-PROD -Region eu-west-2
$Table =  Get-DDBTable -TableName 'prod-accommodation' -ProfileName DevOps-Apex-PROD -Region eu-west-2
Get-DDBTimeToLive -TableName 'prod-accommodation' -ProfileName DevOps-Apex-PROD -Region eu-west-2
Get-DDBBackupsList -ProfileName DevOps-Apex-PROD -Region eu-west-2



$Bk = Get-DDBContinuousBackup -TableName 'prod-accommodation' -ProfileName DevOps-Apex-PROD -Region eu-west-2
$Bk.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus.Value
$Bk.PointInTimeRecoveryDescription.LatestRestorableDateTime

$( New-TimeSpan $($Bk.PointInTimeRecoveryDescription.EarliestRestorableDateTime) $($Bk.PointInTimeRecoveryDescription.LatestRestorableDateTime)).ToString("dd' days 'hh' hrs'")

$BK = Get-BAKBackupPlanList -ProfileName DBA-Sandpit -Region eu-west-2
$BK.AdvancedBackupSettings
$Plan = Get-BAKBackupPlan -BackupPlanId $BK.BackupPlanId -ProfileName DBA-Sandpit -Region eu-west-2
$Plan.advancedBackupSettings

Get-RDSCertificates -ProfileName DevOps-AVR-Pricing-PROD -Region eu-west-2  
$RDS = Get-RDSDBInstance -ProfileName DevOps-AVR-Pricing-PROD -Region eu-west-2

($RDS | where { $_.DBInstanceIdentifier -eq 'repricing-rds-instance-prod' }).CertificateDetails.CAIdentifier

$Maint = Get-RDSPendingMaintenanceActions -ProfileName DevOps-AVR-Pricing-PROD -Region eu-west-2
($Maint |where { $_.ResourceIdentifier -eq 'arn:aws:rds:eu-west-2:771654826489:db:pricing-event-store-1' }).PendingMaintenanceActionDetails

CertificateDetails.CAIdentifier
CertificateDetails.ValidTill



function Get-DoDDBTableInformation {
    [CmdletBinding()]
    param (

        $Profiles,
        $Regions
        
  
    )
    
    begin {

        $Count                  = 1
        $ddbTables              = @()
        $ddbTableList           = @()
        $RegexGroup             = 'AccountNumber'
        $RegexGroupAccountName  = 'AccountName'
        #$RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$"
        $RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$" 
        $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
        
    }
    
    process {

        foreach ($Profile in $Profiles) {

            foreach ($Region in $Regions) {
                
                $LatestBackup = $null
                $ddbTableList   = Get-DDBTableList -ProfileName $Profile.ProfileName -Region $Region
                $ddbBackupList  = Get-DDBBackupList -ProfileName $Profile.ProfileName -Region $Region
                
                foreach ($ddbTable in $ddbTableList) {
                    
                    $LatestBackup = $null
                    $Table          = Get-DDBTable -TableName $ddbTable -ProfileName $Profile.ProfileName -Region $Region
            
                    if ($ddbBackupList) {

                        $LatestBackup   = $ddbBackupList | Where-Object { $_.TableName -eq $Table.TableName } | Sort-Object BackupCreationDateTime -Descending | Select-Object -First 1
                        $BackupCount    = ($ddbBackupList | Where-Object { $_.TableName -eq $Table.TableName } | Measure-Object).Count
                        
                    }
                    else {
                        
                        $BackupCount    = 0
                        
                    }

                    if ([string]::IsNullOrEmpty($LatestBackup)) {

                        $Latest = ''
                        # $Latest = '00/00/0000 00:00:00'

                    }else {

                        $Latest = ($LatestBackup.BackupCreationDateTime).ToString("dd/MM/yyyy HH:mm:ss")
                    }
                         
                    $Sum = [PSCustomObject]@{

                        'No.'               = $Count++
                        Account             = (($Profile.ProfileName | select-string -Pattern $RegexAccountName).Matches.Groups | Where-Object { $_.Name -eq $RegexGroupAccountName }).Value
                        AccountID           = (($Table.TableArn | select-string -Pattern $RegexAccountNumberDDb).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value
                        Region              = $Region
                        TableName           = $Table.TableName
                        TableBackups        = $BackupCount
                        LatestBackup        = $Latest
                        DeletionProtection  = $Table.DeletionProtectionEnabled
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

$AccountName   = 'Apex-PROD'
Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS

$Regions            = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$SelectedProfile    = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match $AccountName }


$DynamoDBSummary  = Get-DoDDBTableInformation $SelectedProfile $Regions
$DynamoDBSummary

Invoke-RestMethod https://devops-db-monitor.sandbox.devops.awaze.com/DatabaseMonitor/GetAccountSummary/Novosol-PROD -Method GET
Invoke-RestMethod https://devops-db-monitor.sandbox.devops.awaze.com/DatabaaseMonitor/GetDDBTableInformation/Apex-PROD -Method GET
Invoke-RestMethod https://devops-db-monitor.sandbox.devops.awaze.com/DatabaseMonitor/GetRDSSummary/Novosol-PROD -Method GET

function Get-DatabaseMonitorParameters {
    <#
    .EXAMPLE
    
        Get-DatabaseMonitorParameters 'Account' 'databasemonitor'  'parameters-database-monitor' 'eu-west-2'
    #>
    [CmdletBinding()]
    param (

        $PK,
        $SK                 = 'databasemonitor',
        $ddbParametersTable = 'parameters-database-monitor',
        $Region             = 'eu-west-2'
        
    )
    
    begin {

        $Results                        = @()
        $GetDetailsQuery                = @{
            TableName                   = $ddbParametersTable
            KeyConditionExpression      = 'PK = :PK and begins_with (SK, :SK)'
            ExpressionAttributeValues   = @{ ':PK' = $PK ; ':SK' = $SK } | ConvertTo-DDBItem
        }
        
    }
    
    process {

        switch ($PK) {

            Account { 

                $QueryResults = Invoke-DDBQuery @GetDetailsQuery -Region $Region -ProfileName DBA-Sandpit| ConvertFrom-DDBItem

                for ($i = 0; $i -lt $QueryResults.Count; $i++) {
                    
                    $obj = [PSCustomObject]@{

                        AccountName     = $QueryResults[$i].AccountName
                        MonitorRoleARN  = $QueryResults[$i].MonitorRoleARN
                        Status          = $QueryResults[$i].Status

                    }
                    $Results += $obj
                }

             }
             General {
                 
                $QueryResults = Invoke-DDBQuery @GetDetailsQuery -Region $Region -ProfileName DBA-Sandpit | ConvertFrom-DDBItem

                $obj = [PSCustomObject]@{

                    CredentialsExpiration   = [int]$QueryResults.CredentialsExpiration
                    Regions                 = $QueryResults.Regions

                }
                $Results += $obj
                    
             }
        }

        
        
    }
    
    end {

        $Results
        
    }

}

Get-DatabaseMonitorParameters 'Account' 

$General = Get-DatabaseMonitorParameters 'General'
$General.Regions.Split(',').Trim()
function Get-DatabaseMonitorRegions {
    <#
    .EXAMPLE
    
        Get-DatabaseMonitorRegions 'Regions' 'databasemonitor' 'parameters-database-monitor' 'eu-west-2'
    #>
    [CmdletBinding()]
    param (
            
            $PK,
            $SK,
            $ddbParametersTable,
            $Region
        
    )
    
    begin {

        $GetRegionsQuery                = @{
            TableName                   = $ddbParametersTable
            KeyConditionExpression      = 'PK = :PK and begins_with (SK, :SK)'
            ExpressionAttributeValues   = @{ ':PK' = $PK ; ':SK' = $SK } | ConvertTo-DDBItem
        }
        
    }
    
    process {

        $Regions = (Invoke-DDBQuery @GetRegionsQuery -Region $Region | ConvertFrom-DDBItem).Regions 
   
    }
    
    end {

        $Regions.Split(',').Trim()
        
    }
}



function Get-DoRDSSnapshotSummary {
    [CmdletBinding()]
    param (

        $Accounts,
        $Regions
        
    )
    
    begin {
            
            $SummarySnapshots   = @()
            $Snapshots          = @()
            $AssumedRole        = Use-STSRole -RoleArn $Accounts.MonitorRoleARN -RoleSessionName $Accounts.AccountName
        
    }
    
    process {

        $Regions | ForEach-Object {
    
            $RDSInstances = Get-RDSDBInstance -Credential $AssumedRole.Credentials -Region $_
        
            if ($RDSInstances) {
                
                foreach ($Instance in $RDSInstances) {

                    $Region = $_
                
                    $DBInstanceArn      = $Instance.DBInstanceArn
                    # $Tags               = Get-RDSTagForResource -ResourceName $DBInstanceArn -ProfileName $Profile.ProfileName
                    $Shots              = Get-RDSDBSnapshot -Credential $AssumedRole.Credentials -DBInstanceIdentifier $DBInstanceArn -Region $Region
                    #$DBClusterSnapshots = Get-RDSDBClusterSnapshot -ProfileName $Profile.ProfileName -DBClusterIdentifier $DBInstanceArn

                    $Snapshots += $Shots
            
                }
            
                $Snapshots | ForEach-Object {
            
                    $Summary= [PSCustomObject]@{
                        
                        AvailabilityZone        = $_.AvailabilityZone
                        DBInstanceIdentifier    = $_.DBInstanceIdentifier
                        DBSnapshotIdentifier    = $_.DBSnapshotIdentifier
                        SnapshotCreateTime      = ($_.SnapshotCreateTime).ToString("dd/MM/yyyy HH:mm:ss")
                        Engine                  = $_.Engine
                        SnapshotType            = $_.SnapshotType
                        Status                  = $_.Status
            
                    }
                    $SummarySnapshots += $Summary
                }
            }
        
        }
        
    }
    
    end {
            
        $SummarySnapshots
        
    }
}


Invoke-RestMethod https://devops-db-monitor.sandbox.devops.awaze.com/DatabaseMonitor/GetRDSSummary/AVR-Pricing-PROD -Method GET
# /GetDDBTableInformation/:AccountName  /DBMonitor/GetAccountSummary/:AccountName

# $AccountName    = 'Owner-Services-PROD' #Apex-PROD' Owner-Services-PROD

Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS

$Regions            = Get-DatabaseMonitorRegions 'Regions' 'databasemonitor' 'parameters-database-monitor' 'eu-west-2'
$Accounts           = $AccountList | Where-Object { $_.AccountName -match $AccountName }
$RDS                = Get-RDSDatabaseSummary $Accounts $Regions 
# $Snapshots  = Get-DoRDSSnapshotSummary $SelectedProfile  $Regions
$RDS

function Get-RDSDatabaseSummary {
    [CmdletBinding()]
    param (

        $Accounts,
        $Regions
        
    )
    
    begin {

        $Inst                   = @()
        # $RegexGroupAccountName  = 'AccountName'
        # $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
        $AccountName            = $Accounts.AccountName
        $AssumedRole            = Use-STSRole -RoleArn $Accounts.MonitorRoleARN -RoleSessionName $Accounts.AccountName
        
    }
    
    process {


        $Regions | ForEach-Object {
    
            $RDSInstances = Get-RDSDBInstance -Credential $AssumedRole.Credentials -Region $_
        
            if ($RDSInstances) {
                
                foreach ($Instance in $RDSInstances) {
                    
                    $Region = $_
                    $DBInstanceArn      = $Instance.DBInstanceArn
                    # $Tags               = Get-RDSTagForResource -ResourceName $DBInstanceArn -ProfileName $Profile.ProfileName

                    $Shots  = Get-RDSDBSnapshot -Credential $AssumedRole.Credentials -DBInstanceIdentifier $DBInstanceArn -Region $Region
                    
                    if ($Shots) {
                        
                        $LastestSnap = ($Shots | Sort-Object -Property SnapshotCreateTime -Descending | Select-Object -First 1).SnapshotCreateTime.ToString("dd/MM/yyyy HH:mm:ss")
                    }else {

                        $LastestSnap = ''
                    }

                    if ($($Instance.LatestRestorableTime -ne '01/01/0001 00:00:00')) {

                        $LatestRestorableTime = ($Instance.LatestRestorableTime).ToString("dd/MM/yyyy HH:mm:ss")

                    } else {

                        $LatestRestorableTime = ""

                    } 
                    
                    #$DBClusterSnapshots = Get-RDSDBClusterSnapshot -ProfileName $Profile.ProfileName -DBClusterIdentifier $DBInstanceArn
            
                    $Sum = [PSCustomObject]@{
                        
                        AccountName             = $AccountName
                        Region                  = $_
                        DBInstanceIdentifier    = $Instance.DBInstanceIdentifier
                        Engine                  = $Instance.Engine
                        Version                 = $Instance.EngineVersion
                        InstanceCreateTime      = $Instance.InstanceCreateTime
                        DBInstanceClass         = $Instance.DBInstanceClass
                        LatestRestorableTime    = $LatestRestorableTime
                        StorageThroughput       = $Instance.StorageThroughput
                        DeletionProtection      = $Instance.DeletionProtection
                        Snapshots               = ($Shots | Measure-Object).Count
                        LatestSnapshot          = $LastestSnap
                        Retention               = $Instance.BackupRetentionPeriod
                        DBClusterSnapshots      = ($DBClusterSnapshots | Measure-Object).Count
            
                    }
                    $Inst += $Sum
                    # $Snapshots += $Shots
            
                }
            
                # $Snapshots | ForEach-Object {
            
                #     $Sum = [PSCustomObject]@{
            
                #         DBInstanceIdentifier    = $_.DBInstanceIdentifier
                #         DBSnapshotIdentifier    = $_.DBSnapshotIdentifier
                #         SnapshotCreateTime      = $_.SnapshotCreateTime
                #         Engine                  = $_.Engine
                #         SnapshotType            = $_.SnapshotType
                #         Status                  = $_.Status
            
                #     }
                #     $Snap += $Sum
                # }
            }

        }
         
    }
    
    end {

        $Inst
           
    }
}


# -------------------------------------------------------------------- Apex Prod ------------------------------------------------------------------- #
clear-host
Get-DDBTableList -ProfileName 'Devops-Test-User' -Region eu-west-2

$ApexProdRoleARN        = "arn:aws:iam::463854377715:role/apex-prod-database-monitor"
$AssumedRoleApexProd    = Use-STSRole -RoleArn $ApexProdRoleARN -RoleSessionName "Apex-Prod" -ProfileName 'Devops-Test-User' -Region eu-west-2 -DurationInSeconds 900

$AssumedRoleApexProd.Credentials
$AssumedRoleApexProd.Credentials.Expiration

clear-host
Get-DDBTableList -Credential $AssumedRoleApexProd.Credentials -Region eu-west-2  


# ---------------------------------------------------------------- AVR Pricing Prod ---------------------------------------------------------------- #

$AVRPricingProdRoleARN  = "arn:aws:iam::771654826489:role/avr-pricing-prod-database-monitor"
$AssumedRoleAVRPricing  = Use-STSRole -RoleArn $AVRPricingProdRoleARN -RoleSessionName "Apex-Prod" -ProfileName 'Devops-Test-User' -Region eu-west-2

$AssumedRoleAVRPricing.Credentials
$AssumedRoleAVRPricing.Credentials.Expiration

clear-host
Get-DDBTableList -Credential $AssumedRoleAVRPricing.Credentials -Region eu-west-2 










# Invoke-RestMethod https://devops-db-monitor.sandbox.devops.awaze.com/DatabaseMonitor/GetAccountSummary/AVR-Pricing-PROD -Method GET
# Invoke-RestMethod https://devops-db-monitor.sandbox.devops.awaze.com/DatabaaseMonitor/GetDDBTableInformation/Apex-PROD -Method GET
# Get-STSCallerIdentity -ProfileName 'Devops-Test-User' -Region eu-west-2



# $ApexProdRoleARN        = "arn:aws:iam::463854377715:role/apex-prod-database-monitor"
# $AssumedRoleApexProd    = Use-STSRole -RoleArn $ApexProdRoleARN -RoleSessionName "DBA-SSIO-Sandpit" -ProfileName 'Devops-Test-User' -Region eu-west-2
# $AssumedRoleApexProd


# $SSIORoleARN            = "arn:aws:iam::587525780573:role/ssio-sandpit-database-monitor"
# $AssumedRoleSSIOSandpit = Use-STSRole -RoleArn $SSIORoleARN -RoleSessionName "DBA-SSIO-Sandpit" -ProfileName 'Devops-Test-User' -Region eu-west-2
# Get-DDBTableList -Credential $AssumedRoleSSIOSandpit.Credentials -Region eu-west-2





# $AVRPricingProdRoleARN  = "arn:aws:iam::771654826489:role/avr-pricing-prod-database-monitor"
# $AssumedRoleAVRPricing  = Use-STSRole -RoleArn $AVRPricingProdRoleARN -RoleSessionName "Apex-Prod" -ProfileName 'Devops-Test-User' -Region eu-west-2

# $NovosolProdRoleARN  = "arn:aws:iam::035637376366:role/novosol-prod-database-monitor"
# $AssumedRoleNovosolProd  = Use-STSRole -RoleArn $NovosolProdRoleARN -RoleSessionName "Novosol-PROD" -ProfileName 'Devops-Test-User' -Region eu-west-2



# Write-Host "----------------------------------------"
# Write-Host "DynamoDB Tables - AVR Pricing Prod"
# Write-Host "----------------------------------------"
# Get-DDBTableList -Credential $AssumedRoleAVRPricing.Credentials -Region eu-west-2 


# Get-DDBTableList -Credential $AssumedRoleSSIOSandpit.Credentials -Region eu-west-2   
# Get-DDBTableList -ProfileName 'Devops-Test-User' -Region eu-west-2
# Get-DDBTableList -ProfileName DevOps-Apex-PROD -Region eu-west-2






# "arn:aws:iam::771654826489:role/avr-pricing-prod-database-monitor"




# Find-Module -Name AWS.Tools.I*
# Get-Module -ListAvailable -Name AWS.Tools.SecurityToken
# Install-Module AWS.Tools.IdentityManagement -Scope AllUsers -Force -AllowClobber
# Update-AWSToolsModule -Confirm:$false
# Remove-Module AWS.Tools.SecurityToken
# Get-Command -Module AWS.Tools.IdentityManagement




# Get-IAMRoleList -ProfileName DBA-Sandpit | Where-Object { $_.RoleName -match 'database-monitor' }
# $SIORoleDBM = Get-IAMRoles -ProfileName DBA-Sandpit | Where-Object { $_.RoleName -match 'database-monitor' }
# $SIORoleDBM.RoleName

# $SSIORoleARN            = "arn:aws:iam::587525780573:role/ssio-database-monitor"
# $AssumedRoleSSIOSandpit = Use-STSRole -RoleArn $SSIORoleARN -RoleSessionName "DBA-SSIO-Sandpit" -ProfileName 'Devops-Test-User' -Region eu-west-2

# aws sts get-caller-identity --profile 'Devops-Test-User' | ConvertFrom-Json
# Get-STSSessionToken -ProfileName 'Devops-Test-User'
# Get-STSCallerIdentity -ProfileName 'Devops-Test-User' -Region eu-west-2
# Get-DDBTableList -Credential $AssumedRoleSSIOSandpit.Credentials -Region eu-west-2   
# Get-DDBTableList
# Get-DDBTableList -ProfileName 'Devops-Test-User' -Region eu-west-2



# $Regions        = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
# $AccountName    = 'Apex-PROD'
# $AccountProfile        = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -match $AccountName }

# function Get-DoAWSDBInformation {

#     [CmdletBinding()]
#     param (

#         $Profiles,
#         $Regions 
        
#     )
    
#     begin {

#         $Summary                = @()
#         $RegexGroup             = 'AccountNumber'
#         $RegexGroupAccountName  = 'AccountName'
#         $RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$"
#         $RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$" 
#         $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
        
#     }
    
#     process {

#         Clear-Host
#         $Count     = 1
#         $Summary    = @()
#         foreach ($Profile in $Profiles) {

#             foreach ($Region in $Regions) {
                
#                 $RDSInstances   = Get-RDSDBInstance -ProfileName $Profile.ProfileName -Region $Region
#                 $ddbTables      = Get-DDBTableList -ProfileName $Profile.ProfileName -Region $Region

#                 switch ([string]::IsNullOrEmpty($RDSInstances)) {
#                     $true { 
#                         if ($ddbTables) {
                            
#                             $Table = $ddbTables | Select-Object -First 1
#                             $ddbTable = Get-DDBTable -TableName $Table -ProfileName $Profile.ProfileName -Region $Region
#                             $AccountID  = (($ddbTable.TableArn | Select-String -Pattern $RegexAccountNumberDDb).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value
#                         }else {

#                             $AccountID = 0
#                         }
#                     }
#                     $false {

#                         $RDSInstance   = $RDSInstances | Select-Object -First 1
#                         $AccountID  = (($RDSInstance.DBInstanceArn | Select-String -Pattern $RegexAccountNumber).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value
#                     }
#                     default {

#                         $AccountID = 0
#                     }
#                 }

#                 $Sum = [PSCustomObject]@{

#                     # 'No.'               = $Count++
#                     Account             = (($Profile.ProfileName | select-string -Pattern $RegexAccountName).Matches.Groups | Where-Object { $_.Name -eq $RegexGroupAccountName }).Value
#                     AccountID           = $AccountID
#                     Region              = $Region
#                     RDSInstances        = ($RDSInstances.DBInstanceIdentifier | Measure-Object).Count
#                     DynamoDBTables      = $ddbTables.Count
                    
#                 }

#                 # Write-Host "Collected Details: Account - $($Sum.Account) | Region - $Region"

#                 $condition = $Sum.RDSInstances + $Sum.DynamoDBTables
#                 if ($condition -gt 0) {
#                     $Number = $Count++
#                     $Sum | Add-Member -MemberType NoteProperty -Name 'No.' -Value $Number
#                     $Summary += $Sum
#                 }
#             }

#         }
        
#     }
    
#     end {

#         $Summary
        
#     }
# }

# $AccountSummary    = Get-DoAWSDBInformation $AccountProfile $Regions
# return $AccountSummary 

# $Account = [PSCustomObject]@{
#     Name = $AccountName
# }
# $Account