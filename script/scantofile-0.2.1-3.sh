#!/bin/bash
# Make the script print a lot of stuff
# Maybe also comment scanadf line to eliminate scanning during debugging...
debug=0

###############
## Global scan control
## Modes:
##   file : Convert scan results to single page PDFs
##   image: Convert scan results to single JPGs
##   email: Convert scan results to double page PDF (2 scans becomes one PDF)
##   ocr  : Convert scan results to single PDF.
##          If use_ocr=1 also use OCR and dump individual pages and a file containing
##          all scanned files incl. text.
###############
set +o noclobber
#
#   $1 = scanner device
#   $2 = friendly name
#
#device=$1
#echo $device
device='brother3:net1;dev0'

###
## Global parameters
###
# Where to put the files:
BASE='/MY_PATH_TO/scans'
TMP=$BASE/temp
mkdir -p "$TMP"
FILE=$(date +"%Y%m%d_%H%M%S")

#400dpi:
#output_tmp=$BASE/20110725_144734
#600dpi:
#output_tmp=$BASE/20110724_234142

###
## Default parameters which can be changed depending on mode
###
# DPI setup: 100|150|200|300|400|600|1200|2400|4800|9600dpi
default_resolution=300
# Color or something else: Black & White|Gray[Error Diffusion]|True Gray|24bit Color
mode="24bit Color"
# Scan area:
x=210
y=291

###
## Setup script depending on how we were called
#From: http://stackoverflow.com/questions/192319/in-the-bash-script-how-do-i-know-the-script-file-name
if [ "${0##*/}" == "scantofile.sh" ]; then
    if [ "$debug" == 1 ]; then
	echo "FILE MODE"
    fi
    # Set flag to control things further on
    kind="file"
    # Color or something else?
#    mode="Black & White"
#    mode="Gray"
#    mode="True Gray"
    resolution=300
elif [ "${0##*/}" == "scantoimage.sh" ]; then
    if [ "$debug" == 1 ]; then
	echo "IMAGE MODE"
    fi
    # Set flag to control things further on
    kind="image"
    resolution=$default_resolution
elif [ "${0##*/}" == "scantoocr.sh" ]; then
    if [ "$debug" == 1 ]; then
	echo "OCR MODE"
    fi
    # Set flag to control things further on
    kind="ocr"
    mode="Black & White"
    # cuneiscan does not like images over 300dpi->buffer overflow
    # Scan at 600, rotate and scale down
    resolution=$default_resolution 
elif [ "${0##*/}" == "scantoemail.sh" ]; then
    if [ "$debug" == 1 ]; then
	echo "OCR MODE - Alternate Folder"
    fi
    # Set flag to control things further on
    kind="ocr"
    mode="Black & White"
    resolution=$default_resolution 
    BASE=$BASE/MY_ALTERNATE_FOLDER
else
    echo "Script was called with wrong name! ${0}"
    echo "Use: scanto{file|image|ocr|email}_IS.sh"
    exit
fi

if [ "$debug" == 1 ]; then
    echo "scan from $2($device) to $TMP/$FILE.pnm"
fi
# Adf will automatically figure out if it is ADF or flatbed
scanadf --device-name "$device" --resolution $resolution -x $x -y $y --mode "$mode" -o"$TMP"/$FILE\_%02d.pnm
# This one takes only a single scan.
#scanimage -B1M --device-name "$device" --resolution $resolution --mode "$mode" > "$TMP"/$FILE.pnm

# Run the post processing as seperate process.
#Debugging: /usr/local/Brother/sane/script/postprocess.sh  $kind "$BASE" "$TMP" 20130403_222759 &
/opt/brother/scanner/brscan-skey/script/postprocess.sh  $kind "$BASE" "$TMP" $FILE &
