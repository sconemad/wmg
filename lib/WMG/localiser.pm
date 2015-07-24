package WMG::localiser;

=head1 NAME

WMG::localiser - Relative link localiser

=head1 SYNOPSIS

  my $loc = WMG::localiser->new("/something.html");
  $art->parse_file("html/something.html");

=head1 DESCRIPTION

Replaces (href|src)="/path/file" links within file with relative path to file 
(using "./", "../", "../../", etc).

=head1 COPYRIGHT

Coyright 2002-2005 Andrew Wedgbury. All Rights Reserved

=head1 AUTHOR

Andrew Wedgbury <lt>wedge@sconemad.com<gt>

=cut

use strict;
use HTML::Parser;
use vars qw($VERSION @ISA);

$VERSION = '1.0';
@ISA=qw(HTML::Parser);

#------------------------------------------------------------------------------
# Constructor
sub new {
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self = $class->SUPER::new();

  my $name = shift;
  my @dm = $name =~ /\//g;
  my $depth = (scalar @dm);

  print STDOUT "$name ($depth)\n";

  if ($depth <= 1) {
    $self->{PRE} = ".";
  } else {
    $self->{PRE} = ".." . ("/.." x ($depth-2));
  }
  
  bless($self,$class);
  return $self;
}

#------------------------------------------------------------------------------
# (PARSER) start tag
sub start
{
  my $self = shift;
  my $pre = $self->{PRE};
  my ($tag,$args,undef,$orig)=@_;

  $orig =~ s/href=(\"|\')\//href=$1$pre\//g;
  $orig =~ s/src=(\"|\')\//src=$1$pre\//g;
  print "$orig";
  $self->SUPER::start(@_);
}  

#------------------------------------------------------------------------------
# (PARSER) end tag
sub end
{
  my $self = shift;
  my ($tag,$orig)=@_;
  print $orig;
  $self->SUPER::end(@_);
}

#------------------------------------------------------------------------------
# (PARSER) text
sub text
{
  my $self = shift;
  my ($text)=@_;
  print $text;
}

#------------------------------------------------------------------------------
# (PARSER) declaration tag
sub declaration 
{
  my $self = shift;
  my ($text)=@_;
  print "<!$text>";
}

#------------------------------------------------------------------------------
# (PARSER) process tag
sub process
{
  my $self = shift;
  my ($text)=@_;
  print $text;
}

1;
