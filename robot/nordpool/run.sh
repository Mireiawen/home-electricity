#!/bin/bash
pushd "/home/mireiawen/robot/robot/nordpool"
rm -f "/home/mireiawen/Downloads/Day-ahead prices.xls"
robot --rpa \
	--report 'NONE' \
	--output 'NONE' \
	--log 'NONE' \
	'nordpool.robot'
popd
