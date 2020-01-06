#This script uses the scraper to get the latest albums in between the lowerbound and upperbound
function Prepare-SendString{
	param(
		$InputObjects
	)
	$String = ""
		$Counter = 1
		$InputObjects | Foreach-Object {
			$CurrentAlbum = $_ | Select-Object -ExpandProperty Album
			$CurrentArtist = $_ | Select-Object -ExpandProperty Artist
			$CurrentReleaseDate = $_ | Select-Object -ExpandProperty ReleaseDate
			$String += "$Counter | '$currentAlbum' by $currentArtist | $currentReleaseDate |`n"
			$Counter++
	}
	return $String
}

$LowerBound = (Get-Date).Day - 3
$UpperBound = (Get-Date).Day + 6
$fromNumber = ""
$toNumber = "" 
$accountSID = ''
$authToken = ''
$CurrentMonth =  (Get-Culture).DateTimeFormat.GetMonthName((Get-Date).Month)
$LatestAlbums = C:\Scripts\Send-LatestAlbums\Get-AlbumsFromWiki.ps1 -Year (Get-Date).Year | Where-Object {$_.ReleaseDate -like "*$CurrentMonth*"}

$SendAlbums = @()
foreach($Album in $LatestAlbums){
	[Int]$Date = $Album.ReleaseDate -replace "[^0-9]"
	if($Date -gt $LowerBound -and $Date -lt $UpperBound){
		$SendAlbums += $Album
	}
	
}

$String = Prepare-SendString $SendAlbums

if($String.Length -gt 400){
	$String = Prepare-SendString ($LatestAlbums | Select-Object -First 3)
}

C:\Scripts\Send-TwilioSMS.ps1 -AccountSID $accountSID -AuthToken $authToken -FromNumber $fromNumber -ToNumber $toNumber -Message $String
