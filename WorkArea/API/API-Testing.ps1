$AccountName    = 'Apex-PROD'
$AccountName    = 'AVR-Pricing-PROD'
$Columns        = 'No.', 'Account', 'AccountID', 'Region', 'RDSInstances', 'DynamoDBTables'
$AccountSummary = Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/$AccountName -Method GET
$AccountSummary | Format-Table

Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/AVR-Pricing-PROD -Method GET

$AccountSummaryAll = Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/AllAccounts -Method GET
$AccountSummaryAll | Select-Object $Columns | Format-Table



Invoke-RestMethod http://localhost:5000/DBMonitor/GetDDBTableInformation/$AccountName -Method GET






