package WMG::gallery;

=head1 NAME

WMG::gallery - wmg image gallery

=head1 SYNOPSIS

  my $gallery = WMG::gallery->new();
  $gallery->scan("image/dir","*.");
  $gallery->write_table();

=head1 DESCRIPTION

Allows galleries of images to be loaded and output

=head1 COPYRIGHT

Coyright 2002-2006 Andrew Wedgbury. All Rights Reserved

=head1 AUTHOR

Andrew Wedgbury <lt>wedge@sconemad.com<gt>

=cut

use strict;
use vars qw($VERSION);

$VERSION = '1.0';

#------------------------------------------------------------------------------
sub new {
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self = {};
  
  $self->{IMGS} = [];
  $self->{THUMB} = "110x110";
  $self->{COLS} = 5;

  bless($self,$class);
  return $self;
}

#------------------------------------------------------------------------------
sub add
{
  my $self = shift;
  my ($path,$size,$text) = @_;
  $size = $self->{SIZE} if (!defined $size);
  $text = $self->{TEXT} if (!defined $text);

  my $imgs = $self->{IMGS};
  my $img = WMG::image->new($path,$size,$text);
  push(@{$imgs},$img);
}

#------------------------------------------------------------------------------
sub scan
{
  my $self = shift;
  my $dir = shift;
  my $pattern = shift || ".*";
  $dir =~ s/^\///;
  $dir =~ s/\/\.$//;

  opendir(DIR,"src/$dir");
  my @files = readdir(DIR);
  closedir(DIR);

  foreach my $file(@files) {
    if ($file =~ /$pattern\.(jpg|jpeg|gif|png)$/i) {
      $self->add("$dir/$file");
    }
  }

}

#------------------------------------------------------------------------------
sub write_table {
  my $self = shift;
  my ($cols) = @_;
  $cols = $self->{COLS} if (!$cols);
  my $imgs = $self->{IMGS};
  my $thumb = $self->{THUMB};

  my $i=0;
  print "<table class='gallery' border='0'>\n";
  while ($i < @{$imgs}) {
    print "<tr>\n";
    for (my $x=0; $x<$cols; ++$x, ++$i) {
      if ($i < @{$imgs}) {
        my $img = $imgs->[$i];
        my $desc = $img->desc();
        print "<td>".
          $img->html($thumb).
          ($desc ? "<p>$desc</p>" : "").
          "</td>\n";
      } else {
        #print "<td> </td>\n";
      }
    }
    print "</tr>\n";
  }
  print "</table>\n";
}

#------------------------------------------------------------------------------
sub write {
  my $self = shift;
  my $imgs = $self->{IMGS};
  my $thumb = $self->{THUMB};

  foreach my $img(@$imgs) {
    print $img->html($thumb)."\n";
  }
}

1;
