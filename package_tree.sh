#!/bin/bash

NAME=spotifyd

python3 package_tree.py $NAME > package_tree.dot
dot package_tree.dot -Tpng -opackage_tree.png

if which loupe &>/dev/null ; then
	loupe package_tree.png
else
	eog package_tree.png
fi

