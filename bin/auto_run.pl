#!/usr/bin/env perl
use Modern::Perl;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Bbs::Advertising::CLIS;
use Data::Dumper;
# VERSION
# PODNAME: bbs-auto
# ABSTRACT: automatically run bbs-script

my $runner = Bbs::Advertising::CLIS->new_with_cmd;
1;
