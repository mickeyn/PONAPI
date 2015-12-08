#!/bin/sh
plackup \
  -R conf \
  -MPlack::Middleware::MethodOverride \
  -Ilib \
  -e 'use PONAPI::Server; my $app = PONAPI::Server->to_app; Plack::Middleware::MethodOverride->wrap($app);'
