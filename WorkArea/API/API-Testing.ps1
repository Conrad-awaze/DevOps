$AccountName = 'Apex-PROD'
$AccountName = 'Owner-DK-Prod'

$AccountSummary = Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/$AccountName -Method GET
$AccountSummary | Format-Table

Invoke-RestMethod http://localhost:5000/DBMonitor/GetAccountSummary/Apex-PROD -Method GET


