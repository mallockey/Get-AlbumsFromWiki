<#
This script uses the Get-AlbumsFromWiki and Twilio to send the newest albums of the month.
#>
function Prepare-SendString{
	param(
		$InputObjects
	)
	$String = ""
	
		$InputObjects | Foreach-Object {
			$CurrentAlbum = $_ | Select-Object -ExpandProperty Album
			$CurrentArtist = $_ | Select-Object -ExpandProperty Artist
			$CurrentReleaseDate = $_ | Select-Object -ExpandProperty ReleaseDate
			$String += "$currentAlbum by: $currentArtist released: $currentReleaseDate | `n"
	}
	return $String
}

$fromNumber = "Twilio Number"
$toNumber = "Your Number"
$accountSID = ''
$authToken = ''
$CurrentMonth =  (Get-Culture).DateTimeFormat.GetMonthName((Get-Date).Month)
$LatestAlbums = .\Get-AlbumsFromWiki -Year (Get-Date).Year | Where-Object {$_.ReleaseDate -like "*$CurrentMonth*"}

$String = Prepare-SendString $LatestAlbums

if($String.Length -gt 400){
	$String = Prepare-SendString ($LatestAlbums | Select-Object -First 3)
}

C:\Scripts\BirthdayReminder\Send-TwilioSMS.ps1 -AccountSID $accountSID -AuthToken $authToken -FromNumber $fromNumber -ToNumber $toNumber -Message $String
