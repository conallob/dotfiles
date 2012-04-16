#!/usr/bin/env bash

for f in bashrc bash_alias bashenv; do
	echo ln -s ${PWD}/${f} ~/.${f}
done
