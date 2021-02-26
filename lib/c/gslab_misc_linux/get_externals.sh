#!/usr/bin/env bash

SVNROOT=http://gsbhmg01.chicagogsb.edu/svn/trunk
SVNPATH=/opt/CollabNet_Subversion/bin

# directory
EXT=./external

# check for and possibly remove existing 'externals' directory
if [ -d $EXT ]; then
    rm -rf $EXT
    echo -e "\n > removed existing external directory \n"
fi 
mkdir $EXT

# export files from repository
# files for compiling
$SVNPATH/svn export -r 14586 $SVNROOT"/lib/c/gslab_misc@14586" $EXT/lib/c/gslab_misc

# files for testing
$SVNPATH/svn export -r 11075 $SVNROOT"/lib/third_party/matlab_xunit@11075" $EXT/lib/third_party/matlab_xunit/
$SVNPATH/svn export -r 12554 $SVNROOT"/lib/matlab/gslab_misc@12554" $EXT/lib/matlab/gslab_misc/