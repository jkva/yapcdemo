#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Data::Dump;

use app;
my $app = app->to_app;

use Plack::Builder;

builder {
    enable "Plack::Middleware::Static",
        pass_through => 1,
        path => sub {
            warn $_;
            if (m!^/mvc\-current/(.*)$!) {
                $_ = "/todomvc_current/examples/vanillajs/$1"
            } elsif (m!^/mvc\-base/(.*)$!) {
                $_ = "/todomvc_base/examples/vanillajs/$1"
            }
            $_;
        }, 
        root => '/home/job/projects/presentation/';
    $app;
};
