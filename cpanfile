requires 'Carp', '1.17';
requires 'Net::IDN::Encode', '2.003';
requires 'Net::IDN::Nameprep', '1.101';
requires 'Net::IDN::Punycode', '1.100';
requires 'perl5i::2', '2.12.0';
requires 'Perl6::Export::Attrs';
 
on 'build' => sub {
  requires 'namespace::autoclean';
  requires 'Net::IDN::Encode';
  requires 'Perl::Critic';
  requires 'Regexp::Assemble::Compressed';
  requires 'Smart::Comments';
  requires 'Test::Class';
  requires 'Test::Deep';
  requires 'Test::More';
  requires 'Test::Perl::Critic';
  requires 'Test::Routine';
  requires 'Unicode::CharName';
};

on 'configure' => sub { 
  requires 'Module::Build';
};
