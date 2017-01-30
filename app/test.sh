#!/bin/bash

EXITCODE=0

[ `egrep -i 'hello' example.txt` ] || EXITCODE=1
[ `egrep 'FROM' Dockerfile ] || EXITCODE=1
