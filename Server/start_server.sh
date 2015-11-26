#!/bin/sh
# requires Dancer2 version 0.163+
plackup -R conf -Ilib -e'use PONAPI::Server; PONAPI::Server->to_app'
