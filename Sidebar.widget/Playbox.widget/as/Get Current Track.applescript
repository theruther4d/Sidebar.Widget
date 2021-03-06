global artistName, songName, albumName, songRating, songDuration, currentPosition, musicapp, apiKey, songMetaFile
property blackStar : "★"
property whiteStar : "☆"
set metaToGrab to {"artistName", "songName", "albumName", "songRating", "songDuration", "currentPosition"}

set apiKey to "2e8c49b69df3c1cf31aaa36b3ba1d166"
tell application "Finder" to set mypath to POSIX path of (container of (path to me) as alias)
set songMetaFile to (mypath & "songMeta.plist" as string)

if isMusicPlaying() is true then

	getSongMeta()

	writeSongMeta({"currentPosition" & "##" & currentPosition})

	if didSongChange() is true then
		writeSongMeta({¬
			"artistName" & "##" & artistName, ¬
			"songName" & "##" & songName, ¬
			"songRating" & "##" & songRating, ¬
			"songDuration" & "##" & songDuration ¬
			})
		writeSongMeta({"albumName" & "##" & albumName})
	end if

	spitOutput(metaToGrab) as string
else
	return "NA"
end if

------------------------------------------------
---------------SUBROUTINES GALORE---------------
------------------------------------------------

on isMusicPlaying()
	set apps to {"iTunes", "Spotify"}
	set answer to false
	repeat with anApp in apps
		tell application "System Events" to set isRunning to (name of processes) contains anApp
		if isRunning is true then
			try
				using terms from application "iTunes"
					tell application anApp
						if player state is playing then
							set musicapp to (anApp as string)
							set answer to true
						end if
					end tell
				end using terms from
			on error e
				my logEvent(e)
			end try
		end if
	end repeat
	return answer
end isMusicPlaying

on getSongMeta()
	try
		if musicapp is "iTunes" then
			tell application "iTunes"
				set {artistName, songName, albumName, rawRating, songDuration} to {artist, name, album, rating, duration} of current track
				set currentPosition to player position
			end tell
		else if musicapp is "Spotify" then
			tell application "Spotify"
				set {artistName, songName, albumName, rawRating, songDuration} to {artist, name, album, popularity, duration} of current track
				set currentPosition to my roundDown(player position as string)
			end tell
		end if
		set songRating to convertRating(rawRating)
	on error e
		my logEvent(e)
	end try
end getSongMeta

on didSongChange()
	set answer to false
	try
		set currentSongMeta to artistName & songName
		set savedSongMeta to (readSongMeta({"artistName"}) & readSongMeta({"songName"}) as string)
		if currentSongMeta is not savedSongMeta then set answer to true
	on error e
		my logEvent(e)
	end try
	return answer
end didSongChange

on readSongMeta(keyNames)
	set valueList to {}
	tell application "System Events" to tell property list file songMetaFile to tell contents
		repeat with keyName in keyNames
			try
				set keyValue to value of property list item keyName
			on error e
				my logEvent("Reading song metadata" & space & e)
				my writeSongMeta({keyName & "##" & "NA"})
				set keyValue to value of property list item keyName
			end try

			copy keyValue to the end of valueList
		end repeat
	end tell
	return valueList
end readSongMeta

on writeSongMeta(keys)
	tell application "System Events"
		if my checkFile(songMetaFile) is false then
			-- create an empty property list dictionary item
			set the parent_dictionary to make new property list item with properties {kind:record}
			-- create new property list file using the empty dictionary list item as contents
			set this_plistfile to ¬
				make new property list file with properties {contents:parent_dictionary, name:songMetaFile}
		end if
		try
			repeat with aKey in keys
				set AppleScript's text item delimiters to "##"
				set keyName to text item 1 of aKey
				set keyValue to text item 2 of aKey
				set AppleScript's text item delimiters to ""
				make new property list item at end of property list items of contents of property list file songMetaFile ¬
					with properties {kind:string, name:keyName, value:keyValue}
			end repeat
		on error e
			my logEvent(e)
		end try
	end tell
end writeSongMeta

on spitOutput(metaToGrab)
	set valuesList to {}
	repeat with metaPiece in metaToGrab
		set valuesList to valuesList & readSongMeta({metaPiece}) & " ~ "
	end repeat
	return items 1 thru -2 of valuesList
end spitOutput

on roundDown(aNumber)
	set delimiters to {",", "."}
	repeat with aDelimiter in delimiters
		if aNumber contains aDelimiter then
			set AppleScript's text item delimiters to aDelimiter
			set outNumber to text item 1 of aNumber & "000"
			set AppleScript's text item delimiters to ""
		else
			set outNumber to aNumber
		end if
	end repeat
	return outNumber
end roundDown

on convertRating(rawRating)
	set stars to (rawRating div 20)
	if rawRating is greater than 0 and stars is equal to 0 then
		set stars to 1
	end if
	set songRating to "" as Unicode text
	repeat with i from 1 to stars
		set songRating to songRating & blackStar
	end repeat
	repeat with i from stars to 4
		set songRating to songRating & whiteStar
	end repeat
	return songRating
end convertRating

on encodeText(this_text, encode_URL_A, encode_URL_B, method)
	--http://www.macosxautomation.com/applescript/sbrt/sbrt-08.html
	set the standard_characters to "abcdefghijklmnopqrstuvwxyz0123456789"
	set the URL_A_chars to "$+!'/?;&@=#%><{}[]\"~`^\\|*"
	set the URL_B_chars to ".-_:"
	set the acceptable_characters to the standard_characters
	if encode_URL_A is false then set the acceptable_characters to the acceptable_characters & the URL_A_chars
	if encode_URL_B is false then set the acceptable_characters to the acceptable_characters & the URL_B_chars
	set the encoded_text to ""
	repeat with this_char in this_text
		if this_char is in the acceptable_characters then
			set the encoded_text to (the encoded_text & this_char)
		else
			set the encoded_text to (the encoded_text & encode_char(this_char, method)) as string
		end if
	end repeat
	return the encoded_text
end encodeText

on encode_char(this_char, method)
	set the ASCII_num to (the ASCII number this_char)
	set the hex_list to {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	set x to item ((ASCII_num div 16) + 1) of the hex_list
	set y to item ((ASCII_num mod 16) + 1) of the hex_list
	if method is 1 then
		return ("%" & x & y) as string
	else if method is 2 then
		return "_" as string
	end if
end encode_char

on replace(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace

on logEvent(e)
	do shell script "echo '" & (current date) & space & e & "' >> ~/Library/Logs/Playbox-Widget.log"
end logEvent

on checkFile(myfile)
	tell application "Finder" to if (exists (myfile as string) as POSIX file) then
		return true
	else
		return false
	end if
end checkFile
