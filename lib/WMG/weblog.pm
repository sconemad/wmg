package WMG::weblog;

=head1 NAME

WMG::weblog - wmg weblog module

=head1 SYNOPSIS

  $blog = WMG::weblog->new($artpath);
  $blog->add();

  $blog->output($site,$filter);

=head1 DESCRIPTION

Stores WMG articles in a chronological format

=head1 COPYRIGHT

Coyright 2002-2006 Andrew Wedgbury. All Rights Reserved

=head1 AUTHOR

Andrew Wedgbury <lt>wedge@sconemad.com<gt>

=cut

use strict;
use vars qw($VERSION);

$VERSION = '1.0';

#------------------------------------------------------------------------------
# Constructor
sub new {
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self = {};

  # Weblog path
  $self->{name} = shift;

  # Sub articles
  $self->{SUBS} = [];

  bless($self,$class);
  return $self;
}

#------------------------------------------------------------------------------
# Add articles to weblog
sub add
{
  my $self = shift;
  my ($pattern)=@_;
  $pattern=".*" if (!defined $pattern);
  my $dir = $self->{name};
  my $arts = $self->{SUBS};
  my $src_root = 'src'.$dir;

  opendir(DIR,$src_root);
  foreach my $file(readdir(DIR)) {
    if ($file !~ (/^\./) && -d "$src_root/$file" && 
        $file =~ /$pattern/) {
      my $art = WMG::article->new("$dir/$file");
      $art->xml_mode(1);
      $art->parse_file("$src_root/$file/article.xml");
      push(@{$arts},$art);
      print STDOUT ".";
    }
  }
  closedir(DIR);
  $self->sort();
}

#------------------------------------------------------------------------------
# Return weblog containing articles for specified month
sub month
{
  my $self = shift;
  my ($pattern) = @_;
  my $arts = $self->{SUBS};
  my $w = WMG::weblog->new($self->{name});
  foreach my $art(@$arts) {
    if ($art->{name} =~ /\/$pattern/) {
      push(@{$w->{SUBS}},$art);
    }
  }
  return $w;
}

#------------------------------------------------------------------------------
# Return weblog containing latest n articles
sub latest
{
  my $self = shift;
  my ($num) = @_;
  my $arts = $self->{SUBS};
  my $w = WMG::weblog->new($self->{name});
  my $i=0;
  foreach my $art(@$arts) {
    last if (++$i>$num);
    push(@{$w->{SUBS}},$art);
  }
  return $w;
}

#------------------------------------------------------------------------------
# Return weblog containing articles selected using predicate
sub select
{
  my $self = shift;
  my ($func) = @_;
  my $arts = $self->{SUBS};
  my $w = WMG::weblog->new($self->{name});
  foreach my $art(@$arts) {
    if (&{$func}($art) == 1) {
      push(@{$w->{SUBS}},$art);
    }
  }
  return $w;
}

#------------------------------------------------------------------------------
# Clear weblog
sub clear
{
  my $self = shift;
  $self->{SUBS}=[];
}

#------------------------------------------------------------------------------
# Sort weblog articles by date
sub sort
{
  my $self = shift;
  my $arts = $self->{SUBS};

  @{$arts} = sort {$b->{date} <=> $a->{date}} @{$arts};  
}

#------------------------------------------------------------------------------
# Output weblog articles
sub output
{
  my $self = shift;
  my ($site,$filter) = @_;

  if ($site->{BLOG_ARCHIVE}) {
    $self->output_months($site,$filter);
  }

  my $i=0;
  foreach my $art (@{$self->{SUBS}}) {
    ++$i;
    if ($filter =~ /^\d{1,3}$/) {
      next if ($i != $filter);
    } else {
      next if ($art->{name} !~ /$filter/);
    }
    $art->output($site,$filter);
  }

}

#------------------------------------------------------------------------------
# Output month pages
sub output_months
{
  my $self = shift;
  my ($site,$filter) = @_;

  my %arch=();
  foreach my $art (@{$self->{SUBS}}) {
    next if (!$art->pub());
    my $c = $art->mcode();
    if (!defined $arch{$c}) {
      $arch{$c}=0;
    }
    ++$arch{$c};
  }
  $site->{ARCH} = \%arch;
  my @arts=();
  foreach my $m (sort {$b<=>$a} keys(%arch)) {
    next if ($m !~ /$filter/);
    my $art = WMG::article->new($self->{name}."/$m");
    $m =~ /(\d{4})(\d{2})/;
    my ($year,$month) = ($1,$2);
    my $month_str = $WMG::calender::mths[$month-1];
    $art->{title} = "$month_str $year";
    $art->{BLOG} = $self->month($m);
    push(@arts,$art);
  }
  foreach my $art (@arts) {
    $art->output($site,$filter);
  }

}

#------------------------------------------------------------------------------
# Print article index
sub print_index
{
  # Do nothing for weblogs
}

1;

