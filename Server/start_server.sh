#!/bin/sh
# requires Dancer2 version 0.163+
plackup -r -Ilib -Ilib/PONAPI/Server/Dancer2/routes/ -e'use PONAPI; PONAPI->to_app'
