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
$RDSSnapshotColumns  = 'AvailabilityZone', 'DBInstanceIdentifier', 'DBSnapshotIdentifier', 'SnapshotCreateTime', 'SnapshotType', 'Status'
$ProfilesFULL           = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                      FUNCTIONS                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region FUNCTIONS

#endregion

# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #                                                        COLLECT ALL THE DATABASE INFORMATION                                                        #
# # -------------------------------------------------------------------------------------------------------------------------------------------------- #
# #region COLLECT ALL THE DATABASE INFORMATION

# $SummaryFULL    = Get-DoAWSDBInformation $ProfilesFULL $Regions

# #endregion

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

