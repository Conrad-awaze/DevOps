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
  
  # -------------------------------------------------------------------------------------------------------------------------------------------------- #
  $Navigation = @(
      New-UDListItem -Label "Home"
      New-UDListItem -Label "Getting Started" -Children {
          New-UDListItem -Label "Installation" -Icon (New-UDIcon -Icon envelope) -OnClick { Invoke-UDRedirect '/installation' }
          New-UDListItem -Label "Usage" -Icon (New-UDIcon -Icon edit) -OnClick { Invoke-UDRedirect '/usage' }
          New-UDListItem -Label "FAQs" -Icon (New-UDIcon -Icon trash) -OnClick { Invoke-UDRedirect '/faqs' }
          New-UDListItem -Label "System Requirements" -Icon (New-UDIcon -Icon bug) -OnClick { Invoke-UDRedirect '/requirements' }
          New-UDListItem -Label "Purchasing" -OnClick { Invoke-UDRedirect '/purchasing'}
      }
  )
  # -------------------------------------------------------------------------------------------------------------------------------------------------- #
  New-UDDashboard -Theme $theme -Title "Database Monitor" -Content {
      
    New-UDCard -Title 'Account Details' -Content {
  
        "View a summary of an AWS Account."
    }
  
    # ------------------------------------------------------------------ Account Table ----------------------------------------------------------------- #
    # $Data = @(
    #   @{Dessert = 'Frozen yoghurt'; Calories = 159; Fat = 6.0; Carbs = 24; Protein = 4.0}
    #   @{Dessert = 'Ice cream sandwich'; Calories = 159; Fat = 6.0; Carbs = 24; Protein = 4.0}
    #   @{Dessert = 'Eclair'; Calories = 159; Fat = 6.0; Carbs = 24; Protein = 4.0}
    #   @{Dessert = 'Cupcake'; Calories = 159; Fat = 6.0; Carbs = 24; Protein = 4.0}
    #   @{Dessert = 'Gingerbread'; Calories = 159; Fat = 6.0; Carbs = 24; Protein = 4.0}
    # ) 
  
    # $Columns = @(
    #     New-UDTableColumn -Property Dessert -Title "A Dessert"
    #     New-UDTableColumn -Property Calories -Title Calories 
    #     New-UDTableColumn -Property Fat -Title Fat 
    #     New-UDTableColumn -Property Carbs -Title Carbs 
    #     New-UDTableColumn -Property Protein -Title Protein 
    # )
  
    # New-UDTable -Id 'customColumnsTable' -Data $Data -Columns $Columns
  
  #   $Data = @(
  #     @{Account = 'Apex-PROD'; AccountID = 463854377715; Region = 'eu-west-2'; RDSInstances = 24; DynamoDBTables = 8}
  #     @{Account = 'Owner-DK-Prod'; AccountID = 619122104288; Region = 'eu-west-2'; RDSInstances = 0; DynamoDBTables = 1}
  #     @{Account = 'Eclair'; AccountID = 159; Region = 6.0; RDSInstances = 24; DynamoDBTables = 4.0}
  #     @{Account = 'Cupcake'; AccountID = 159; Region = 6.0; RDSInstances = 24; DynamoDBTables = 4.0}
  #     @{Account = 'Gingerbread'; AccountID = 159; Region = 6.0; RDSInstances = 24; DynamoDBTables = 4.0}
  # ) 
  $Columns        =  'Account', 'AccountID', 'Region', 'RDSInstances', 'DynamoDBTables'
  $AccountName    = 'AVR-Guest'
  $AccountSummary = Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/$AccountName -Method GET
  
  #$AccountSummary | Format-Table
  
  $Option = New-UDTableTextOption -Search "Search all these records"
  
  # $Columns = @(
  #     New-UDTableColumn -Property Dessert -Title Dessert -Render { 
  #         New-UDButton -Id "btn$($EventData.Dessert)" -Text "Click for Dessert!" -OnClick { Show-UDToast -Message $EventData.Dessert } 
  #     }
  #     New-UDTableColumn -Property Calories -Title Calories -Width 5 -Truncate
  #     New-UDTableColumn -Property Fat -Title Fat 
  #     New-UDTableColumn -Property Carbs -Title Carbs 
  #     New-UDTableColumn -Property Protein -Title Protein 
  # )
  
  New-UDTable -Data $($AccountSummary | Select-Object $Columns) -TextOption $Option -ShowSearch 
  
    #New-UDButton -Text 'Add user' -Color primary
  
    # ------------------------------------------------------------- Account Drop Down List ------------------------------------------------------------- #
    # $RegexGroupAccountName  = 'AccountName'
    # $RegexAccountName       = "(?<PreFix>DevOps-)(?<$RegexGroupAccountName>.+)"
    # $AccountList = (Get-AWSCredentials -ListProfileDetail | Where-Object { $_.ProfileName -like 'DevOps*' }).ProfileName
    # $AccountList = $AccountList | ForEach-Object { (($_| select-string -Pattern $RegexAccountName).Matches.Groups | Where-Object { $_.Name -eq $RegexGroupAccountName }).Value }
    # New-UDAutocomplete -Options @( $AccountList) -id 'AccountList' -Label 'Account Name' -Value 'Select Account Name' 
  
  
  
  
  
  
  } -Navigation $Navigation -NavigationLayout Permanent