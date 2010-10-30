package ParseUtil::Domain;

use base qw(ParentClass);

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless {}, $class;
    $self;
}

"one, but we're not the same";

__END__


=head1 NAME

ParseUtil::Domain - Utility for parsing domain name into its constituent
components.

=head1 SYNOPSIS

  use ParseUtil::Domain;

  # synopsis...

=head1 DESCRIPTION

# longer description...


=head1 INTERFACE


=head1 DEPENDENCIES


=head1 SEE ALSO


