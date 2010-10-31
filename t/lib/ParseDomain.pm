package ParseDomain;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use Test::Deep;
use Test::Exception;

use ParseUtil::Domain ':all';

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
      is($parsed, superhashof(
              { 
                  tld => ignore(), 
                  domain => ignore()
              }
          ), "Expected datastructure." );

   }
}    #}}}

1;
