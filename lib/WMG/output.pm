package WMG::output;

=head1 NAME

WMG::output - wmg output module

=head1 SYNOPSIS

  my $art = WMG::article->new();
  ...
  my $out = WMG::output->new();

  $out->run($art,"default.tpl","html/output.html");

=head1 DESCRIPTION

Parses and executes the template using the specified article as input,
and writes the output to specified file.

=head1 COPYRIGHT

Coyright 2002-2005 Andrew Wedgbury. All Rights Reserved

=head1 AUTHOR

Andrew Wedgbury <lt>wedge@sconemad.com<gt>

=cut

#use strict;
use HTML::Parser;
use WMG::article;
use vars qw($TPLBASE $VERSION @ISA);

$VERSION = '1.0';
@ISA=qw(HTML::Parser);

#------------------------------------------------------------------------------
# Constructor
sub new {
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self = $class->SUPER::new();
  bless($self,$class);
  return $self;
}

#------------------------------------------------------------------------------
# Run the template parser and produce the output
sub run
{
  my $self = shift;
  my ($src,$tpl,$out)=@_;

  print STDOUT $src->{name};
  print STDOUT " - \"".$src->{title}."\"" if defined $src->{title};
  print STDOUT "\n";

  $self->xml_mode(1);
  $self->{SRC}=$src;

  if ($out =~ /^(.*)\/[^\/]+$/) {
    mkdir($1);
  }
  my $outfile = IO::File->new(">$out");
  binmode($outfile);
  my $stdout = select($outfile);

  $self->parse_file(locate_tpl_file($tpl));
  
  select($stdout);
  $outfile->close();
}

#------------------------------------------------------------------------------
# (PARSER) start tag
sub start
{
  my $self = shift;
  my ($tag,$args,undef,$orig)=@_;
  print $orig;
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
  my $src = $self->{SRC};

  if ($text =~ /^WMG(.*)$/s) {
    my $code=$1;
    eval $code;

  } else {
    print "<?$text?>";
  }
}

#------------------------------------------------------------------------------
sub wmg_tpl
{
  my $self = shift;
  my ($tpl) = @_;
  $self->wmg_file(locate_tpl_file($tpl));
}

#------------------------------------------------------------------------------
sub wmg_file
{
  my $self = shift;
  my ($file)=@_;
  my $p = WMG::output->new;
  $p->{SRC}=$self->{SRC};
  $p->xml_mode(1);
  $p->parse_file($file);
}

#------------------------------------------------------------------------------
sub wmg_str
{
  my $self = shift;
  my ($str)=@_;
  return if !defined $str;
  my $p = WMG::output->new;
  $p->{SRC}=$self->{SRC};
  $p->xml_mode(1);
  $p->parse($str);
  $p->eof;
}

#------------------------------------------------------------------------------
sub locate_tpl_file
{
  my ($tpl) = @_;
  # Find template to use
  $tpl = $tpl || "default";
  my $tpl_file = "tpl/$tpl.wmg";
  if (! -f $tpl_file) {
    $tpl_file = "$TPLBASE/tpl/$tpl.wmg";
  }
  die "Unknown template '$tpl'" if (! -f $tpl_file);
  return $tpl_file;
}

#------------------------------------------------------------------------------
sub nav_link
{
  my ($this,$link,$name,$help)=@_;
  if ($this eq $link) {
    print "<span>$name</span>";
  } elsif (defined $help) {
    print "<a href='$link' title='$help'>$name</a>";
  } else {
    print "<a href='$link'>$name</a>";
  }
}

#------------------------------------------------------------------------------
sub tag
{
  my ($tag,$content) = @_;
  return "<$tag>$content</$tag>\n";
}

1;
