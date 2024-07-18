using namespace System.Management.Automation.Host

Remove-Module DevOpsToolkit
Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS
Import-Module '/Users/conrad.gauntlett/WorkArea/Repos/DBA_MISC/PowerShell/Modules/DevOpsToolkit'

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                     PARAMATERS                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region PARAMATERS

$RegexGroupAccountName  = 'AccountName'
$RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
$Regions                = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
# $Columns                = 'Account', 'AccountID','RDS Instances','DynamoDB Tables'
$ColumnsFULL            = 'No.','Account', 'AccountID', 'Region', 'RDSInstances', 'DynamoDBTables'
$ColumnsDDBTables       = 'No.', 'Account', 'Region', 'TableName', 'TableBackup', 'CreationDateTime', 'ItemCount','TableSizeBytes', 'TableSizeMB', 'TableStatus', 'AccountID'
$RDSSnapshotColumns     = 'AvailabilityZone', 'DBInstanceIdentifier', 'DBSnapshotIdentifier', 'SnapshotCreateTime', 'SnapshotType', 'Status'
$ProfilesFULL           = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                      FUNCTIONS                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region FUNCTIONS

# function Get-DoAWSAccountList {
#     [CmdletBinding()]
#     param (
        
#     )
    
#     begin {

#         Clear-Host
#         Write-Host "AWS Account List"
#         Write-Host "--------------------------------"

#         $RegexGroupAccountName  = 'AccountName'
#         $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
#         $Profiles               = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }
        
#     }
    
#     process {

#         $AVSAccounts = @()

#         for ($i = 0; $i -lt $Profiles.Count; $i++) {
            
#             $Acc = [PSCustomObject]@{

#                 Number  = $($i + 1)
#                 Account = (($Profiles[$i].ProfileName | select-string -Pattern $RegexAccountName).Matches.Groups | Where-Object { $_.Name -eq $RegexGroupAccountName }).Value
                
#             }
#             $AVSAccounts += $Acc
#             Write-Host "$($Acc.Number). $($Acc.Account)"
#         }
        
#     }
    
#     end {

#         $AVSAccounts
        
#     }
# }
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

#                 Write-Host "Collected Details: Account - $($Sum.Account) | Region - $Region"

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

# function Get-DoDDBTableInformation {
#     [CmdletBinding()]
#     param (

#         $Profiles,
#         $Regions
#         # $Selection
        
         
#     )
    
#     begin {

#         $Count          = 1
#         $ddbTables      = @()
#         $ddbTableList   = @()
#         $RegexGroup             = 'AccountNumber'
#         $RegexGroupAccountName  = 'AccountName'
#         #$RegexAccountNumber     = "(?<$RegexGroup>\d+):db.+$"
#         $RegexAccountNumberDDb  = "(?<$RegexGroup>\d+):table.+$" 
#         $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
        
#     }
    
#     process {

#         foreach ($Profile in $Profiles) {

#             foreach ($Region in $Regions) {
                
#                 $ddbTableList   = Get-DDBTableList -ProfileName $Profile.ProfileName -Region $Region
#                 $ddbBackupList  = Get-DDBBackupList -ProfileName $Profile.ProfileName -Region $Region
            
#                 foreach ($ddbTable in $ddbTableList) {
                    
#                     $Table = Get-DDBTable -TableName $ddbTable -ProfileName $Profile.ProfileName -Region $Region
            
#                     if ($ddbBackupList) {
                        
#                         $BackupAvailable = $ddbBackupList.TableName.Contains("$($Table.TableName)")
#                     }
#                     else {
            
#                         $BackupAvailable = $false
#                     }
                          
#                     $Sum = [PSCustomObject]@{

#                         'No.'               = $Count++
#                         Account             = (($Profile.ProfileName | select-string -Pattern $RegexAccountName).Matches.Groups | Where-Object { $_.Name -eq $RegexGroupAccountName }).Value
#                         AccountID           = (($Table.TableArn | select-string -Pattern $RegexAccountNumberDDb).Matches.Groups | Where-Object { $_.Name -eq $RegexGroup }).Value
#                         Region              = $Region
#                         TableName           = $Table.TableName
#                         TableBackup         = $BackupAvailable
#                         CreationDateTime    = $Table.CreationDateTime
#                         ItemCount           = $Table.ItemCount
#                         TableSizeBytes      = $Table.TableSizeBytes
#                         TableSizeMB         = "$([math]::round($($Table.TableSizeBytes /1MB), 0)) MB"
#                         TableStatus         = $Table.TableStatus
#                         TableId             = $Table.TableId
#                         TableARN            = $Table.TableArn
#                         KeySchema           = $Table.KeySchema
#                         GlobalSecondaryIndexes = $Table.GlobalSecondaryIndexes
                        
#                     }
#                     $ddbTables += $Sum

#                     # if ($Selection -eq 0) {
                        
#                     #     Write-Host "Collected Table Details : Account - $($Sum.Account) | Region - $Region | Table - $($Sum.TableName)"

#                     # }

                    

#                 }
                
#             }
            
#         }
        
#     }
    
#     end {

#         $ddbTables
        
#     }
# }

# function Get-DoRDSDBSummary {
#     [CmdletBinding()]
#     param (

#         $Profiles,
#         $Regions
        
#     )
    
#     begin {

#         $Inst       = @()
#         # $Snap       = @()
#         # $Snapshots  = @()
        
#     }
    
#     process {

#         $Regions | ForEach-Object {
    
#             $RDSInstances = Get-RDSDBInstance -ProfileName $Profiles.ProfileName -Region $_
        
#             if ($RDSInstances) {
                
#                 foreach ($Instance in $RDSInstances) {
                    
#                     $Region = $_
#                     $DBInstanceArn      = $Instance.DBInstanceArn
#                     # $Tags               = Get-RDSTagForResource -ResourceName $DBInstanceArn -ProfileName $Profile.ProfileName

#                     $Shots  = Get-RDSDBSnapshot -ProfileName $Profiles.ProfileName -DBInstanceIdentifier $DBInstanceArn -Region $Region
                    
                    
#                     #$DBClusterSnapshots = Get-RDSDBClusterSnapshot -ProfileName $Profile.ProfileName -DBClusterIdentifier $DBInstanceArn
            
#                     $Sum = [PSCustomObject]@{
            
#                         Region                 = $_
#                         DBInstanceIdentifier    = $Instance.DBInstanceIdentifier
#                         Engine                  = $Instance.Engine
#                         Version                 = $Instance.EngineVersion
#                         InstanceCreateTime      = $Instance.InstanceCreateTime
#                         DBInstanceClass         = $Instance.DBInstanceClass
                        
#                         StorageThroughput       = $Instance.StorageThroughput
#                         #Tags                    = $Tags
#                         Snapshots               = ($Shots | Measure-Object).Count
#                         Retention               = $Instance.BackupRetentionPeriod
#                         #DBClusterSnapshots      = ($DBClusterSnapshots | Measure-Object).Count
            
#                     }
#                     $Inst += $Sum
#                     # $Snapshots += $Shots
            
#                 }
            
#                 # $Snapshots | ForEach-Object {
            
#                 #     $Sum = [PSCustomObject]@{
            
#                 #         DBInstanceIdentifier    = $_.DBInstanceIdentifier
#                 #         DBSnapshotIdentifier    = $_.DBSnapshotIdentifier
#                 #         SnapshotCreateTime      = $_.SnapshotCreateTime
#                 #         Engine                  = $_.Engine
#                 #         SnapshotType            = $_.SnapshotType
#                 #         Status                  = $_.Status
            
#                 #     }
#                 #     $Snap += $Sum
#                 # }
#             }

#         }
         
#     }
    
#     end {

#         $Inst
           
#     }
# }

# function Get-DoRDSSnapshotSummary {
#     [CmdletBinding()]
#     param (

#         $Profiles,
#         $Regions
        
#     )
    
#     begin {
            
#             $SummarySnapshots   = @()
#             $Snapshots          = @()
        
#     }
    
#     process {

#         $Regions | ForEach-Object {
    
#             $RDSInstances = Get-RDSDBInstance -ProfileName $Profiles.ProfileName -Region $_
        
#             if ($RDSInstances) {
                
#                 foreach ($Instance in $RDSInstances) {

#                     $Region = $_
                
#                     $DBInstanceArn      = $Instance.DBInstanceArn
#                     # $Tags               = Get-RDSTagForResource -ResourceName $DBInstanceArn -ProfileName $Profile.ProfileName
#                     $Shots              = Get-RDSDBSnapshot -ProfileName $Profiles.ProfileName -DBInstanceIdentifier $DBInstanceArn -Region $Region
#                     #$DBClusterSnapshots = Get-RDSDBClusterSnapshot -ProfileName $Profile.ProfileName -DBClusterIdentifier $DBInstanceArn

#                     $Snapshots += $Shots
            
#                 }
            
#                 $Snapshots | ForEach-Object {
            
#                     $Summary= [PSCustomObject]@{
                        
#                         AvailabilityZone        = $_.AvailabilityZone
#                         DBInstanceIdentifier    = $_.DBInstanceIdentifier
#                         DBSnapshotIdentifier    = $_.DBSnapshotIdentifier
#                         SnapshotCreateTime      = $_.SnapshotCreateTime
#                         Engine                  = $_.Engine
#                         SnapshotType            = $_.SnapshotType
#                         Status                  = $_.Status
            
#                     }
#                     $SummarySnapshots += $Summary
#                 }
#             }
        
#         }
        
#     }
    
#     end {
            
#         $SummarySnapshots
        
#     }
# }

# function Get-DoRegexDetails {
#     param (

#         $InputString,
#         $Pattern,
#         $Group
#     )

#     $Results = (($InputString | select-string -Pattern $Pattern).Matches.Groups | Where-Object { $_.Name -eq $Group }).Value
    
#     $Results
# }

# function Request-AnotherAccountSelection {
#     [CmdletBinding()]
#     param(
#         # [Parameter(Mandatory)]
#         # [ValidateNotNullOrEmpty()]
#         # [string]$Title,

#         [Parameter(Mandatory)]
#         [ValidateNotNullOrEmpty()]
#         [string]$Question
#     )
    
#     $yes = [ChoiceDescription]::new('&Yes', 'View Another Account')
#     $no = [ChoiceDescription]::new('&No', 'Quit and Exit')
    

#     $options = [ChoiceDescription[]]($yes, $no)

#     $result = $host.ui.PromptForChoice("", $Question, $options, 0)
#     # $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)

#     switch ($result) {
#         0 { 
             
#             $Option = $true

        
#         }
#         1 { 
            
#             $Option = $false
#         }
        
#     }

#     $Option

# }

# function Request-DatabaseTypeSelection {
#     [CmdletBinding()]
#     param(
#         # [Parameter(Mandatory)]
#         # [ValidateNotNullOrEmpty()]
#         # [string]$Title,

#         [Parameter(Mandatory)]
#         [ValidateNotNullOrEmpty()]
#         [string]$Question
#     )
    
#     $ddb = [ChoiceDescription]::new('&DynamoDB', 'View DynamoDB Table Details')
#     $rds = [ChoiceDescription]::new('&RDS', 'View RDS Database Details')
    

#     $options = [ChoiceDescription[]]($ddb, $rds)

#     $result = $host.ui.PromptForChoice("", $Question, $options, 0)
#     # $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)

#     switch ($result) {
#         0 { 
             
#             $Option = 'DynamoDB'

        
#         }
#         1 { 
            
#             $Option = 'RDS'
#         }
        
#     }

#     $Option

# }

# function Request-ViewBackupsSelection {
#     [CmdletBinding()]
#     param(
#         # [Parameter(Mandatory)]
#         # [ValidateNotNullOrEmpty()]
#         # [string]$Title,

#         [Parameter(Mandatory)]
#         [ValidateNotNullOrEmpty()]
#         [string]$Question
#     )
    
#     $yes = [ChoiceDescription]::new('&Yes', 'View Backups')
#     $no = [ChoiceDescription]::new('&No', 'Quit and Exit')
    

#     $options = [ChoiceDescription[]]($yes, $no)

#     $result = $host.ui.PromptForChoice("", $Question, $options, 0)
#     # $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)

#     switch ($result) {
#         0 { 
             
#             $Option = $true

        
#         }
#         1 { 
            
#             $Option = $false
#         }
        
#     }

#     $Option

# }

# function Request-YesNoSelection {
#     [CmdletBinding()]
#     param(
#         # [Parameter(Mandatory)]
#         # [ValidateNotNullOrEmpty()]
#         # [string]$Title,

#         [Parameter(Mandatory)]
#         [ValidateNotNullOrEmpty()]
#         [string]$Question
#     )
    
#     $yes = [ChoiceDescription]::new('&Yes', 'Confirm Question')
#     $no = [ChoiceDescription]::new('&No', 'Quit and Exit')
    

#     $options = [ChoiceDescription[]]($yes, $no)

#     $result = $host.ui.PromptForChoice("", $Question, $options, 0)
#     # $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)

#     switch ($result) {
#         0 { 
             
#             $Option = $true

        
#         }
#         1 { 
            
#             $Option = $false
#         }
        
#     }

#     $Option

# }



# #endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                        COLLECT ALL THE DATABASE INFORMATION                                                        #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region COLLECT ALL THE DATABASE INFORMATION

$SummaryFULL    = Get-DoAWSDBInformation $ProfilesFULL $Regions

#endregion

do {

    # ---------------------------------------------------------- View FULL Collection Results ---------------------------------------------------------- #
    #region View FULL Collection Results

    Clear-Host
    $SummaryFULL    | Select-Object $ColumnsFULL | Format-Table -AutoSize

    #endregion


    # ----------------------------------------------------- Filter Account list based on Selection ----------------------------------------------------- #
    #region Filter Account list based on Selection

    Write-Host ""
    $AccountSelection = Read-Host "Select Account Number (1 to $(($SummaryFULL | Measure-Object).Count)) " 

    switch ($AccountSelection) {
            
        ({$PSItem -in 1..$(($SummaryFULL | Measure-Object).Count)}) {

            $SelectedProfile = $ProfilesFULL | Where-Object { $_.ProfileName -match "$(($SummaryFULL | Where-Object { $_.'No.' -eq $AccountSelection }).Account)" }
        }
        ($PSItem -gt $(($SummaryFULL | Measure-Object).Count)) { 

            write-host "Invalid Selection"
        }
    }

    #endregion

    # -------------------------------------------------------- View Selected Account Information ------------------------------------------------------- #
    #region View Selected Account Information

    Clear-Host
    $SelectedAccountName = Get-DoRegexDetails $SelectedProfile.ProfileName $RegexAccountName $RegexGroupAccountName
    $SummaryFULL | Where-Object { $SelectedAccountName -match $_.Account  } | Select-Object $ColumnsFULL | Format-Table -AutoSize

    #endregion

    # ----------------------------------------------------------- Question - DynamoDB or RDS ----------------------------------------------------------- #
    #region Question - DynamoDB or RDS

    $OptionDatabaseType = Request-DatabaseTypeSelection -Question 'View DynamoDB or RDS Details'

    #endregion

    # ----------------------------------------------------------- View DynamoDB or RDS Details ----------------------------------------------------------- #
    #region View DynamoDB or RDS Details

    switch ($OptionDatabaseType) {

        DynamoDB { 

            # ---------------------------------------------------------- Collect DynamoDB Information ---------------------------------------------------------- #
            #region Collect DynamoDB Information

            Write-Host "Collecting DynamoDB Details for the [$SelectedAccountName] Account...!!"
            
            $DynamoDBSummary  = Get-DoDDBTableInformation $SelectedProfile $Regions
            $DynamoDBSummary | Select-Object $ColumnsDDBTables | Format-Table -AutoSize

            #endregion

            # ----------------------------------------------------- Check if any of the tables have backups ---------------------------------------------------- #
            #region Check if any of the tables have backups

            $TablesWithBackups = $DynamoDBSummary | Where-Object { $_.TableBackup -eq $true } | Select-Object $ColumnsDDBTables 
            
            if ($TablesWithBackups) {

                Write-Host "NOTE: $($TablesWithBackups.Count) tables in this account have backups" -ForegroundColor Yellow
                
                # ------------------------------------------------------------ Question - View Backups? ------------------------------------------------------------ #
                #region Question - View Backups?

                Write-Host ""
                $OptionViewBackups = Request-ViewBackupsSelection -Question 'View Backups?'
                
                # --------------------- Based on the user selection, the script will either display the tables with backups or exit the script. -------------------- #
                #region display the tables with backups or exit the script.

                switch ($OptionViewBackups) {
                    $true { 

                        $BackupsList    = Get-DDBBackupList -ProfileName $SelectedProfile.ProfileName 
                        $Columns        = 'TableName', 'BackupName', 'BackupCreationDateTime', 'BackupType', 'BackupStatus','BackupSizeBytes'
                        $BackupsList | Sort-Object BackupCreationDateTime -Descending  | Select-Object -Property $Columns | Format-Table -AutoSize

                        # Write-Host 'Press any key to continue...';
                        Write-Host '';
                        # $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

                     }
                    $false {

                        break
                    }
                }
                
                #endregion

                #endregion
            }
            
            #endregion

        }
        RDS {
                
                # ---------------------------------------------------------- Collect RDS Information ---------------------------------------------------------- #
                #region Collect RDS Information
    
                Write-Host "Collecting RDS Details for the [$SelectedAccountName] Account...!!"

                $RDS        = Get-DoRDSDBSummary $SelectedProfile $Regions 
                $Snapshots  = Get-DoRDSSnapshotSummary $SelectedProfile  $Regions
                $RDS | Format-Table -AutoSize
                
                #endregion

                # ----------------------------------------------------- Check if any Snapshots have been taken ----------------------------------------------------- #
                #region Check if any Snapshots have been taken

                if ($Snapshots) {
                    
                    Write-Host "NOTE: Snapshots available in this account" -ForegroundColor Yellow

                    # ----------------------------------------------------------- Question - View Snapshots? ----------------------------------------------------------- #
                    #region Question - View Snapshots?

                    Write-Host ''
                    $OptionViewSnapshots = Request-YesNoSelection -Question 'View Snapshots?'

                    # -------------------------- Based on the user selection, the script will either display the snapshots or exit the script. ------------------------- #
                    #region display the snapshots or exit the script.

                    switch ($OptionViewSnapshots) {
                        $true { 

                            foreach ($Instance in $RDS) {

                                if ($Instance.Snapshots -gt 0) {
                                    
                                    $Snapshots | Where-Object {$_.DBInstanceIdentifier -eq $Instance.DBInstanceIdentifier}  |Select-Object $RDSSnapshotColumns |
                                Sort-Object SnapshotCreateTime -Descending  |Format-Table -AutoSize

                                Write-Host ''
                                Write-Host 'Press any key to continue...';
                                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                                }

                            }

                        }
                        $false {

                            break
                        }
                    }
                    
                    #endregion
                    
                    #endregion

                }
                
                #endregion

                
        }
    }

    #endregion

    # ----------------------------------------------------------- Question - View Another Account ----------------------------------------------------------- #
    #region Question - View Another Account

    Write-Host ""
    $OptionAnotherAccount = Request-AnotherAccountSelection -Question 'View Another Account?'

    #endregion
    
} while (
    
    $OptionAnotherAccount -eq $true
)