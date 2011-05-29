#!/bin/bash
for f in $(ls -1 . | grep -v install.sh);
  cp $f ~/.$f
done 
