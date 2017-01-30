#!/bin/bash

EXITCODE=0

[ `egrep -i 'hello' app/example.txt` ] || EXITCODE=1
[ `egrep 'FROM' app/Dockerfile` ] || EXITCODE=1

exit $EXITCODE
