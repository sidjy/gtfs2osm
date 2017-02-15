#!/bin/bash

source ../config.sh

./get.sh 2>&1 >result.log
./create_and_fill.sh 2>&1 >>result.log
