#!/bin/sh
# installed Dancer2 must be with latest parameters features
# I run it with PERL5LIB=../Dancer2/lib
plackup -Ilib -Ilib/PONAPI/Server/routes/ -MPONAPI -e'PONAPI->to_app'
