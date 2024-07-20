using namespace System.Management.Automation.Host

Remove-Module DevOpsToolkit
Import-Module AWS.Tools.Common, AWS.Tools.DynamoDBv2, AWS.Tools.RDS
Import-Module '/Users/conrad.gauntlett/WorkArea/Repos/DBA_MISC/PowerShell/Modules/DevOpsToolkit'

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                     PARAMATERS                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region PARAMATERS

# $ddbParametersTable     = 'DBA-Parameters'
# $ProfileNameCommon      = 'DBA-Common'
# $keyTeams               = @{ PK = 'Teams'; SK = 'ChannelGUIDs'} | ConvertTo-DDBItem
# $Teams                  = Get-DDBItem -TableName $ddbParametersTable -Key $keyTeams -ProfileName $ProfileNameCommon | ConvertFrom-DDBItem
# $URI                    = "https://awazecom.webhook.office.com/webhookb2/$($Teams.DBAAWSGUID1)/IncomingWebhook/$($Teams.DBAAWSGUID2)"
$Regions                = "eu-central-1" , "eu-west-2" , "eu-west-1", "us-east-1"
$Columns                = 'Account', 'AccountID','RDS Instances','DynamoDB Tables'
$Profiles               = Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }

#endregion

# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                      FUNCTIONS                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region FUNCTIONS

function New-Menu {
    [CmdletBinding()]
    param(
        # [Parameter(Mandatory)]
        # [ValidateNotNullOrEmpty()]
        # [string]$Title,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Question
    )
    
    $ddb = [ChoiceDescription]::new('&DynamoDB', 'View DynamoDB Table Details')
    $rds = [ChoiceDescription]::new('&RDS', 'View RDS Database Details')
    

    $options = [ChoiceDescription[]]($ddb, $rds)

    $result = $host.ui.PromptForChoice("", $Question, $options, 0)
    # $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)

    switch ($result) {
        0 { 
             
            $Option = 'DynamoDB'

        
        }
        1 { 
            
            $Option = 'RDS'
        }
        
    }

    $Option

}

function New-AccountSelection {
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
#                                                              COLLECT DATABASE DETAILS                                                              #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#region COLLECT DATABASE DETAILS

$AVSAccounts =  Get-DoAWSAccountList

Write-Host ""
$Selection = Read-Host "Select Account Number (0 for All Accounts) " 

switch ($Selection) {
    
    0 { 

        $AccountProfiles = $Profiles 
    
    }
    ({$PSItem -in 1..14}) {

        $AccountProfiles = $Profiles | Where-Object { $_.ProfileName -match "$(($AVSAccounts | Where-Object { $_.Number -eq $Selection }).Account)" }
    }
    'q' { 

        Break 
    }
}

$Summary    = Get-DoAWSDBInformation $AccountProfiles $Regions
Clear-Host
$Summary    | Select-Object 'No.',Account, AccountID, Region, RDSInstances, DynamoDBTables | Format-Table -AutoSize

#endregion

# Write-Host 'Press any key to continue...';
Write-Host '';
# $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

# ------------------------------------------------- Check if a single or all accounts are requested ------------------------------------------------ #
$Count = 0
if ($Selection -eq 0) {

    do {

        # -------------------------------------------- Clear the screen if it's the second time through the loop ------------------------------------------- #

        $Count++
        if ($Count -gt 1) {
            Clear-Host
            $Summary    | Select-Object 'No.',Account, AccountID, Region, RDSInstances, DynamoDBTables | Format-Table -AutoSize
        }

        Write-Host ""
        $Selection = Read-Host "Select Account Number (1 to $(($Summary | Measure-Object).Count)) " 

        switch ($Selection) {
        
            ({$PSItem -in 1..$(($Summary | Measure-Object).Count)}) {
        
                $AccountProfiles = $Profiles | Where-Object { $_.ProfileName -match "$(($Summary | Where-Object { $_.'No.' -eq $Selection }).Account)" }
            }
            ($PSItem -gt $(($Summary | Measure-Object).Count)) { 
        
                write-host "Invalid Selection"
            }
        }
        
        # -------------------------------------------------------------------------------------------------------------------------------------------------- #
        #                                                              COLLECT DYNAMODB DETAILS                                                              #
        # -------------------------------------------------------------------------------------------------------------------------------------------------- #
        #region COLLECT DYNAMODB DETAILS
    
        $ddbTables = Get-DoDDBTableInformation $AccountProfiles $Regions 
        $ddbTables | Select-Object 'No.',Account, Region, TableName, TableBackup, CreationDateTime, ItemCount,TableSizeBytes, TableSizeMB, TableStatus, AccountID | Format-Table -AutoSize
    
        #endregion
    
        $OptionAnotherAccount = New-AccountSelection -Question 'View Another Account?'
        
    } while (

        $OptionAnotherAccount -eq $true
        
    )
    

}else {
    if ($Count -gt 0) {
        Write-Host "Looping through the accounts..."
    }

    $Option = New-Menu -Question 'View DynamoDB or RDS Details?'

    switch ($Option) {

        DynamoDB { 

            if ($Selection -eq 0) {
        
                $AVSAccounts =  Get-DoAWSAccountList
            
                Write-Host ""
                $Selection = Read-Host "Select Account Number (0 for All Accounts) " 
            
                switch ($Selection) {
                
                    0 { 
                
                        $AccountProfiles = $Profiles 
                    
                    }
                    ({$PSItem -in 1..14}) {
                
                        $AccountProfiles = $Profiles | Where-Object { $_.ProfileName -match "$(($AVSAccounts | Where-Object { $_.Number -eq $Selection }).Account)" }
                    }
                    'q' { 
                
                        Break 
                    }
                }
                
                # -------------------------------------------------------------------------------------------------------------------------------------------------- #
                #                                                              COLLECT DYNAMODB DETAILS                                                              #
                # -------------------------------------------------------------------------------------------------------------------------------------------------- #
                #region COLLECT DYNAMODB DETAILS
            
                $ddbTables = Get-DoDDBTableInformation $AccountProfiles $Regions 
                $ddbTables | Select-Object Account, Region, TableName, TableBackup, CreationDateTime, ItemCount,TableSizeBytes, TableSizeMB, TableStatus, AccountID | Format-Table -AutoSize
            
                #endregion
            
            }else {
                
                # -------------------------------------------------------------------------------------------------------------------------------------------------- #
                #                                                              COLLECT DYNAMODB DETAILS                                                              #
                # -------------------------------------------------------------------------------------------------------------------------------------------------- #
                #region COLLECT DYNAMODB DETAILS

                Write-Host "Collecting DynamoDB Details for the [$($AccountProfiles.ProfileName)] Account...!!"
            
                $ddbTables = Get-DoDDBTableInformation $AccountProfiles $Regions $Selection
                $ddbTables | Select-Object 'No.',Account, Region, TableName, TableBackup, CreationDateTime, ItemCount,TableSizeBytes, TableSizeMB, TableStatus, AccountID | Format-Table -AutoSize
            
                #endregion

                $OptionAnotherAccount = New-AccountSelection -Question 'View Another Account?'

                do {

                    # -------------------------------------------- Clear the screen if it's the second time through the loop ------------------------------------------- #
            
                    $Count++
                    if ($Count -gt 0) {
                        
                        $AVSAccounts =  Get-DoAWSAccountList
                        $AccountProfiles = $Profiles
                    }
            
                    Write-Host ""
                    $Selection = Read-Host "Select Account Number (1 to $(($AVSAccounts| Measure-Object).Count)) " 
            
                    switch ($Selection) {
                    
                        ({$PSItem -in 1..$(($AVSAccounts | Measure-Object).Count)}) {
                    
                            $AccountProfiles = $Profiles | Where-Object { $_.ProfileName -match "$(($AVSAccounts | Where-Object { $_.Number -eq $Selection }).Account)" }
                        }
                        ($PSItem -gt $(($AVSAccounts | Measure-Object).Count)) { 
                    
                            write-host "Invalid Selection"
                        }
                    }

                    $Summary    = Get-DoAWSDBInformation $AccountProfiles $Regions
                    Clear-Host
                    $Summary    | Select-Object 'No.',Account, AccountID, Region, RDSInstances, DynamoDBTables | Format-Table -AutoSize

                    $Option = New-Menu -Question 'View DynamoDB or RDS Details?'
                    
                    # -------------------------------------------------------------------------------------------------------------------------------------------------- #
                    #                                                              COLLECT DYNAMODB DETAILS                                                              #
                    # -------------------------------------------------------------------------------------------------------------------------------------------------- #
                    #region COLLECT DYNAMODB DETAILS
                
                    $ddbTables = Get-DoDDBTableInformation $AccountProfiles $Regions 
                    $ddbTables | Select-Object 'No.',Account, Region, TableName, TableBackup, CreationDateTime, ItemCount,TableSizeBytes, TableSizeMB, TableStatus, AccountID | Format-Table -AutoSize
                
                    #endregion
                
                    # $OptionAnotherAccount = New-AccountSelection -Question 'View Another Account?'
                    
                } while (
            
                    $OptionAnotherAccount -eq $true
                    
                )

            }

        }
        RDS {
            Write-Host 'RDS'
        }
    }
        
   
    
    
}














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