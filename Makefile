.ONESHELL:
SHELL = /bin/bash

server:
	hugo server -s website

build:
	hugo --minify -s website
