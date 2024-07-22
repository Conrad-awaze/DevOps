$Theme = @{
  palette = @{
    primary = @{
      light = '#63ccff'
      main = '#009be5'
      dark = '#006db3'
    }
  }
  typography = @{
    h5 = @{
      fontWeight = 500
      fontSize = 26
      letterSpacing = 0.5
    }
  }
  shape = @{
    borderRadius = 8
  }
  mixins = @{
    toolbar = @{
      minHeight = 48
    }
  }
  overrides = @{
    MuiDrawer = @{
        paper = @{
          backgroundColor = '#081627'
        }
    }
    MuiButton = @{
        label = @{
            textTransform = 'none'
        }
        contained = @{
          boxShadow = 'none'
          '&:active' = @{
            boxShadow = 'none'
          }
        }
    }
    MuiTabs = @{
        root = @{
          marginLeft = 1
        }
        indicator = @{
          height = 3
          borderTopLeftRadius = 3
          borderTopRightRadius = 3
          backgroundColor = '#000'
        }
    }
    MuiTab = @{
        root = @{
            textTransform = 'none'
            margin = '0 16px'
            minWidth = 0
            padding = 0
        }
    }
    MuiIconButton = @{
        root = @{
          padding = 1
        }
    }
    MuiTooltip = @{
        tooltip = @{
          borderRadius = 4
        }
    }
    MuiDivider = @{
        root = @{
          backgroundColor = 'rgb(255,255,255,0.15)'
        }
    }
    MuiListItemButton = @{
        root = @{
          '&.Mui-selected' = @{
            color = '#4fc3f7'
          }
        }
    }
    MuiListItemText = @{
        primary = @{
            color = 'rgba(255, 255, 255, 0.7) '
          fontSize = 14
          fontWeight = 500
        }
    }
    MuiListItemIcon = @{
        root = @{
          color = 'rgba(255, 255, 255, 0.7) '
          minWidth = 'auto'
          marginRight = 2
          '& svg' = @{
            fontSize = 20
          }
        }
    }
    MuiAvatar = @{
        root = @{
          width = 32
          height = 32
        }
    }
  }
}

New-UDDashboard -Theme $theme -Title "Database Monitor" -Content {

  # -------------------------------------------------------------- Generate Account list ------------------------------------------------------------- #
  #region Generate Account list

  $RegexGroupAccountName  = 'AccountName'
  $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
  $AccountList = (Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }).ProfileName
  $AccountList = $AccountList | ForEach-Object { (($_| select-string -Pattern $RegexAccountName).Matches.Groups | Where-Object { $_.Name -eq $RegexGroupAccountName }).Value }
  $AccountList += 'AllAccounts'
  
  #endregion
    
  New-UDCard -Title 'Account Summary' -Content {

      "View a summary of the AWS Accounts."
  }

  New-UDForm -Content {

    # ------------------------------------------------------------- Account Drop Down List ------------------------------------------------------------- #
    New-UDSelect -Option {
      $AccountList | ForEach-Object {
        New-UDSelectOption -Name $_ -Value $_
      }
  } -Label 'Account Name' -Id 'AccountList' 

    #New-UDAutocomplete -Options @( $AccountList) -id 'AccountList' -Label 'Account Name' -Value 'Select Account Name' 

  } -OnSubmit {

    # --------------------------------------------------------------- Get Account Summary -------------------------------------------------------------- #
    #region Get Account Summary

    $AccountName    = "$($EventData.AccountList)"
    $AccountSummary = Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/$AccountName -Method GET

    $Columns = @(
        New-UDTableColumn -Property 'Account' -Title 'Account' -IncludeInSearch
        New-UDTableColumn -Property 'AccountID' -Title 'AccountID'
        New-UDTableColumn -Property 'Region' -Title 'Region' -IncludeInSearch
        New-UDTableColumn -Property 'RDSInstances' -Title 'RDSInstances' 
        New-UDTableColumn -Property 'DynamoDBTables' -Title 'DynamoDBTables' 
        New-UDTableColumn -Property 'Details' -Title 'Details' -Render { 
          New-UDButton -Id "btn$($EventData.Account)" -Text "View Details" -OnClick { 
            Show-UDToast -Message $EventData.Account 
          } 
      }
    )

    Set-UDElement -Id 'results' -Content {

      New-UDTable -Data $($AccountSummary) -Columns $Columns -ShowPagination -ShowSearch

    }

    
    
    #endregion

  } -OnProcessing {

    New-UDTypography -Text 'Processing...' -Variant h6
    New-UDProgress

  }

  New-UDElement -Id 'results' -Tag 'div'
  

} #-Navigation $Navigation -NavigationLayout Temporary 