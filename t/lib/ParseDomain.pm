package ParseDomain;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use Test::Deep;
use Test::Exception;
use utf8;
use YAML;

use ParseUtil::Domain;

sub t010_split_ascii_domain_tld : Test(15) {    #{{{
    my $self         = shift;
    my $test_domains = [

        {
            raw    => 'something.com',
            domain => 'something',
            zone   => 'com'

        },
        {
            raw    => 'neteseco.or.at',
            domain => 'neteseco',
            zone   => 'or.at'

        },
        {
            raw    => 'something.tas.gov.au',
            domain => 'something',
            zone   => 'tas.gov.au'
        },
        { raw => 'whatever.name',    domain => 'whatever',    zone => 'name' },
        { raw => 'me.whatever.name', domain => 'me.whatever', zone => 'name' },
        { raw => 'me@whatever.name', domain => 'me@whatever', zone => 'name' },
        { raw => 'mx01.whatever.it', domain => 'mx01.whatever', zone => 'it' },

    ];

    foreach my $test_domain ( @{$test_domains} ) {
        my $parsed = parse_domain( $test_domain->{raw} );
        my ( $domain, $zone, ) = @{$parsed}{qw/domain zone /};

        is(
            $domain,
            $test_domain->{domain},
            "Expected " . $test_domain->{domain}
        );
        is( $zone, $test_domain->{zone}, "Expected " . $test_domain->{zone} );

    }

    throws_ok {
        parse_domain('nota.tld');

    }
    qr/Could not find tld/, 'Unknown tlds not processed.';

}    #}}}

sub t020_split_unicode_domain_tld : Test(18) {    #{{{
    my $self          = shift;
    my $domain_to_ace = [
        {
            raw     => 'ü.com',
            decoded => 'ü.com',
            ace     => 'xn--tda.com'

        },
        {
            raw     => 'test.香港',
            decoded => 'test.香港',
            ace     => 'test.xn--j6w193g'

        },
        {
            raw     => 'test.xn--o3cw4h',
            decoded => 'test.ไทย',
            ace     => 'test.xn--o3cw4h'

        },
        {
            raw     => 'ü@somewhere.name',
            decoded => 'ü@somewhere.name',
            ace     => 'xn--tda@somewhere.name'

        },
        {
            raw     => 'ü.or.at',
            decoded => 'ü.or.at',
            ace     => 'xn--tda.or.at'

        },
        {
            decoded => 'bloß.de',
            ace     => 'xn--blo-7ka.de',
            raw     => 'xn--blo-7ka.de'

        },
        {
            raw     => 'faß.co.at',
            decoded => 'fass.co.at',
            ace     => 'fass.co.at'

        },
        {
            raw     => 'faß.de',
            decoded => 'faß.de',
            ace     => 'xn--fa-hia.de'

        },
        {
            decoded => 'faß.de',
            ace     => 'xn--fa-hia.de',
            raw     => 'xn--fa-hia.de'

        },

    ];

    foreach my $test_domain ( @{$domain_to_ace} ) {
        my $parsed = parse_domain( $test_domain->{raw} );
        my ( $domain, $domain_ace, $zone, $zone_ace ) =
          @{$parsed}{qw/domain domain_ace zone zone_ace/};

        my $decoded_domain = join "." => $domain,     $zone;
        my $ace_domain     = join "." => $domain_ace, $zone_ace;

        is( $test_domain->{decoded},
            $decoded_domain, "Expected " . $test_domain->{decoded} );
        is( $test_domain->{ace}, $ace_domain,
            "Expected " . $test_domain->{ace} );

    }
}    #}}}

1;
