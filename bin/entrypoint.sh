#!/bin/bash
set -e

# Set permissions so that new files can be deleted/overwritten outside docker
umask 000

cd ./bound

Rscript --vanilla /bound/web_tool_script_1.R "${1:-1234}" &&
	Rscript --vanilla /bound/web_tool_script_2.R "${1:-1234}" &&
	/usr/bin/shiny-server
