use strict;
use warnings;
use ParseUtil::Build;

my $builder = ParseUtil::Build->new(
    module_name => 'ParseUtil::Domain',
    license     => 'perl',
    dist_author => 'William Travis Holton <cromulent2000_eisley@yahoo.de>',
    dist_version_from    => 'lib/ParseUtil/Domain.pm',
    recursive_test_files => 1,
    build_requires       => {

        #        'LWP::UserAgent'               => 0,
        'Regexp::Assemble::Compressed' => 0,

    },
    requires => {
        'Test::More'         => 0,
        'Test::Class'        => 0,
        'Test::Deep'         => 0,
        'Perl::Critic'       => 0,
        'version'            => 0.77,
        'Test::Perl::Critic' => 0,
        'Smart::Comments'    => 0,
        'YAML'               => 0,
        'Net::IDN::Encode'   => 0,
        'Net::IDN::Punycode' => 0,
        'Perl6::Export::Attrs' => 0,

    },
    add_to_cleanup => ['ParseUtil-*'],
    tld_data_files =>
      { 'data/effective_tld_names.txt' => 'data/effective_tld_names.txt' }
);

$builder->add_build_element('tld_data');
$builder->create_build_script();

