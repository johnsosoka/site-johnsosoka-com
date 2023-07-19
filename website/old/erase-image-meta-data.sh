#!/bin/bash

# NOTE: Requires imagemagic 
# TODO set up for different image types.

find . -iname "*.jp*g" -exec mogrify -strip {} \;
