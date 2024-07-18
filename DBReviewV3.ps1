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
$ProfilesFULL           = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                      FUNCTIONS                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region FUNCTIONS
function Request-AnotherAccountSelection {
    [CmdletBinding()]
    param(
        # [Parameter(Mandatory)]
        # [ValidateNotNullOrEmpty()]
        # [string]$Title,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Question
    )
    
    $yes = [ChoiceDescription]::new('&Yes', 'View Another Account')
    $no = [ChoiceDescription]::new('&No', 'Quit and Exit')
    

    $options = [ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice("", $Question, $options, 0)
    # $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)

    switch ($result) {
        0 { 
             
            $Option = $true

        
        }
        1 { 
            
            $Option = $false
        }
        
    }

    $Option

}

#endregion

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

        }
        RDS {}
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

