#!/bin/sh
# installed Dancer2 must be with latest parameters features
# I run it with PERL5LIB=../Dancer2/lib
plackup -Ilib -Ilib/Server/routes/ -MAPI::PONAPI -e'API::PONAPI->to_app'
