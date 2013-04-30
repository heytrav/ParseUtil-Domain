package ParseUtil::Domain;

## no critic
our $VERSION = '2.26_001';
$VERSION = eval $VERSION;
## use critic

use perl5i::2;

use Perl6::Export::Attrs;
use ParseUtil::Domain::ConfigData;
use Net::IDN::Encode ':all';
use Net::IDN::Punycode ':all';
use Net::IDN::Nameprep;

#use Smart::Comments;
#use YAML;

sub parse_domain : Export(:parse) {
    my $name = shift;
    $name =~ s/\s//gs;
    open my $utf8h, "<:encoding(utf8)", \$name;
    my $utf8_name = do { local $/; <$utf8h>; };
    $utf8h->close;
    my @name_segments = $utf8_name->split(qr{\Q@\E});
    ### namesegments : Dump(\@name_segments)

    my @segments = $name_segments[-1]->split(qr/[\.\x{FF0E}\x{3002}\x{FF61}]/);
    ### executing with : $name
    my ( $zone, $zone_ace, $domain_segments ) =
      _find_zone( \@segments )->slice(qw/zone zone_ace domain/);

    ### found zone : $zone
    ### found zone_ace : $zone_ace

    my $puny_processed = _punycode_segments( $domain_segments, $zone );
    @{$puny_processed}{qw/zone zone_ace/} = ( $zone, $zone_ace );

    # process .name "email" domains
    if ( @name_segments > 1 ) {
        my $punycoded_name = _punycode_segments( [ $name_segments[0] ], $zone );
        my ( $name_domain, $name_ace ) =
          $punycoded_name->slice(qw/domain domain_ace/);

        $puny_processed->{domain} =
          [ $name_domain, $puny_processed->{domain} ]->join('@');
        if ($name_ace) {
            $puny_processed->{domain_ace} =
              [ $name_ace, $puny_processed->{domain_ace} ]->join('@');

        }
    }
    return $puny_processed;

}

sub puny_convert : Export(:simple) {
    my $domain = shift;
    my @keys;
    given ($domain) {
        when (/\.?xn--/) {
            @keys = qw/domain zone/;
        }
        default {
            @keys = qw/domain_ace zone_ace/;
        }
    }
    my $parsed        = parse_domain($domain);
    my $parsed_domain = $parsed->slice(@keys)->join(".");

    return $parsed_domain;
}

func _find_zone($domain_segments) {

    my $tld_regex = ParseUtil::Domain::ConfigData->config('tld_regex');
      my $tld     = @{$domain_segments}->pop;
      my $sld     = @{$domain_segments}->pop;
      my $thld    = @{$domain_segments}->pop;

      my ( $possible_tld, $possible_thld );
      my ( $sld_zone_ace, $tld_zone_ace ) =
      map { domain_to_ascii( nameprep $_) } $sld, $tld;
      my $thld_zone_ace;
      $thld_zone_ace = domain_to_ascii( nameprep $thld) if $thld;
      if ( $tld =~ /^de$/ ) {
        ### is a de domain
        $possible_tld = join "." => $tld, _puny_encode($sld);
    }
    else {
        $possible_tld = join "." => $tld_zone_ace, $sld_zone_ace;
        $possible_thld = join "." => $possible_tld,
          $thld_zone_ace
          if $thld_zone_ace;
    }
    my ( $zone, @zone_params );

      if ( $possible_thld and $possible_thld =~ /\A$tld_regex\z/ ) {
        my $zone_ace = join "." => $thld_zone_ace, $sld_zone_ace, $tld_zone_ace;
        $zone = join "." => $thld, $sld, $tld;
        push @zone_params, zone_ace => $zone_ace;
    }
    elsif ( $possible_tld =~ /\A$tld_regex\z/ ) {
        push @{$domain_segments}, $thld;
        my $zone_ace = join "." => $sld_zone_ace, $tld_zone_ace;
        $zone = join "." => $sld, $tld;
        push @zone_params, zone_ace => $zone_ace;
    }
    elsif ( $tld_zone_ace =~ /\A$tld_regex\z/ ) {
        push @{$domain_segments}, $thld if $thld;
        push @{$domain_segments}, $sld;
        push @zone_params, zone_ace => $tld_zone_ace;
        $zone = $tld;
    }
    croak "Could not find tld." unless $zone;
      my $unicode_zone = domain_to_unicode($zone);
      return {
        zone   => $unicode_zone,
        domain => $domain_segments,
        @zone_params
      };
  }

  func _punycode_segments( $domain_segments, $zone ) {

    if ( not $zone or $zone !~ /^(?:de|fr|pm|re|tf|wf|yt)$/ ) {
        my $puny_encoded = [];
        foreach my $segment ( @{$domain_segments} ) {
            croak
              "Error processing domain. Please report to package maintainer."
              if not $segment
              or $segment eq '';
            my $nameprepped = nameprep( lc $segment );
            my $ascii       = domain_to_ascii($nameprepped);
            push @{$puny_encoded}, $ascii;
        }
        my $puny_decoded = [ map { domain_to_unicode($_) } @{$puny_encoded} ];
        croak "Undefined mapping!"
          if $puny_decoded->any( sub { lc $_ ne nameprep( lc $_ ) } );
        return {
            domain     => $puny_decoded->join("."),
            domain_ace => $puny_encoded->join(".")
        };
    }

    # Have to avoid the nameprep step for .de domains now that DENIC has
    # decided to allow the German "sharp S".
    my $puny_encoded   = [ map { _puny_encode( lc $_ ) } @{$domain_segments} ];
      my $puny_decoded = [ map { _puny_decode($_) } @{$puny_encoded} ];
      return {
        domain     => $puny_decoded->join("."),
        domain_ace => $puny_encoded->join(".")
      };

  }

  func _puny_encode($unencoded) {

    ### encoding : $unencoded
    # quick check to make sure that domain should be decoded
    my $temp_unencoded = nameprep $unencoded;
      ### namepreped : $temp_unencoded
      my $test_encode = domain_to_ascii($temp_unencoded);
      return $unencoded if $test_encode eq $unencoded;
      return "xn--" . encode_punycode($unencoded);
  }

  func _puny_decode($encoded) {
    return $encoded
      unless $encoded =~ /xn--/;
      $encoded =~ s/^xn--//;
      ### decoding : $encoded
      my $test_decode = decode_punycode($encoded);
      ### test decode : $test_decode
      return $encoded if $encoded eq $test_decode;
      return decode_punycode($encoded);

  }

  "one, but we're not the same";

__END__


=head1 NAME

=encoding utf8

ParseUtil::Domain - Domain parser and puny encoder/decoder.

=head1 SYNOPSIS

  use ParseUtil::Domain ':parse';

    my $processed = parse_domain("somedomain.com");
    #$processed:
    #{
        #domain => 'somedomain',
        #domain_ace => 'somedomain',
        #zone => 'com',
        #zone_ace => 'com'
    #}


=head1 DESCRIPTION


This purpose of this module is to parse a domain name into its respective name and tld. Note that
the I<tld> may actually refer to a second or third level domain (i.e. co.uk or
plc.co.im).  It also provides respective puny encoded and decoded versions of
the parsed domain.

This module makes use of the data provided by the I<Public Suffix List>
(L<http://publicsuffix.org/list/>) to parse tlds.



=head1 INTERFACE


=head2 parse_domain


=over 2

=item
parse_domain(string)


=over 3

=item
Examples:


   1. parse_domain('somedomain.com');

    Result:
    {
        domain     => 'somedomain',
        zone       => 'com',
        domain_ace => 'somedomain',
        zone_ace   => 'com'
    }

  2. parse_domain('test.xn--o3cw4h');

    Result:
    {
        domain     => 'test',
        zone       => 'ไทย',
        domain_ace => 'test',
        zone_ace   => 'xn--o3cw4h'
    }

  3. parse_domain('bloß.co.at');

    Result:
    {
        domain     => 'bloss',
        zone       => 'co.at',
        domain_ace => 'bloss',
        zone_ace   => 'co.at'
    }

  4. parse_domain('bloß.de');

    Result:
    {
        domain     => 'bloß',
        zone       => 'de',
        domain_ace => 'xn--blo-7ka',
        zone_ace   => 'de'
    }

=back



=back

=head2 puny_convert

Toggles a domain between puny encoded and decoded versions.


   use ParseUtil::Domain ':simple';

   my $result = puny_convert('bloß.de');
   # $result: xn--blo-7ka.de

   my $reverse = puny_convert('xn--blo-7ka.de');
   # $reverse: bloß.de






=head1 DEPENDENCIES

=over 3


=item
L<Net::IDN::Encode>


=item
L<Net::IDN::Punycode>


=item
L<Regexp::Assemble::Compressed>


=item
The Public Suffix List at L<http://publicsuffix.org/list/>.


=back


=head1 CHANGES


=over 3


=item *
Updated public suffix list.

=item *
Added a bunch of new TLDs (nTLDs).



=back
