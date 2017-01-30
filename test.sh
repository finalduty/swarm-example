#!/bin/bash

EXITCODE=0

[ `egrep -i 'hello' app/example.txt &>/dev/null; echo $?` -eq 0 ] || EXITCODE=1
[ `egrep 'FROM' app/Dockerfile &>/dev/null; echo $?` -eq 0 ] || EXITCODE=1

exit $EXITCODE
