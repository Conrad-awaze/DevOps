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
  
  New-UDDashboard -Theme $theme -Title "Database Monitor"  -Content {
      
    New-UDCard -Title 'Account Summary' -Content {
  
        "View a summary of the AWS Accounts."
    }
  
    # --------------------------------------------------------------- Get Account Summary -------------------------------------------------------------- #
    #region Get Account Summary
  
    $AccountName    = 'Apex-PROD'
    $AccountSummary = Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/$AccountName -Method GET
  
    $Columns = @(
        New-UDTableColumn -Property 'Account' -Title 'Account'
        New-UDTableColumn -Property 'AccountID' -Title 'AccountID'
        New-UDTableColumn -Property 'Region' -Title 'Region' 
        New-UDTableColumn -Property 'RDSInstances' -Title 'RDSInstances' 
        New-UDTableColumn -Property 'DynamoDBTables' -Title 'DynamoDBTables' 
        New-UDTableColumn -Property 'Details' -Title 'Details' -Render { 
          New-UDButton -Id "btn$($EventData.Account)" -Text "View Details" -OnClick { 
            Show-UDToast -Message $EventData.Account 
          } 
      }
    )
  
    New-UDTable -Data $($AccountSummary) -Columns $Columns
    
    #endregion
  
  
  } -Navigation $Navigation -NavigationLayout Permanent 