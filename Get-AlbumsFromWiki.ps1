param(
	[Switch]$AllYears,
	[Switch]$ExportCache,
	[Switch]$UseCache,
	[Array]$Year = (Get-Date).Year
)
function Test-URL {
	param(
		$CurrentURL
	)
	try {
		$HTTPRequest = [System.Net.WebRequest]::Create($CurrentURL)
		$HTTPResponse = $HTTPRequest.GetResponse()
		$HTTPStatus = [Int]$HTTPResponse.StatusCode

		if ($HTTPStatus -ne 200) {
			return $False
		}

		$HTTPResponse.Close()

	}catch {
		return $False
	}	
	return $True
}
function Clean-HTMLString {
	param(
		$InputString
	)

	$InputString = $InputString -replace '<[^>]+>', ''
	$InputString = $InputString -replace '&amp;', ''
	$InputString = $InputString -replace "{", ""
	$InputString = $InputString -replace "}", ""
	
	return $InputString
}

if ($AllYears) {
	$Year = 1938..(Get-Date).Year
	$ThisYear = (Get-Date).Year
	if((!$UseCache)){
		Write-Warning "This will take some time. Getting music albums from 1938 to $ThisYear"
		Write-Warning "Be sure to use to use the -ExportCache parameter to speed up search times after this run"
	}

}

if ($ExportCache) {
	if (!(Test-Path "$PSScriptRoot\AlbumCache\")) {
		New-Item "$PSScriptRoot\AlbumCache\" -ItemType Directory
	}
}

$ListOfMonths = "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
$ArrayOfAlbums = [System.Collections.ArrayList]@()

$AlbumProps = [Ordered]@{
	Album       = $Null
	Artist      = $Null
	ReleaseDate = $Null
	ReleaseYear = $Null
}

foreach ($CurrentYear in $Year) {
	$Counter = 0
	if ($UseCache) {
		try {
			$ImportedAlbum = Import-Csv "$PSScriptRoot\AlbumCache\ListOf$($CurrentYear)Albums.csv"
		}
		catch {
			Write-Warning "Cache not found for $($CurrentYear) albums."
			Write-Warning "Please confirm you have exported $($CurrentYear) by typing in the below:"
			Write-Warning "Get-AlbumsFromWiki -Year $($CurrentYear) -ExportCache"
			Write-Warning "Then rerun the script using the -UseCache Parameter"
			continue
		}
		
		$ArrayOfAlbums += $ImportedAlbum
	}
	else {
		if ($CurrentYear -lt 2005) {
			$URL = "https://en.wikipedia.org/wiki/$($CurrentYear)_in_music"
		}
		else {
			$URL = "https://en.wikipedia.org/wiki/List_of_$($CurrentYear)_albums"
		}
		if ((Test-URL -CurrentURL $URL) -eq $True) {
		
			$WikiCurrentYearPage = Invoke-WebRequest $URL
			$Content = $WikiCurrentYearPage | ForEach-Object { $_.Content }
			$Content = $Content -split '\r?\n'
			$FoundAlbums = $False
			
			foreach ($Line in $Content) {
				if ($CurrentYear -gt 2004) {
					$ListOfMonths | ForEach-Object {
						if ($Line -like "*$_<br />*") {
							$ReleaseDate = $line
						}
					}
					if ($Line -like "*<i>*</i>") {
						$AlbumObj = New-Object -TypeName PSObject -Prop $AlbumProps
						$Album = $Line
						$Artist = $Content[$Counter - 2]
						$AlbumObj.Album = Clean-HTMLString -InputString $Album
						$AlbumObj.Artist = Clean-HTMLString -InputString $Artist
						$AlbumObj.ReleaseDate = Clean-HTMLString -InputString $ReleaseDate
						$AlbumObj.ReleaseYear = $CurrentYear
						$ArrayOfAlbums.Add($AlbumObj) | Out-Null
					}	
				
				}elseif($CurrentYear -gt 1962){
					if($Line -match "<b>[a-zA-Z]<br \/>"){
						$Month = $line
					  }
					  $ListOfMonths | ForEach-Object {
						if ($Line -match "id=`"$_`">") {
							$Month = $line
						}
					}
					  if($Line -match "`"center`">\d" -or $Line -match "`"vertical-align:top;`">\d" -or $Line -match "`"text-align:center;`">\d" -or $line -match "valign=`"top`">\d"){
						$ReleaseDate = $line
					  }
					  if($Line -like "<td>*<i>*</i></td>"){
						$AlbumObj = New-Object -TypeName PSObject -Prop $AlbumProps
						$Album = $Line
						$Album = $Album -replace '<[^>]+>',''
						$Artist = $Content[$Counter +1]
						$AlbumObj.ReleaseDate = (Clean-HTMLString -InputString $Month) + " " + (Clean-HTMLString -InputString $ReleaseDate)
						$AlbumObj.Artist = Clean-HTMLString -InputString $Artist  
						$AlbumObj.Album = Clean-HTMLString -InputString $Album
						$AlbumObj.ReleaseYear = $CurrentYear
						$ArrayOfAlbums.Add($AlbumObj) | Out-Null 
					  }	
				}else{
					if($Line -match "id=`"Biggest_hit_singles`">" -or $line -like "<p>These singles reached*" -or $Line -like "<p>The following songs achieved the highest*"){
						break
					}
					if($line -like "*id=`"Albums_released`"*"){
						$FoundAlbums = $True
						continue
					}
					if($FoundAlbums -eq $True){
						$AlbumObj = New-Object -TypeName PSObject -Prop $AlbumProps
						$ArtistAndAlbum = Clean-HTMLString $Line
						$ArtistAndAlbum = $ArtistAndAlbum -replace '\p{Pd}','-' #Returns unicode hypen instead of ascii, took an hour to figure that out.
						#https://stackoverflow.com/questions/43897530/powershell-ad-dls-hyphen-in-name-has-2-different-formats-escape-character-or-so
						$Album, $Artist = $ArtistAndAlbum -split "-"
						if($Album -like "*US No. 1 hit singles*" -or $album -like "*Biggest hit songs*"){	
							continue
						}
						$AlbumObj.Artist = Clean-HTMLString -InputString $Artist
						$AlbumObj.Album = Clean-HTMLString -InputString $Album
						$AlbumObj.ReleaseYear = $CurrentYear
						$ArrayOfAlbums.Add($AlbumObj) | Out-Null 
					}
				}
				$Counter++
			}
			if ($ExportCache) {
				$ArrayOfAlbums | Where-Object { $_.ReleaseYear -eq "$CurrentYear" } | Export-Csv "$PSScriptRoot\AlbumCache\ListOf$($CurrentYear)Albums.csv" -NoTypeInformation
			}
		}
		else {
			Write-Warning "$URL is not a valid link"
		}
	}
}
$ArrayOfAlbums
