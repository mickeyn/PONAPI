#!/bin/sh
plackup -R conf -Ilib -e'use PONAPI::Server; PONAPI::Server->to_app'
