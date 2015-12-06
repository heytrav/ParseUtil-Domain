#!/usr/bin/env perl

use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;
use Mock::Quick;
use ParseUtil::Domain ':parse';
use namespace::autoclean;

test 'cannot find tld' => sub {
    my ($self) = @_;
    my $control = qtakeover  'ParseUtil::Domain::ConfigData';
    $control->override(tld_regex => sub { return qr/\.notlds/; });
    throws_ok {
        parse_domain('somedomain.com'); 
    } qr/Could\snot\sfind\stld/, 'Croaks when tld not available.';
};

test 'can find tld' => sub {
    my ($self) = @_;
    my $control = qtakeover  'ParseUtil::Domain::ConfigData';
    $control->override(tld_regex => sub { return qr/test/; });
    lives_ok {
        parse_domain('somedomain.test'); 
    } 'Finds tld.';
};

run_me;
done_testing;
