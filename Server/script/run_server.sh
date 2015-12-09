#!/bin/sh
plackup \
  -R conf \
  -MPlack::Middleware::MethodOverride \
  -Ilib \
  -e 'use PONAPI::Server;
      my $comp = PONAPI::Server->new();
      my $app  = $comp->to_app;
      Plack::Middleware::MethodOverride->wrap( $app );'
