The scantofile-...sh file must be linked to 4 different names:

scantofile.sh
scantoocr.sh
scantoimage.sh
scantoemail.sh

These are the names used in the brscan-skey.cfg file in turn.
From the calling name, the script is able to determine what to do.

postprocessing happensin another process, allowing scans to continue without waiting for that.
