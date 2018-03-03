#!/bin/bash

## Comic Downloader ##

GlobalConfig=$"Generic_Comic_Downloader.conf"
. $GlobalConfig
New=0

if [ ! -e "comiclist.txt" ] ; then
	echo "There is no comiclist.txt!"
	echo "This is a space deliminated file with the URL (Of the first page),"
	echo " and the name of the comic (no spaces)."
	echo "I literally cannot continue."
	exit 1
fi
if [ ! -e "$GlobalConfig" ] ; then
	echo "There is no Generic_Comic_Downloader.conf!"
	echo "This a nessesary config file for the operation of this script."
	echo "I literally cannot continue."
	exit 2
fi

#Start comic downloading...

while read -r ComicName; do

	localSave=$MainDir/$ComicName/DoNotDeleteMe.txt
	LocalConfig=$MainDir/$ComicName/DoNotDeleteMe.conf
	tmpFile=$TmpDir/$ComicName/index.tmp

	# Check and initialize temp directory and temp file if missing.
	if [ ! -d "$TmpDir/$ComicName" ] ; then
		echo "Temp Directory for $ComicName not found! Creating..."
		sleep 2
		mkdir -p $TmpDir/$ComicName
		touch $tmpFile
		echo "Done creating $ComicName Temp Directory."
		sleep 2
	fi

	# Check and initialize main directory and save files if missing.
	# If main directory and/or LocalConfig save files were missing start the
	# initial comic configuration.

	if [ ! -d "$MainDir/$ComicName" ] ; then
		echo "$ComicName main directory not found! Assuming new comic. Creating..."
		echo "$ComicName main directory and save files."
		New=1
		sleep 2
		mkdir -p $MainDir/$ComicName
		touch $localSave
		touch $LocalConfig
		echo "SavedURL=\"\"" | tee --append $localSave
		echo "SavedFileNum=\"0\"" | tee --append $localSave
		echo "Done creating $ComicName directory and save files."
		sleep 2
	fi
	if [ ! -e "$localSave" ] ; then
		if [ ! -e "$LocalConfig" ] ; then
			echo "Save file for $ComicName not found! Recreating and restarting from"
			echo "scratch. Please do not delete this file as it saves bandwidth by"
			echo "remembering the last page of the webcomic downloaded."
			sleep 3
			touch $localSave
			echo "SavedURL=\"\"" | tee --append $localSave
			echo "SavedFileNum=\"0\"" | tee --append $localSave
			echo "Done recreating save file."
			New=1
			sleep 2
		else
			echo "Save file for $ComicName not found! Recreating..."
			echo "Please do not delete this file as it saves bandwidth by remembering"
			echo "the last page of the webcomic downloaded."
			sleep 3
			touch $localSave
			echo "SavedURL=\"\"" | tee --append $localSave
			echo "SavedFileNum=\"0\"" | tee --append $localSave
			echo "Done recreating save file."
			New=2
			sleep 2
		fi
	fi
	if [ ! -e "$LocalConfig" ] ; then
		if [ ! -e "$localSave" ] ; then
			echo "$ComicName config file not found! Recreating config file as new comic."
			echo "Please do not delete this config file as it tells the main program"
			echo "how to download from this particular webcomic site."
			New=1
			sleep 3
			touch $LocalConfig
			echo "Done recreating $ComicName config file."
			sleep 2
		fi
	fi

	# New comic setup

	if [[ $New = 1 ]] ; then
		clear
		echo "Welcome to the new webcomic setup."
		sleep 2
		echo "The purpose of this interactive system is to customize finding"
		echo "and downloading of the $ComicName webcomic."
		read -p "Press any key to continue... " -n1 -s </dev/tty
		clear
		echo "First, I will ask you for the URL of the first page of the"
		echo "$ComicName webcomic. I will attempt different ways to get the next"
		echo "page of the webcomic."
		echo
		echo -n "Please enter the URL of the first page of the webcomic below."
		echo
		read comicSetup </dev/tty
		echo "The name of the new comic first page URL is $comicSetup"
		read -rsp $'Press any key to continue...\n' key </dev/tty
		clear

# Find proper link extraction formula

		formulaTry=1
		while [[ $formulaTry -lt 3 ]]; do
			if [[ $formulaTry == 3 ]]; then
				echo "I unfortunatly do not have a method to extract the next link from"
				echo "this webcomic URL. I cannot continue with the setup."
				exit 3
			fi
			if [[ $formulaTry == 2 ]]; then
				wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
				links=$( grep -A 1 '<td class="comic_navi_right">' $tmpFile | awk -F'"' '{print $2}' )
				echo "Please confirm that the link below is to the next page."
				echo $linkTry
				echo "Please enter (Y)es or (N)o."
				read -p "Y-y/N-n" -n 1 -r </dev/tty
				echo
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo "FirstPage="$comicSetup"" | tee --append $LocalConfig
					echo "linkFormula=\"2\"" | tee --append $LocalConfig
					formulaTry=4
				else
					((formulaTry++))
				fi
			fi
			if [[ $formulaTry ==  1 ]]; then
				wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
				linkTry=$( grep 'class="next"' $tmpFile | awk -F\" '{print $8}' )
				echo "Please confirm that the link below is to the next page."
				echo $linkTry
				echo "Please enter (Y)es or (N)o."
				read -p "Y-y/N-n" -n 1 -r </dev/tty
				echo
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo "FirstPage="$comicSetup"" | tee --append $LocalConfig
					echo "linkFormula=\"1\"" | tee --append $LocalConfig
					formulaTry=4
				else
					((formulaTry++))
				fi
			fi
		done

# Find proper image extraction formula

	clear
	imageFormulaTry=1
	while [[ $imageFormulaTry -lt 3 ]]; do
		if [[ $imageFormulaTry == 3 ]]; then
			echo "I unfortunatly do not have a method to extract the image from"
			echo "this webcomic. I cannot continue with the setup."
			exit 4
		fi
		if [[ $imageFormulaTry ==  2 ]]; then
			wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
			imageTry=$""
			echo "Please confirm that the image opened is the image expected from the"
			echo "webcomic page."
			open $imageTry
			echo "Please enter (Y)es or (N)o."
			read -p "Y-y/N-n" -n 1 -r </dev/tty
			echo
			if [[ $REPLY =~ ^[Yy]$ ]] ; then
				echo "imageFormula=\"2\"" | tee --append $LocalConfig
				imageFormulaTry=4
			else
				((imageFormulaTry++))
			fi
		fi
		if [[ $imageFormulaTry ==  1 ]]; then
			wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
			imageTry=$( xmllint --html --xpath '//img/@src' $tmpFile 2>/dev/null | awk -F\" '{for (i=2; i<NF; i+=2) {print $i}}' )
			if [[ $comicSetup == http://rockcocks.slipshine.net* ]] ; then
				for link in $imageTry
				do
				if [[ "$link" != *Teaser* ]] ; then
					tempstring="$tempstring"" ""$link"
				fi
				done
				imageTry="$tempstring"
			fi

			imgcount=0

			maximg=$(
			( for imgURL in $imageTry ; do
				curl --max-time 60 -A "USERAGENT" -e $comicSetup -o $TmpDir/$ComicName/$imgcount $imgURL
				echo $(( $( identify -format '%W * %H\n' $TmpDir/$ComicName/$imgcount | head --lines=1 ) )) $TmpDir/$ComicName/$imgcount
				imgcount=$(( imgcount++ ))
			done
			) | sort -n -r | awk 'NR==1 {print $2}'
			)

			convert $maximg $TmpDir/$ComicName/try.jpg

			echo "Please confirm that the image opened is the image expected from the"
			echo "webcomic page."
			xdg-open $TmpDir/$ComicName/try.jpg
			echo "Please enter (Y)es or (N)o."
			read -p "Y-y/N-n" -n 1 -r </dev/tty
			echo
			if [[ $REPLY =~ ^[Yy]$ ]] ; then
				echo "imageFormula=\"1\"" | tee --append $LocalConfig
				imageFormulaTry=4
			else
				((imageFormulaTry++))
			fi
		fi
	done
	sed -i 's,SavedURL=.*,SavedURL='$comicSetup',' $localSave
	sed -i 's,SavedFileNum=.*,SavedFileNum='0',' $localSave
fi

	# Start loading comic data

	. $localSave
	. $LocalConfig

	if [[ $New = 2 ]]; then
		sed -i 's,SavedURL=.*,SavedURL='$FirstPage',' $localSave
	fi

	# If SavedFileNum is not 0 load localSave data instead of comiclist.txt data

	if [[ "$SavedFileNum" -ne 0 ]]; then
		echo "Loading save data for $ComicName"
		URL=$SavedURL
		filenum=$SavedFileNum
	else
		URL=$FirstPage
		filenum=$SavedFileNum
	fi

		while [ "$URL" != "" ] ; do

			linkcheck="$URL"
			echo "Working on page $URL"

			# If next post cannot be identified, assume at the end of comic and end program.
			# Otherwise...
			# fetch web page.

			wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $URL

			# list images based on imageFormula

			if [[ "$imageFormula" -eq 1 ]]; then
				images=$( xmllint --html --xpath '//img/@src' $tmpFile 2>/dev/null | awk -F\" '{for (i=2; i<NF; i+=2) {print $i}}' )
			fi
			if [[ "$imageFormula" -eq 2 ]]; then
				images=$""
			fi
			if [[ "$imageFormula" -eq 3 ]]; then
				images=""
			fi

			if [[ $URL == http://rockcocks.slipshine.net* ]] ; then
				for link in $images
				do
				if [[ "$link" != *Teaser* ]] ; then
					tempstring="$tempstring"" ""$link"
				fi
				done
				images="$tempstring"
			fi

			# find biggest image

			imgcount=0

			maximg=$(
			( for imgURL in $images ; do
				curl --max-time 60 -sS $imgURL > $TmpDir/$ComicName/$imgcount
				echo $(( $( identify -format '%W * %H\n' $TmpDir/$ComicName/$imgcount 2>/dev/null | head --lines=1 ) )) $TmpDir/$ComicName/$imgcount
				imgcount=$(( imgcount++ ))
			done
			) | sort -n -r | awk 'NR==1 {print $2}'
			)

			# Parse HTML for post name
			if [[ "$linkFormula" -eq 1 ]]; then
				postname=$( xmllint --html --xpath '//div[@id = "comicwrapinner"]//img[@title]' $tmpFile | awk -F\" '{print $2}' )
				almostaname=$( sed 's`/`-`g' <<< "$postname" )
				cleanpostname=$( sed 's/ //g' <<< "$almostaname" )
			fi
			if [[ "$linkFormula" -eq 2 ]]; then
				links=$( grep -A 1 '<div id="comic">' $tmpFile | awk -F'"' '{print $1}' )
			fi
			if [[ "$linkFormula" -eq 3 ]]; then
				links=$""
			fi

			# Identify if the image is not jpeg and transform into jpeg if different

			format=$( identify -format "%m" $maximg )
			if [ "$format" != "JPEG" ] ; then
				echo "Image is a "$format" and will be changed to JPEG."
				convert $maximg $TmpDir/$ComicName/$filenum"_"$cleanpostname.jpg
			else

				# If it turns out to be a jpeg already just rename it.

				echo "Image is a JPEG. We're cool."
				mv $maximg $TmpDir/$ComicName/$filenum"_"$cleanpostname.jpg
			fi

			# Have we downloaded this file before?

			if [ -e $MainDir/$ComicName/$filenum"_"$cleanpostname.jpg ] ; then

				# If file exists compare with downloaded image

				results=` compare -metric RMSE -dissimilarity-threshold 1 $TmpDir/$ComicName/$filenum"_"$cleanpostname.jpg $MainDir/$ComicName/$filenum"_"$cleanpostname.jpg $TmpDir/$ComicName/null.jpg: 2>&1; `

				# If they are not a match then move image into main folder

				if [ $? -gt "1" ] ; then
					echo "Image already exists but doesn't match downloaded copy. Overwriting..."
					mv $TmpDir/$ComicName/$filenum"_"$cleanpostname.jpg $MainDir/$ComicName/$filenum"_"$cleanpostname.jpg
				else
					echo "Image match exists... Moving on..."
				fi
			else
				echo "New image being written..."
				mv $TmpDir/$ComicName/$filenum"_"$cleanpostname.jpg $MainDir/$ComicName/$filenum"_"$cleanpostname.jpg
			fi

			# Parse HTML for next post link

			if [[ "$linkFormula" -eq 1 ]]; then
				links=$( xmllint --html --xpath '//div[@class = "nav"]//*[@class = "next"]' $tmpFile | awk -F\" '{print $2}' )
			fi
			if [[ "$linkFormula" -eq 2 ]]; then
				links=$( grep -A 1 '<td class="comic_navi_right">' $tmpFile | awk -F'"' '{print $2}' )
			fi
			if [[ "$linkFormula" -eq 3 ]]; then
				links=$""
			fi
			for link in $links ; do
				if [[ "$link" != *void* ]] ; then
					URL="$link"
				else
					echo "The End"
				fi
			done

			if [ "$linkcheck" != "$URL" ] ; then
				SavedURL=$URL
				sed -i 's,SavedURL=.*,SavedURL='$SavedURL',' $localSave
				((filenum++))
				sed -i 's,SavedFileNum=.*,SavedFileNum='$filenum',' $localSave
			fi
		done
	done < comiclist.txt
