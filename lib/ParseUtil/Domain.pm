package ParseUtil::Domain;

## no critic
our $VERSION = '2.34';
$VERSION = eval $VERSION;
## use critic

use Carp;

use autobox;
use autobox::Core;
use List::MoreUtils qw/any/;
use Perl6::Export::Attrs;
use Net::IDN::Encode ':all';
use Net::IDN::Punycode ':all';
use Net::IDN::Nameprep;
#use Smart::Comments;

use ParseUtil::Domain::ConfigData;

sub parse_domain : Export(:parse) {
    my $name = shift;
    ### testing : $name
    my @name_segments = $name->split(qr{\Q@\E});
    ### namesegments : \@name_segments

    my @segments = $name_segments[-1]->split(qr/[\.\x{FF0E}\x{3002}\x{FF61}]/);
    ### executing with : $name
    my ( $zone, $zone_ace, $domain_segments ) =
      _find_zone( \@segments )->slice(qw/zone zone_ace domain/);

    ### found zone : $zone
    ### found zone_ace : $zone_ace

    my $puny_processed = _punycode_segments( $domain_segments, $zone );
    my ( $domain_name, $name_ace ) = $puny_processed->slice(qw/name name_ace/);
    ### puny processed : $puny_processed
    ### joining name slices : $domain_name
    $puny_processed->{name} = [ $domain_name, $zone ]->join('.')
      if $domain_name;
    $puny_processed->{name_ace} = [ $name_ace, $zone_ace ]->join('.')
      if $name_ace;
    @{$puny_processed}{qw/zone zone_ace/} = ( $zone, $zone_ace );

    # process .name "email" domains
    if ( @name_segments > 1 ) {
        my $punycoded_name = _punycode_segments( [ $name_segments[0] ], $zone );
        my ( $domain, $domain_ace ) =
          $punycoded_name->slice(qw/domain domain_ace/);

        $puny_processed->{domain} =
          [ $domain, $puny_processed->{domain} ]->join('@');
        if ($domain_ace) {
            $puny_processed->{domain_ace} =
              [ $domain_ace, $puny_processed->{domain_ace} ]->join('@');

        }
    }
    return $puny_processed;

}

sub puny_convert : Export(:simple) {
    my $domain = shift;
    my @keys;
    if ( $domain =~ /\.?xn--/ ) {
        @keys = qw/domain zone/;
    }
    else {
        @keys = qw/domain_ace zone_ace/;
    }
    my $parsed        = parse_domain($domain);
    my $parsed_domain = $parsed->slice(@keys)->join(".");

    return $parsed_domain;
}

sub _find_zone {
    my $domain_segments = shift;

    my $tld_regex = ParseUtil::Domain::ConfigData->config('tld_regex');
    ### Domain Segments: $domain_segments
    my $tld  = $domain_segments->pop;
    my $sld  = $domain_segments->pop;
    my $thld = $domain_segments->pop;

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

    # first checking for third level domain
    if ( $possible_thld and $possible_thld =~ /\A$tld_regex\z/ ) {
        ### $possible_thld: $possible_thld
        my $zone_ace = join "." => $thld_zone_ace, $sld_zone_ace, $tld_zone_ace;
        $zone = join "." => $thld, $sld, $tld;
        push @zone_params, zone_ace => $zone_ace;
    }
    elsif ( $possible_tld =~ /\A$tld_regex\z/ ) {
        ### possible_tld: $possible_tld
        push @{$domain_segments}, $thld;
        my $zone_ace = join "." => $sld_zone_ace, $tld_zone_ace;
        $zone = join "." => $sld, $tld;
        push @zone_params, zone_ace => $zone_ace;
    }
    elsif ( $tld_zone_ace =~ /\A$tld_regex\z/ ) {
        ### tld_zone_ace: $tld_zone_ace
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

sub _punycode_segments {
    my ( $domain_segments, $zone ) = @_;

    my @name_prefix;
    if ( not $zone or $zone !~ /^(?:de|fr|pm|re|tf|wf|yt)$/ ) {
        my $puny_encoded = [];
        foreach my $segment ( @{$domain_segments} ) {
            croak "Error processing domain."
              . " Please report to package maintainer."
              if not defined $segment
              or $segment eq '';
            my $nameprepped = nameprep( lc $segment );
            my $ascii       = domain_to_ascii($nameprepped);
            push @{$puny_encoded}, $ascii;
        }
        my $puny_decoded =
          [ map { domain_to_unicode($_) } @{$puny_encoded} ];
        croak "Undefined mapping!"
          if any { lc $_ ne nameprep( lc $_ ) } @{$puny_decoded};

        my $domain     = $puny_decoded->join(".");
        my $domain_ace = $puny_encoded->join(".");

        my $processed_name     = _process_name_part($puny_decoded);
        my $processed_name_ace = _process_name_part($puny_encoded);
        @{$processed_name_ace}{qw/name_ace prefix_ace/} =
          delete @{$processed_name_ace}{qw/name prefix/};

        return {
            domain     => $domain,
            domain_ace => $domain_ace,
            %{$processed_name},
            %{$processed_name_ace}
        };
    }

    # Avoid nameprep step for certain tlds
    my $puny_encoded =
      [ map { _puny_encode( lc $_ ) } @{$domain_segments} ];
    my $puny_decoded       = [ map { _puny_decode($_) } @{$puny_encoded} ];
    my $domain             = $puny_decoded->join(".");
    my $domain_ace         = $puny_encoded->join(".");
    my $processed_name     = _process_name_part($puny_decoded);
    my $processed_name_ace = _process_name_part($puny_encoded);
    @{$processed_name_ace}{qw/name_ace prefix_ace/} =
      delete @{$processed_name_ace}{qw/name prefix/};
    return {
        domain     => $domain,
        domain_ace => $domain_ace,
        %{$processed_name},
        %{$processed_name_ace}
    };

}

sub _process_name_part {
    my $processed = shift;
    my @name_prefix;
    my $name   = $processed->pop;
    my $prefix = $processed->join(".");
    push @name_prefix, name   => $name   if $name;
    push @name_prefix, prefix => $prefix if $prefix;
    return {@name_prefix};
}

sub _puny_encode {
    my $unencoded = shift;

    ### encoding : $unencoded
    # quick check to make sure that domain should be decoded
    my $temp_unencoded = nameprep $unencoded;
    ### namepreped : $temp_unencoded
    my $test_encode = domain_to_ascii($temp_unencoded);
    return $unencoded if $test_encode eq $unencoded;
    return "xn--" . encode_punycode($unencoded);
}

sub _puny_decode {
    my $encoded = shift;
    return $encoded
      unless $encoded =~ /xn--/;
    $encoded =~ s/^xn--//;
    ### decoding : $encoded
    my $test_decode = decode_punycode($encoded);
    ### test decode : $test_decode
    return $encoded if $encoded eq $test_decode;
    return decode_punycode($encoded);

}

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
the I<tld> may actually refer to a second- or third-level domain, e.g. co.uk or
plc.co.im.  It also provides respective puny encoded and decoded versions of
the parsed domain.

This module uses TLD data from the L<Public Suffix List|http://publicsuffix.org/list/> which is included with this
distribution.


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

  5. parse_domain('www.whatever.com');

   Result:
    {
        domain     => 'www.whatever',
        zone       => 'com',
        domain_ace => 'www.whatever',
        zone_ace   => 'com',
        name       => 'whatever',
        name_ace   => 'whatever',
        prefix     => 'www',
        prefix_ace => 'www'
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
The L<Public Suffix List|http://publicsuffix.org/list/>.


=back


=head1 CHANGES


=over 3

=item *
Go back to C<sub> style subroutines instead of C<func>. The L<perl5i> style functions seem to cause the debugger to die horribly.

=item *
Added extra I<prefix> and I<name> fields to output to separate the actual registered part of the domain from subdomains (or things like I<www>).

=item *
Updated with latest version of the public suffix list.

=item *
Added a bunch of new TLDs (nTLDs).



=back
