use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'ParseUtil::Domain',
    license     => 'perl',

    dist_author => 'William Travis Holton <cromulent2000_eisley@yahoo.de>',
    dist_version_from    => 'lib/ParseUtil/Domain.pm',
    recursive_test_files => 1,
    requires             => {
        'Test::More'         => 0,
        'Test::Class'        => 0,
        'Test::Deep'         => 0,
        'Perl::Critic'       => 0,
        'Test::Perl::Critic' => 0,
        'Smart::Comments'    => 0,
        'YAML'               => 0,

    },
    add_to_cleanup => ['ParseUtil-*'],
);

$builder->create_build_script();
