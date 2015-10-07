#!/bin/sh
# installed Dancer2 must be with latest parameters features
# I run it with PERL5LIB=../Dancer2/lib
plackup -r -Ilib -Ilib/PONAPI/Server/routes/ -e'use PONAPI; PONAPI->to_app'
