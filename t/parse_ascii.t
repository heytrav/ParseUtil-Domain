#!/usr/bin/perl

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = '.*split_ascii_domain_tld';

use ParseDomain;
ParseDomain->runtests();

