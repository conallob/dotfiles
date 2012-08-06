#!/usr/bin/env bash

for f in zprofile zshenv zshrc; do
	ln -s ${PWD}/${f} ~/.${f}
done
