#!/usr/bin/env bash

for f in bashrc bash_alias bashenv bash_profile; do
	ln -s ${PWD}/${f} ~/.${f}
done
