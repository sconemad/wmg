package WMG::image;

=head1 NAME

WMG::image - wmg image

=head1 SYNOPSIS

  # Load the image and scale to 800x800 and adding text
  my $img = WMG::image->new("image.jpg","800x800","Text to appear on image");

  # Print html image tag using a 120x120 thumbnail
  print $img->html("120x120");

=head1 DESCRIPTION

Allows images to be scaled, annotated and thumbnailed.

=head1 COPYRIGHT

Coyright 2002-2006 Andrew Wedgbury. All Rights Reserved

=head1 AUTHOR

Andrew Wedgbury <lt>wedge@sconemad.com<gt>

=cut

use strict;
use File::Copy;
use Image::Magick;
use vars qw($VERSION);

$VERSION = '1.0';

my $im_path = "/usr/local/bin";
$im_path = "/usr/bin" if (! -e "$im_path/identify");

#------------------------------------------------------------------------------
sub new {
  my $proto=shift || "";
  my $class=ref($proto) || $proto;
  my $self = {};
  
  my $file = shift || "";
  $self->{FILE} = $file;
  $self->{SIZE} = shift;
  $self->{TEXT} = shift;

  if ($file =~ /^(.*)\.[^\.]+/) {
    my $descfile = "src/$1.txt";
    if (-f $descfile) {
      my $desc = "";
      open(DESC,$descfile);
      while (<DESC>) { $desc .= $_; }
      close(DESC);
      $self->{DESC}=$desc;
    }
  }

  bless($self,$class);
  return $self;
}

#------------------------------------------------------------------------------
sub write
{
  my $self = shift;
  print $self->html(@_);
}

#------------------------------------------------------------------------------
sub desc
{
  my $self = shift;
  return $self->{DESC};
}

#------------------------------------------------------------------------------
sub html
{
  my $self = shift;
  my $ts = shift;
  my $path = $self->{FILE};
  my $cs = $self->{SIZE};
  my $text = $self->{TEXT};

  my $file = $path;
  my $dir = "";
  if ($path =~ /^(.*)\/([^\/]+)$/) {
      ($dir,$file)=($1,$2);
  }

  my $image_src = "src/$dir/$file";
  my $image = "html/$dir/$file";
  my $image_href = ($dir?"/$dir/":"/") . $file;

  print STDOUT " IMG ($image_href ";

  if ((! -e $image_src) && (! -e $image)) {
    # Source and output images don't exist
    print STDOUT "DOES NOT EXIST)\n";
    return "";
  }

  my $im_image = 0;
  my ($w,$h);

  if (-e $image_src) {
    if ((! -e $image) || (-M $image > -M $image_src)) {
      # Output image doesn't exist or is out of date
      mkdir("html/$dir");
      
      $im_image = Image::Magick->new;
      my $err = $im_image->Read($image_src);
      print STDOUT "$err" if "$err";
      $w = $im_image->Get('width');
      $h = $im_image->Get('height');

      if (defined $cs) {
        $cs =~ /(\d+)x(\d+)/;
        my ($cw,$ch) = ($1,$2);
        if ($w > $cw || $h > $ch) {
          print STDOUT "SCALING ${w}x${h} -> ";
          $im_image->Scale(geometry=>$cs);
        }
      }

      # Annotate the image
      my $font = 'helvetica';
      if ($self->{DESC}) {
        $im_image->Annotate(font=>$font, pointsize=>18, fill=>'white',
                            gravity=>'NorthWest', x=>0, y=>0,
                            text=>' '.($self->{DESC}).' ', undercolor=>'#000000c0');
      }
      if ($text) {
        $im_image->Annotate(font=>$font, pointsize=>12, fill=>'white',
                            gravity=>'SouthWest', x=>0, y=>0,
                            text=>' '.$text.' ', undercolor=>'#000000c0');
      }
      
      # Write out image to output location
      $im_image->Write(filename=>$image);
    }
  }
  
  if (!$im_image) {
    $im_image = Image::Magick->new;
    my $err = $im_image->Read($image);
    print STDOUT "$err" if "$err";
  }

  $w = $im_image->Get('width');
  $h = $im_image->Get('height');
  my $alt = "[${w}x${h}]";
  print STDOUT "${w}x${h}) ";

#  `identify $image` =~ /^.* ([^ ]+) (\d+)x(\d+)/;
#  my ($w,$h) = ($2,$3);
#  my $alt = "[$2x$3 $1]";

  if (defined $ts) {

    $ts =~ /(\d+)x(\d+)/;
    my ($tw,$th) = ($1,$2);
    my $str="";

    if ($w > $tw || $h > $th) {
      # Thumbnail required

      my $thumb = "html/$dir/$ts/$file";
      my $thumb_href = "/$dir/$ts/$file";
      mkdir("html/$dir/$ts");

      if (! -f $thumb || -M $thumb > -M $image) {
        print STDOUT "(THUMB generating ";
#        system("convert -size $ts $image -resize $ts +profile '*' $thumb");
        $im_image->Scale(geometry=>$ts);
#        $im_image->Quantize(colorspace=>'gray');
        $im_image->Write(filename=>$thumb);

      } else {
        print STDOUT "(THUMB exists ";
        $im_image = Image::Magick->new;
        my $err = $im_image->Read($thumb);
        warn "$err" if "$err";
      }

#      `identify $thumb` =~ /^.* ([^ ]+) (\d+)x(\d+)/;
#      return "<a href='$image_href'><img src='$thumb_href' alt='$alt' width='$2' height='$3' /></a>";

      $tw = $im_image->Get('width');
      $th = $im_image->Get('height');

      print STDOUT "${tw}x${th})\n";
      return "<a href='$image_href'>".
        "<img src='$thumb_href' alt='$alt' width='$tw' height='$th' /></a>";
    }
  }

  # Thumbnail not required
  print STDOUT "\n";
  return "<img src='$image_href' alt='$alt' width='$w' height='$h' />";

}

1;
