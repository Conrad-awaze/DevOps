$AccountName = 'Apex-PROD'
$AccountName = 'Owner-DK-Prod'

$AccountSummary = Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/$AccountName -Method GET
$AccountSummary | Format-Table

Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/Apex-PROD -Method GET

$AccountSummaryAll = Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummaryALL/ -Method GET
$AccountSummaryAll | Select-Object 'No.', 'Account', 'AccountID', 'Region', 'RDSInstances', 'DynamoDBTables' | Format-Table

