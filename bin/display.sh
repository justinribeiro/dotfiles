#!/bin/bash

case $1 in
    standby|suspend|off)
        xset dpms force $1
        ;;
    *)
        echo "Usage: $0 standby|suspend|off"
        ;;
  esac
