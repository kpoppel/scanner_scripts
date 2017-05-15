#!/bin/bash
# Post process the scanned result and let the scanner be able to scan again while
# the result is processed
#
# This postpocess is based on scanning at 300dpi

kind=$1
BASE=$2
TMP=$3
FILE=$4
log=/MY_PATH_TO/scans/scanlog/log.txt
debug=0

echo "---------------------------------------------" >> $log
echo "Scan kind: "$kind >> $log
echo "Base     : "$BASE >> $log
echo "Tmp      : "$TMP  >> $log
echo "File     : "$FILE >> $log

# Output file type (image scanning)
imgtype=jpg
# Use OCD engine?
use_ocr=1

# Crop images? Good for A5 type scans. Less good for anything else.
use_crop=0

# save and change IFS
OLDIFS=$IFS
IFS=$'\n'
# read all file name into an array
fileArray=($(find $TMP/$FILE*.pnm -type f))
# get length of an array
tLen=${#fileArray[@]}

# use for loop read all filenames
for (( i=0; i<${tLen}; i++ ));
do
    # Cuts file postfix: <>.* away (%%.*)
    pnmfile=${fileArray[$i]}
    basename=${fileArray[$i]%%.*}
    if [ "$kind" == "file" ]; then
	echo "FILE: Converting PNM to single file PDF: $basename.pdf" >> $log
	# Deskew
        # If the filename is specified as output it becomes much larger than if using pipe?
        convert "$pnmfile" -deskew 40% - > "$basename".rotated.pnm
        # Convert to PostScript, then to PDF
	pnmtops "$basename".rotated.pnm | ps2pdf - "$basename".pdf
	mv "$basename".pdf $BASE/
    elif [ "$kind" == "image" ]; then
	echo "IMAGE: Convert PNM to JPG q:85: $basename.jpg" >> $log
	pnmtojpeg --progressive --quality=85 --smooth 10 "$pnmfile" > "$basename".jpg
	mv "$basename".jpg $BASE/
    elif [ "$kind" == "email" ]; then
	# I use email mode to scan double sided documents instead.
	echo "EMAIL: Convert PNM to dual sided PDF: $basename.pdf" >> $log
	# Deskew
        # If the filename is specified as output it becomes much larger than if using pipe?
        convert "$pnmfile" -deskew 40% - | pnmtops - > "$basename".ps
	if [ -e "$TMP/doublesided.ps" ]; then
	    echo "Second page scanned" >> $log
 	    psmerge -o"$basename".comb.ps "$TMP/doublesided.ps" "$basename".ps
	    ps2pdf "$basename".comb.ps "$basename".pdf
	    rm "$TMP/doublesided.ps"
	    mv "$basename".pdf $BASE/
	else 
	    if [ "$debug" == "1" ]; then
		echo "EMAIL: First page scanned" >> $log
	    fi
	    mv "$basename".ps "$TMP/doublesided.ps"
	fi
    elif [ "$kind" == "ocr" ]; then
	echo "OCR: Converting many PNM to PDF: $basename.pdf" >> $log
	if [ "$use_ocr" == "1" ]; then
	    echo "Using OCR engine" >> $log
            # Deskew
            # If the filename is specified as output it becomes much larger than if using pipe?
            convert "$pnmfile" -deskew 40% - > "$basename".scaled.pnm
#	    if [ -e "$basename".rotated.pnm ]; then
#		echo "Scale Image to 100% - reduces file size" >> $log
#		convert -scale 100% "$basename".rotated.pnm "$basename".scaled.pnm
#	    fi
            ## Cuneiform 300dpi setup: ###
	    if [ -e "$basename".scaled.pnm ]; then
		echo "Perform OCR" >> $log
		cuneiform -l dan -f hocr -o "$basename".hocr "$basename".scaled.pnm
	    fi
	    rc=$?
	    if [[ $rc == 0 ]]; then
		echo "Embed OCR in PDF" >> $log
		hocr2pdf  -r 300 -i "$basename".scaled.pnm -s -o "$basename".pdf < "$basename".hocr
	    else
		echo "OCR failed. Converting image to PDF without OCR embedded." >> $log
	        ## Save not OCRed files as PDF also (in case OCR failed)
	        #convert "$basename".rotated.pnm "$basename".pdf # <-- Creates rather large files
		# Convert to PDF
                pnmtops "$basename".scaled.pnm > "$basename".tmp.ps
		ps2pdf "$basename".tmp.ps "$basename".pdf
                #pnmtops "$basename".scaled.pnm | ps2pdf - "$basename".pdf
	    fi
	    ### end ###
	else
	    echo "Not using OCR engine. Just convert to PDF" >> $log
            pnmtops "$basename".scaled.pnm > "$basename".tmp.ps
            ps2pdf "$basename".tmp.ps "$basename".pdf
	    #pnmtops "$pnmfile" | ps2pdf - "$basename".pdf
	fi
	echo "Moving "$basename".pdf to "$BASE >> $log
	mv "$basename".pdf     $BASE/
    fi
done

## Finish up multipage scan by merging it all into a single PDF
if [ "$kind" == "ocr" ]; then
    if [ "$use_ocr" == "1" ]; then
	echo "Finish embedding text in PDF" >> $log
	pdftk $(ls "$BASE/$FILE"_??.pdf) cat output "$BASE/$FILE"_all.pdf
    else
	echo "Merge PS into one big file" >> $log
	psmerge -o"$TMP/$FILE"_all.ps  $(ls "$TMP/$FILE"*.ps)
	echo "Convert PS to PDF" >> $log
	ps2pdf "$TMP/$FILE"_all.ps "$BASE/$FILE"_all.pdf
    fi
fi

###
## Delete temporary files
###
#fileArray=($(find $TMP/$FILE* -type f))
fileArray=($(find $TMP/$FILE*))
tLen=${#fileArray[@]}
#debug=1
for (( i=0; i<${tLen}; i++ ));
do
    if [ "$debug" == "1" ]; then
	echo "Not deleting file: ${fileArray[$i]}" >> $log
    else
	echo "Deleting file: ${fileArray[$i]}" >> $log
	rm -rf "${fileArray[$i]}"
    fi
done

# restore it
IFS=$OLDIFS

## TESSERACT:
##############
## Get tesseract from SVN (gz 3.0.0 file outputs wrong hocr html)
## Site: http://code.google.com/p/tesseract-ocr/source/checkout
##  svn checkout http://tesseract-ocr.googlecode.com/svn/trunk/ tesseract-ocr-read-only
## Follow this guide to compile and install:
##  http://ubuntuforums.org/showthread.php?t=1647350
## Generally speaking:
##  ./runautoconf; ./configure; make -j2; sudo checkinstall; sudo ldconfig
## Get training data fromgoogle code also.
##
## CUNEIFORM:
##############
##
##
##
##
##
##
