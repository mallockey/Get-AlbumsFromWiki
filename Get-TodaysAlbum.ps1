#Build our string to include like the HTML returned
#Ex: February14th
$TodaysMonth = (Get-Date).Month
$TodaysDate = (Get-Date).Day
$TodaysMonthConverted = (Get-Culture).DateTimeFormat.GetMonthName($TodaysMonth)
$TodaysDateString = "$($TodaysMonthConverted)$($TodaysDate)"

Get-AlbumsFromWiki.ps1 | Where-Object {$_.ReleaseDate -like $TodaysDateString}