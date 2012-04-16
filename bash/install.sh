#!/usr/bin/env bash

for f in bashrc bash_alias bashenv; do
	ln -s ${PWD}/${f} ~/.${f}
done
