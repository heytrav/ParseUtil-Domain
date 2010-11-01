package ParseDomain;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use Test::Deep;
use Test::Exception;
use utf8;

use ParseUtil::Domain;

sub t010_split_ascii_domain_tld : Test(6) {    #{{{
    my $self = shift;

    my @ascii_domains = qw/
      something.com
      netseco.or.at
      whatever.name
      me.whatever.name
      me@whatever.name
      mx01.whatevertest.it
      /;

    foreach my $domain (@ascii_domains) {
        my $parsed = parse_domain($domain);
        is(
            $parsed,
            superhashof(
                {
                    tld    => ignore(),
                    domain => ignore()
                }
            ),
            "Expected datastructure."
        );

    }
}    #}}}

sub t020_split_unicode_domain_tld : Test(6) {    #{{{
    my $self          = shift;
    my $domain_to_ace = [
        {
            domain  => 'u¨.com',
            decoded => 'ü.com',
            ace     => 'xn--tda.com'

        },
        {
            domain  => 'ü.com',
            decoded => 'ü.com',
            ace     => 'xn--tda.com'

        },
        {
            domain  => 'ü.or.at',
            decoded => 'ü.or.at',
            ace     => 'xn--tda.or.at'

        },
        {
            domain  => 'bloß.de',
            decoded => 'bloß.de',
            ace     => 'xn--blo-7ka.de'

        },
        {
            domain  => 'faß.co.at',
            decoded => 'fass.co.at',
            ace     => 'fass.co.at'

        },
        {
            domain  => 'faß.de',
            decoded => 'faß.de',
            ace     => 'xn--fa-hia.de'

        },
        {
            domain  => 'faß.de',
            decoded => 'faß.de',
            ace     => 'xn--fa-hia.de'

        },

    ];

    my @ascii_domains = qw/

      /;
    foreach my $domain (@ascii_domains) {
        my $parsed = parse_domain($domain);
        is(
            $parsed,
            superhashof(
                {
                    tld    => ignore(),
                    domain => ignore()
                }
            ),
            "Expected datastructure."
        );

    }
}    #}}}

1;
