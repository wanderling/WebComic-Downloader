#!/bin/bash

short_date=$(/bin/date +%m%d%y)
exec {BASH_XTRACEFD}>"$short_date".log
set -x

## Comic Downloader ##

##dependancy check##
#libxml2-utils
#wget
#ImageMagick
#curl
#bash (duh)

GlobalConfig=$"Generic_Comic_Downloader.conf"
. $GlobalConfig
New=0

if [ ! -e "comiclist.txt" ] ; then
	echo "There is no comiclist.txt!"
	echo "This is a space deliminated file with the name of the comic (No_Spaces)."
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

	if [[ $ComicName == "" ]]; then
		echo "I have finished all of the items in comiclist.txt!"
		sleep 3
		exit 0
	fi

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
		echo "SavedFileNum=\"000\"" | tee --append $localSave
		echo "Done creating $ComicName directory and save files."
		sleep 2
	fi
	if [ ! -e "$localSave" ] ; then
		if [ ! -e "$LocalConfig" ] ; then
			echo "Save and config files for $ComicName not found! Recreating and"
			echo "restarting from scratch. Please do not delete this file as it"
			echo "saves bandwidth by remembering the last page of the webcomic downloaded."
			sleep 3
			touch $localSave
			touch $LocalConfig
			echo "SavedURL=\"\"" | tee --append $localSave
			echo "SavedFileNum=\"000\"" | tee --append $localSave
			echo "Done recreating save and config files."
			New=1
			sleep 2
		else
			echo "Save file for $ComicName not found! Recreating..."
			echo "Please do not delete this file as it saves bandwidth by remembering"
			echo "the last page of the webcomic downloaded."
			sleep 3
			touch $localSave
			echo "SavedURL=\"\"" | tee --append $localSave
			echo "SavedFileNum=\"000\"" | tee --append $localSave
			echo "Done recreating save file."
			New=2
			sleep 2
		fi
	fi
	if [ ! -e "$LocalConfig" ] ; then
		echo "$ComicName config file not found! Recreating config file as new comic."
		echo "Please do not delete this config file as it tells the main program"
		echo "how to download from this particular webcomic site."
		New=1
		sleep 3
		touch $LocalConfig
		echo "Done recreating $ComicName config file."
		sleep 2
	fi

	# New comic setup

	if [[ $New = 1 ]] ; then
		New=0
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
		while [[ $formulaTry -lt 100 ]] ; do
			if [[ $formulaTry == 8 ]] ; then
				echo -e "I unfortunatly do not have a method to extract the next link from\nthis webcomic URL. I cannot continue with the setup."
				rm -r $MainDir/$ComicName
				sleep 3
				exit 3
			fi
			# This formula works with
			if [[ $formulaTry == 7 ]] ; then
				wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
				linkTry=$( xmllint --html --xpath '//figure[@class = "photo-hires-item"]//img[@src]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
				if [[ $linkTry == "" ]] ; then
					# If $linkTry is blank, Assume "no"
					REPLY=n
				else
				echo "Please confirm that the link below is to the next page."
				echo $linkTry
				echo "Please enter (Y)es or (N)o."
				read -p "Y-y/N-n" -n 1 -r </dev/tty
				echo
				fi
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo "FirstPage="$comicSetup"" | tee --append $LocalConfig
					echo "linkFormula=\"7\"" | tee --append $LocalConfig
					formulaTry=100
				else
					((formulaTry++))
				fi
			fi

			# This formula works with Love Genie
			if [[ $formulaTry == 6 ]] ; then
				wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
				linkTry=$( xmllint --html --xpath '//a[@href][contains(text(),"Next")]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
				if [[ $linkTry == "" ]] ; then
					# If $linkTry is blank, Assume "no"
					REPLY=n
				else
				echo "Please confirm that the link below is to the next page."
				echo $linkTry
				echo "Please enter (Y)es or (N)o."
				read -p "Y-y/N-n" -n 1 -r </dev/tty
				echo
				fi
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo "FirstPage="$comicSetup"" | tee --append $LocalConfig
					echo "linkFormula=\"6\"" | tee --append $LocalConfig
					formulaTry=100
				else
					((formulaTry++))
				fi
			fi

			# This formula works with Fey Winds
			if [[ $formulaTry == 5 ]] ; then
				wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
				linkTry=$( xmllint --html --xpath '//aside[@id = "webcomiclink-11"]//a[@class]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
				if [[ $linkTry == "" ]] ; then
					# If $linkTry is blank, Assume "no"
					REPLY=n
				else
				echo "Please confirm that the link below is to the next page."
				echo $linkTry
				echo "Please enter (Y)es or (N)o."
				read -p "Y-y/N-n" -n 1 -r </dev/tty
				echo
				fi
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo "FirstPage="$comicSetup"" | tee --append $LocalConfig
					echo "linkFormula=\"5\"" | tee --append $LocalConfig
					formulaTry=100
				else
					((formulaTry++))
				fi
			fi

			# This formula works with Dangerously Chloe
			if [[ $formulaTry == 4 ]] ; then
				wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
				linkTry=$( xmllint --html --xpath '//div[@class]//a[@class = "next"]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
				if [[ $linkTry == "" ]] ; then
					# If $linkTry is blank, Assume "no"
					REPLY=n
				else
				echo "Please confirm that the link below is to the next page."
				echo $linkTry
				echo "Please enter (Y)es or (N)o."
				read -p "Y-y/N-n" -n 1 -r </dev/tty
				echo
				fi
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo "FirstPage="$comicSetup"" | tee --append $LocalConfig
					echo "linkFormula=\"4\"" | tee --append $LocalConfig
					formulaTry=100
				else
					((formulaTry++))
				fi
			fi
			# This formula works with Delve, Alfie, Cats N Cameras, Zoe The Vampire,
			if [[ $formulaTry == 3 ]] ; then
				wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
				linkTry=$( xmllint --html --xpath '//td[@class = "comic-nav"]//a[@class = "comic-nav-base comic-nav-next"]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
				if [[ $linkTry == "" ]] ; then
					# If $linkTry is blank, Assume "no"
					REPLY=n
				else
				echo "Please confirm that the link below is to the next page."
				echo $linkTry
				echo "Please enter (Y)es or (N)o."
				read -p "Y-y/N-n" -n 1 -r </dev/tty
				echo
				fi
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo "FirstPage="$comicSetup"" | tee --append $LocalConfig
					echo "linkFormula=\"3\"" | tee --append $LocalConfig
					formulaTry=100
				else
					((formulaTry++))
				fi
			fi
			# This formula works with The Cummoner
			if [[ $formulaTry == 2 ]] ; then
				wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
				linkTry=$( xmllint --html --xpath '//td[@class = "comic_navi_right"]//a[@class]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
				if [[ $linkTry == "" ]] ; then
					# If $linkTry is blank, Assume "no"
					REPLY=n
				else
				echo "Please confirm that the link below is to the next page."
				echo $linkTry
				echo "Please enter (Y)es or (N)o."
				read -p "Y-y/N-n" -n 1 -r </dev/tty
				echo
				fi
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo "FirstPage="$comicSetup"" | tee --append $LocalConfig
					echo "linkFormula=\"2\"" | tee --append $LocalConfig
					formulaTry=100
				else
					((formulaTry++))
				fi
			fi
			# This formula works with The Rock Cocks,
			if [[ $formulaTry ==  1 ]] ; then
				wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
				linkTry=$( grep 'class="next"' $tmpFile | awk -F\" '{print $8}' )
				if [[ $linkTry == "" ]]; then
					# If $linkTry is blank, Assume "no"
					REPLY=n
				else
				echo "Please confirm that the link below is to the next page."
				echo $linkTry
				echo "Please enter (Y)es or (N)o."
				read -p "Y-y/N-n" -n 1 -r </dev/tty
				echo
				fi
				if [[ $REPLY =~ ^[Yy]$ ]] ; then
					echo "FirstPage="$comicSetup"" | tee --append $LocalConfig
					echo "linkFormula=\"1\"" | tee --append $LocalConfig
					formulaTry=100
				else
					((formulaTry++))
				fi
			fi
		done

# Find proper image extraction formula

	clear
	imageFormulaTry=1
	while [[ $imageFormulaTry -lt 100 ]] ; do
		if [[ $imageFormulaTry == 3 ]] ; then
			echo "I unfortunatly do not have a method to extract the image from"
			echo "this webcomic. I cannot continue with the setup."
			rm -r $MainDir/$ComicName
			sleep 3
			exit 4
		fi
		if [[ $imageFormulaTry ==  2 ]] ; then
			wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
			imageTry=$( xmllint --html --xpath '//div[@id = "comic"]//img[@src]' $tmpFile 2>/dev/null | awk '-F"' '{print $2}' )
			if [[ $comicSetup == *rockcocks* ]] ; then
				for link in $images
				do
				if [[ "$link" != *Teaser* ]] ; then
					tempstring="$tempstring"" ""$link"
				fi
				done
				images="$tempstring"
				tempstring=""
			fi
			if [[ $comicSetup != *catsncameras* ]] ; then
				for link in $images
				do
					if [[ "$link" != *gif ]] ; then
						tempstring="$tempstring"" ""$link"
					fi
				done
				images="$tempstring"
				tempstring=""
			fi
			if [[ $comicSetup != *feywinds* ]]; then
				for link in $images
				do
					if [[ "$link" != *php ]] ; then
						tempstring="$tempstring"" ""$link"
					fi
				done
				images="$tempstring"
				tempstring=""
			fi

			imgcount=0

			maximg=$(
			( for imgURL in $imageTry ; do
				curl --max-time 60 -sS $imgURL > $TmpDir/$ComicName/$imgcount
				echo $(( $( identify -format '%W * %H\n' $TmpDir/$ComicName/$imgcount 2>/dev/null | head --lines=1 ) )) $TmpDir/$ComicName/$imgcount
				imgcount=$((imgcount+1))
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
				echo "imageFormula=\"2\"" | tee --append $LocalConfig
				imageFormulaTry=100
			else
				((imageFormulaTry++))
			fi
		fi
		if [[ $imageFormulaTry ==  1 ]] ; then
			wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $comicSetup
			imageTry=$( xmllint --html --xpath '//img/@src' $tmpFile 2>/dev/null | awk -F\" '{for (i=2; i<NF; i+=2) {print $i}}' )
			if [[ $comicSetup == *rockcocks* ]] ; then
				for link in $images
				do
				if [[ "$link" != *Teaser* ]] ; then
					tempstring="$tempstring"" ""$link"
				fi
				done
				images="$tempstring"
				tempstring=""
			fi
			if [[ $comicSetup != *catsncameras* ]] ; then
				for link in $images
				do
					if [[ "$link" != *gif ]] ; then
						tempstring="$tempstring"" ""$link"
					fi
				done
				images="$tempstring"
				tempstring=""
			fi
			if [[ $comicSetup != *feywinds* ]]; then
				for link in $images
				do
					if [[ "$link" != *php ]] ; then
						tempstring="$tempstring"" ""$link"
					fi
				done
				images="$tempstring"
				tempstring=""
			fi

			imgcount=0

			maximg=$(
			( for imgURL in $imageTry ; do
				curl --max-time 60 -sS $imgURL > $TmpDir/$ComicName/$imgcount
				echo $(( $( identify -format '%W * %H\n' $TmpDir/$ComicName/$imgcount 2>/dev/null | head --lines=1 ) )) $TmpDir/$ComicName/$imgcount
				imgcount=$((imgcount+1))
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
				imageFormulaTry=100
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

	if [[ $New == 2 ]]; then
		sed -i 's,SavedURL=.*,SavedURL='$FirstPage',' $localSave
	fi

	# If SavedFileNum is not 0 load localSave data instead of comiclist.txt data

	if [[ "$SavedFileNum" -ne 000 ]]; then
		echo "Loading save data for $ComicName"
		if [[ $SavedURL == "" ]]; then
			if [[ $FirstPage == "" ]]; then
				echo "Config file for $ComicName is corrupt!! Please delete the file"
				echo "\"DoNotDeleteMe.conf\"in the $ComicName folder, then re-run the downloader."
				exit 5
			else
				echo "Save file for $ComicName is corrupt!! Please delete the file"
				echo "\"DoNotDeleteMe.txt\"in the $ComicName folder, then re-run the downloader."
				exit 6
			fi
		fi
		URL=$SavedURL
		filenum=$SavedFileNum
	else
		URL=$FirstPage
		filenum=$SavedFileNum
	fi
	newComic=0

		# If URL is blank, assume at the end of comic and go to the next comic.
		while [ "$URL" != "" ] ; do
			# Otherwise ...
			linkcheck="$URL"
			echo "Working on page $URL"
			# Fetch the next page
			wget --timeout=60 --user-agent="$USERAGENT" --convert-links --quiet -O $tmpFile $URL
			if ! [ "$(grep -c -i "page not found" $tmpFile)" -eq 0 ] ; then
				echo "404 error! Page not found... Skipping."
				echo "404 error! Page not found for $ComicName..." >> Comic_Output_"$short_date".txt
			else
				if ! [ "$(file $tmpFile | grep -c "empty")" -eq 0 ]; then
					echo "Page error! Page not found... Skipping."
					echo "Page error! Page empty for $ComicName..." >> Comic_Output_"$short_date".txt
				else
					# list images based on imageFormula
					# This search formula seems to work on almost everything...
					if [[ "$imageFormula" -eq 1 ]] ; then
						images=$( xmllint --html --xpath '//img/@src' $tmpFile 2>/dev/null | awk -F\" '{for (i=2; i<NF; i+=2) {print $i}}' | cut -f1 -d "?" )
					fi
					if [[ "$imageFormula" -eq 2 ]] ; then
						images=$( xmllint --html --xpath '//div[@id = "comic"]//img[@src]' $tmpFile 2>/dev/null | awk '-F"' '{print $2}' )
					fi
					if [[ "$imageFormula" -eq 3 ]] ; then
						images=""
					fi
					# These next if statements are for any special operations to correct the images list
					if [[ $URL == *rockcocks* ]] ; then
						for link in $images
						do
							if [[ "$link" != *Teaser* ]] ; then
								tempstring="$tempstring"" ""$link"
							fi
						done
						images="$tempstring"
						tempstring=""
					fi
					if [[ "$URL" != *lovegenie* ]] ; then
						if [[ "$URL" != *catsncameras* ]] ; then
							for link in $images
							do
								if [[ "$link" != *gif ]] ; then
									tempstring="$tempstring"" ""$link"
								fi
							done
							images="$tempstring"
							tempstring=""
						fi
					fi
					for link in $images
					do
						if [[ "$link" != *php ]] ; then
							tempstring="$tempstring"" ""$link"
						fi
					done
					images="$tempstring"
					tempstring=""

					# find biggest image

					imgcount=0

					maximg=$(
					( for imgURL in $images ; do
						curl --max-time 60 -sS $imgURL > $TmpDir/$ComicName/$imgcount
						echo $(( $( identify -format '%W * %H\n' $TmpDir/$ComicName/$imgcount 2>/dev/null | head --lines=1 ) )) $TmpDir/$ComicName/$imgcount
						imgcount=$((imgcount+1))
					done
					) | sort -n -r | awk 'NR==1 {print $2}'
					)

					# Parse HTML for post name...
					#This works for The Rock Cocks,
					if [[ "$linkFormula" -eq 1 ]]; then
						postname=$( xmllint --html --xpath '//div[@id = "comicwrapinner"]//img[@title]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
						almostaname=$( sed 's`/`-`g' <<< "$postname" )
						cleanpostname=$( sed 's/ //g' <<< "$almostaname" )
					fi
					#This works for The Cummoner,
					if [[ "$linkFormula" -eq 2 ]]; then
						postname=$( xmllint --html --xpath '//h2[@class = "post-title"]' $tmpFile 2>/dev/null | awk -F\> '{print $2}' | sed 's`</h2``g' )
						almostaname=$( sed 's`/`-`g' <<< "$postname" )
						cleanpostname=$( sed 's/ //g' <<< "$almostaname" )
					fi
					#This formula works with Delve, Alfie, Cats N Cameras, Zoe The Vampire,
					if [[ "$linkFormula" -eq 3 ]]; then
						postname=$( xmllint --html --xpath '//div[@id = "comic"]//img[@title]' $tmpFile 2>/dev/null | awk -F\" '{print $6}' )
						almostaname=$( sed 's`/`-`g' <<< "$postname" )
						cleanpostname=$( sed 's/ //g' <<< "$almostaname" )
					fi
					#This works for Dangerously Chloe
					if [[ "$linkFormula" -eq 4 ]]; then
						postname=$( xmllint --html --xpath '//h3' $tmpFile 2>/dev/null | awk -F\" '{print $1}' 2>/dev/null | tr -d '<>/\n' | sed 's/h3//g' )
						cleanpostname=$( sed 's/ //g' <<< "$postname" )
					fi
					#This works for Fey Winds
					if [[ "$linkFormula" -eq 5 ]]; then
						postname=$( xmllint --html --xpath '//header[@class = "post-header"]//h1' $tmpFile 2>/dev/null | tr -d '<>/\n' | sed 's/h1//g' )
						cleanpostname=$( sed 's/ //g' <<< "$postname" )
					fi
					#This works for Love Genie
					if [[ "$linkFormula" -eq 6 ]]; then
						postname=$( xmllint --html --xpath '//h2[@class="heading"][1]' $tmpFile 2>/dev/null | awk -F\" '{print $3}' | tr -d '<>/\n' | sed 's/h2//g' )
						cleanpostname=$( sed 's/ //g' <<< "$postname" )
					fi
					if [[ "$linkFormula" -eq 7 ]]; then
						cleanpostname=""
					fi

					# Identify if the image is not JPEG and transform into JPEG if anything but a GIF
					# If the image is a GIF leave alone.

					format=$( identify -format "%m" $maximg | cut -c 1-3)
					if [ "$format" == "GIF" ] ; then
						mv $maximg $TmpDir/$ComicName/$filenum"_"$cleanpostname.gif
					else
						if [ "$format" != "JPE" ] ; then
							# Image is a "$format" and will be changed to JPEG.
							convert $maximg $TmpDir/$ComicName/$filenum"_"$cleanpostname.jpg
						else
							# If it turns out to be a jpeg already just rename it.
							# Image is a JPEG. We're cool.
							mv $maximg $TmpDir/$ComicName/$filenum"_"$cleanpostname.jpg
						fi
					fi
					# Have we downloaded this file before?
					if [ -e $MainDir/$ComicName/$filenum"_"$cleanpostname.* ] ; then
						# If file exists compare with downloaded image
						results=` compare -metric RMSE -dissimilarity-threshold 1 $TmpDir/$ComicName/$filenum"_"$cleanpostname.* $MainDir/$ComicName/$filenum"_"$cleanpostname.* $TmpDir/$ComicName/null.tmp: 2>&1; `
						# If they are not a match then move image into main folder
						if [ "$results" != "0 (0)" ] ; then
							if [[ "$format" == "GIF" ]] ; then
								echo "Image already exists but doesn't match downloaded copy. Overwriting..."
								mv $TmpDir/$ComicName/$filenum"_"$cleanpostname.gif $MainDir/$ComicName/$filenum"_"$cleanpostname.gif
							else
								echo "Image already exists but doesn't match downloaded copy. Overwriting..."
								mv $TmpDir/$ComicName/$filenum"_"$cleanpostname.jpg $MainDir/$ComicName/$filenum"_"$cleanpostname.jpg
							fi
						fi
					else
						if [[ "$format" == "GIF" ]] ; then
							echo "New image being written..."
							mv $TmpDir/$ComicName/$filenum"_"$cleanpostname.gif $MainDir/$ComicName/$filenum"_"$cleanpostname.gif
						else
							echo "New image being written..."
							mv $TmpDir/$ComicName/$filenum"_"$cleanpostname.jpg $MainDir/$ComicName/$filenum"_"$cleanpostname.jpg
						fi
					fi
					# Parse HTML for next post link
					#Rock Cocks,
					if [[ "$linkFormula" -eq 1 ]]; then
						links=$( xmllint --html --xpath '//div[@class = "nav"]//*[@class = "next"]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
					fi
					#The Cummoner,
					if [[ "$linkFormula" -eq 2 ]]; then
						links=$( xmllint --html --xpath '//td[@class = "comic_navi_right"]//a[@class]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
					fi
					#Delve, Alfie, Cats N Cameras, Zoe The Vampire,
					if [[ "$linkFormula" -eq 3 ]]; then
						links=$( xmllint --html --xpath '//td[@class = "comic-nav"]//*[@class = "comic-nav-base comic-nav-next"]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
					fi
					#Dangerously Chloe
					if [[ "$linkFormula" -eq 4 ]]; then
						links=$( xmllint --html --xpath '//div[@class]//a[@class = "next"]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
					fi
					#Fey Winds
					if [[ "$linkFormula" -eq 5 ]]; then
						links=$( xmllint --html --xpath '//aside[@id = "webcomiclink-11"]//a[@class]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
					fi
					#Love Genie
					if [[ "$linkFormula" -eq 6 ]]; then
						links=$( xmllint --html --xpath '//a[@href][contains(text(),"Next")]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
					fi
					#
					if [[ "$linkFormula" -eq 7 ]]; then
						links=$( xmllint --html --xpath '//a[@class = "next-button"][@href]' $tmpFile 2>/dev/null | awk -F\" '{print $2}' )
					fi
				fi
			fi
			if [[ "$links" == "index.tmp" ]]; then
				links=""
			fi
			if [[ "$links" != "" ]] ; then
				URL="$links"
			else
				echo "Finished processing $ComicName."
				if [[ $newComic -gt 0 ]]; then
					echo -e "\n$(tput setab 2)$ComicName has new content!$(tput sgr 0)\n"
					echo "$ComicName has new content!" >> Comic_Output_"$short_date".txt
				else
					echo -e "$(tput setaf 1)No new content for $ComicName...$(tput sgr 0)"
					echo "No new content for $ComicName..." >> Comic_Output_"$short_date".txt
				fi
			fi
			if [ "$linkcheck" != "$URL" ] ; then
				SavedURL=$URL
				sed -i 's,SavedURL=.*,SavedURL='$SavedURL',' $localSave
				filenum=$( printf %03d "$((10#$filenum + 1))" )
				echo $filenum
				((newComic++))
				sed -i 's,SavedFileNum=.*,SavedFileNum='$filenum',' $localSave
			else
				URL=""
			fi
		done
	done < comiclist.txt
	exit 10
