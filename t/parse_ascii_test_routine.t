#!/usr/bin/perl

use strict;
use warnings;

use lib qw{ ./t/lib };

use Test::More tests => 2;
use Test::Routine::Util;

run_tests(
    'Test toggle between unicode and puny-encoded ascii',
    ['AsciiToggle','ToggleTester']
);

run_tests(
    'Test toggle between unicode and puny-encoded ascii',
    ['UnicodeToggle','ToggleTester']
);




