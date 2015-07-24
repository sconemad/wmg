package WMG::article;

=head1 NAME

WMG::article - wmg article

=head1 SYNOPSIS

  my $art = WMG::article->new("/something");
  $art->xml_mode(1);
  $art->parse_file("src/something.xml");

=head1 DESCRIPTION

Stores an article, which is parsed and executed from an XML input file.

=head1 COPYRIGHT

Coyright 2002-2006 Andrew Wedgbury. All Rights Reserved

=head1 AUTHOR

Andrew Wedgbury <lt>wedge@sconemad.com<gt>

=cut

use strict;
use WMG::calender;
use HTML::Parser;
use File::Copy;
use vars qw($VERSION @ISA);

$VERSION = '1.0';
@ISA=qw(HTML::Parser);

my $article_tags = "head|description|content|side|subs|img|gallery";

#------------------------------------------------------------------------------
# Constructor
sub new {
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self = $class->SUPER::new();
  
  # Article path
  $self->{name}=shift;

  # Sub articles
  $self->{SUBS}=[];

  # Parse data
  $self->{SECTION}='';
  $self->{SEEKTAGS}= shift || $article_tags;
  $self->{STACK}=[];

  if ($self->{name} =~ /(\d{14})$/) {
    $self->{date}=$1;
  }
    
  bless($self,$class);
  return $self;
}

#------------------------------------------------------------------------------
# Return article date in format "DD MMM YYYY"
sub date_string
{
  my $self = shift;
  my ($n) = @_;
  $n = 3 if (!defined $n);
  if (defined $self->{date}) {
    if ($self->{date} =~ /(\d\d\d\d)(\d\d)(\d\d)/) {
      return "$3 ".substr($WMG::calender::mths[$2-1],0,$n)." $1";
    }
  }
  return '';
}

#------------------------------------------------------------------------------
# Return article time in format "hh:mm:ss" or "hh:mm"
sub time_string
{
  my $self = shift;
  if (defined $self->{date}) {
    if ($self->{date} =~ /(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/) {
      return "$4:$5:$6";
    } elsif ($self->{date} =~ /(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)/) {
      return "$4:$5";
    }
  }
  return '';
}

#------------------------------------------------------------------------------
# Return article day of week
sub wday_string
{
  my $self = shift;
  my ($n) = @_;
  $n = 3 if (!defined $n);
  if ($self->{date} =~ /^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)/) {
    my @t = localtime( Time::Local::timelocal(0,$5,$4,$3,$2-1,$1) );
    return substr($WMG::calender::days[$t[6]],0,$n);
  }
  return '';
}

#------------------------------------------------------------------------------
# Return article timezone "+/-HHMM"
sub timezone
{
  my $self = shift;
#  my $date = $self->date_string(3);
#  my $z = `/bin/date -d \"$date\" +%z`;
#  chomp $z;

  if ($self->{date} =~ /^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)/) {
    my $tl = Time::Local::timelocal(0,$5,$4,$3,$2-1,$1);
    my $tg = Time::Local::timegm(0,$5,$4,$3,$2-1,$1);
    return sprintf("%+05d",100*(($tg-$tl)/3600));
  }
  return "+0000";
}

#------------------------------------------------------------------------------
# Return article month code "YYYYMM"
sub mcode
{
  my $self = shift;
  if ($self->{name} =~ /(\d{6})\d{8}/) {
    return "$1";
  }
  return '197001';
}

#------------------------------------------------------------------------------
# Return article day code "YYYYMMDD"
sub dcode
{
  my $self = shift;
  if ($self->{name} =~ /(\d{8})\d{6}/) {
    return "$1";
  }
  return '19700101';
}

#------------------------------------------------------------------------------
# Return article timecode "YYYYMMDDhhmmss"
sub tcode
{
  my $self = shift;
  if ($self->{name} =~ /(\d{14})/) {
    return "$1";
  }
  return '19700101000000';
}

#------------------------------------------------------------------------------
# Return article type (defaults to 'general')
sub type
{
  my $self = shift;
  return $self->{type} || 'general';
}

#------------------------------------------------------------------------------
# Return if article publish flag set
sub pub
{
  my $self = shift;
  if ($self->{pub}) {
    return ($self->{pub} =~ /^[Yy1]/);
  }
  return 1;
}

#------------------------------------------------------------------------------
# Return article directory
sub dir
{
  my $self = shift;
  my $dir = $self->{name};
  $dir =~ s/\/[^\/]+$//;
  return $dir;
}



#------------------------------------------------------------------------------
# Locate source file
sub locate_src
{
  my $self = shift;
  my ($name) = @_;
  my $test = $name;
  my $dir = $self->dir();
  $dir =~ s/^\///;
  my $dir2 = $self->{name};
  $dir2 =~ s/^\///;

  while (1) {

    if ($dir) {
      if (-e "src/$dir/$test") {
        return "$dir/$name";
      }
    } else {
     if (-e "src/$test") {
        return "$name";
      }
    }

    if (-e "src/$dir2/$test") {
      return "$dir2/$name";
    }
    
    if (-e "src/$test") { 
      return $name; 
    }
    if (-e "html/$test") { 
      return $name; 
    }
    
    if ($test =~ /^(.*)\.html$/) {
      $test = "$1.xml";
    
    } else {
      last;
    }
  }

  return undef;
}

#------------------------------------------------------------------------------
# Output article
sub output
{
  my $self = shift;
  my ($site,$filter) = @_;
  $self->{SITE} = $site;

  my $out = WMG::output->new();
  my $tpl = $self->{tpl};
  my $file = $self->{out} ? 
    "html/".$self->{out} : 
    "html".$self->{name}.".html";

  $out->run($self,$tpl,$file);
#  print STDOUT "\n";

  my $subs = $self->{SUBS};
  foreach my $sub (@$subs) {
    $sub->output($site,$filter);
  }
}

#------------------------------------------------------------------------------
# Print article index
sub print_index
{
  my $self = shift;
  my ($this) = @_;

  my $href = $self->{name}.".html";
  my $title = $self->{short} || $self->{title};
  
  my $thisdir = $this;
  $thisdir =~ s/\/[^\/]+$//;
  my $hrefdir = $href;
  if ($hrefdir && $thisdir) {
    $hrefdir =~ s/\/index\.html$//;
  }
  $hrefdir =~ s/\/[^\/]+$//;
  
  if ($this eq $href) {
    print "<li class='index-this'>$title</li>\n";
      
#  } elsif ($hrefdir !~ /$thisdir/ &&
#           $thisdir !~ /$hrefdir/) {
#    print "<li class='index-hide'><a href='$href'>$title</a></li>\n";
      
  } else {  
    print "<li><a href='$href'>$title</a></li>\n";
  }

  my $subs = $self->{SUBS};
  if (@$subs) {
    print "<ul>\n";
    foreach my $sub (@$subs) {
      next if (defined $sub->{out});
      next if (!$sub->pub());
      $sub->print_index($this);
    }
    print "</ul>\n";
  }

}

#------------------------------------------------------------------------------
sub read_file
{
  my $self = shift;
  my ($file) = @_;
  my $path = $self->locate_src($file);
  print "<pre class='file'>";
  print "<div class='head'>--- $file ---</div>";
  print "<div class='body'>";
  open(FILE,"src/$path");
  while (<FILE>) { 
    s/\&/\&amp;/g;
    s/\</\&lt;/g;
    s/\>/\&gt;/g;
    print; 
  }
  close(FILE);
  print "</div></pre>\n";
}

#------------------------------------------------------------------------------
# (PARSER) start tag
sub start
{
  my $self = shift;
  my ($tag,$args,undef,$orig)=@_;
  my $stack = $self->{STACK};

  if ($tag eq "article") {
    foreach my $arg(keys %$args) {
      $self->{$arg} = $args->{$arg};
    }
  } elsif ($tag =~ /^($self->{SEEKTAGS})$/) {
    my $ptag = $self->{SECTION};
    push(@$stack,$ptag);
    $self->{SECTION}=$tag;

    if ($tag eq "gallery") {
      $self->{$ptag} .= "<?WMG\nmy \$g = WMG::gallery->new();\n";
      if (defined $args->{size}) {
        $self->{$ptag} .= "\$g->{SIZE} = \"".$args->{size}."\";\n";
      }
      if (defined $args->{thumb}) {
        $self->{$ptag} .= "\$g->{THUMB} = \"".$args->{thumb}."\";\n";
      }
      if (defined $args->{cols}) {
        $self->{$ptag} .= "\$g->{COLS} = \"".$args->{cols}."\";\n";
      }
      if (defined $args->{text}) {
        $self->{$ptag} .= "\$g->{TEXT} = \"".$args->{text}."\";\n";
      }
      my $scan = $args->{scan};
      if (defined $scan) {
        my $dir;
        if ($scan =~ /^\//) {
          $dir = $scan;
        } else {
          $dir = $self->{name} .'/'. $scan;
        }
        my $pattern = $args->{pattern} || ".*";
        $self->{$ptag} .= "\$g->scan('$dir','$pattern');\n";
      }
            
    } elsif ($tag eq "img") {
      # IMAGE TAG
      my $src = $self->locate_src($args->{src});
      if (!$src) {
        print STDERR "ERROR: Image '".$args->{src}."' not found.\n";
        $self->{$ptag} .= " X ";
      } elsif ($ptag eq "gallery") {
        $self->{content} .= "\$g->add('$src');\n";
      } else {
        my $thumb = $args->{thumb} ? '"'.$args->{thumb}.'"' : "";
        my $size = $args->{size} ? '"'.$args->{size}.'"' : "undef";
        my $text = $args->{text} ? '"'.$args->{text}.'"' : "undef";
        my $code = "my \$img = WMG::image->new('$src',$size,$text);\n" .
                   "\$img->write($thumb);";
        $self->{$ptag} .= "<?WMG $code ?>\n";
      }
    }

  } elsif ($self->{SECTION} ne "") {

    # Handle links
    my $link = $args->{href};
    if (defined $link) {
      if ($link =~ /^http:\/\//) {
        my $title = $args->{title} || $link;
        push(@{$self->{LINKS}},"<a href='$link'>$title</a><br />\n");
      } else {
        my $src = $self->locate_src($link);
        if ($src) {

          if ($src !~ /\.(htm|html)$/) {
            # Append file size
            my $size = -s "src/$src";
            if ($size > 1e6) {
              $size = sprintf("%.1fMB",$size/1048576);
            } elsif ($size > 1e3) {
              $size = sprintf("%.1fKB",$size/1024);
            } else {
              $size = sprintf("%dB",$size);
            }
            $self->{APPEND} = " [$size]";
          }

          $orig =~ s/$link/\/$src/g;
          if (!-e "html/$src") {
            if ($src =~ /^(.*)\/[^\/]+$/) {
              my $dir = $1;
	      if (! -e "html/$dir") {
		mkdir("html/$dir") 
	      }
            }
	    copy("src/$src","html/$src");
            print STDOUT "#";
          }
        } else {
#          print STDERR "ERROR: Link '$link' not resolved.\n";
        }
      }
    }

    $self->{ $self->{SECTION} } .= $orig;
  }

  $self->SUPER::start(@_);
}  

#------------------------------------------------------------------------------
# (PARSER) end tag
sub end
{
  my $self = shift;
  my ($tag,$orig)=@_;
  my $sec = $self->{SECTION};
  my $stack = $self->{STACK};

  if ($tag =~ /^($self->{SEEKTAGS})$/) {
    if ($self->{$sec}) {
      $self->{$sec} =~ s/^(\r\n|\r|\n)+//;
      $self->{$sec} =~ s/(\r\n|\r|\n)+$//;
    }

    if ($tag eq "gallery") {
      $self->{content} .= "\$g->write_table();\n?>\n";
    }

    $self->{SECTION} = pop(@$stack) || "";

  } elsif ($tag eq "article") {

    my $subs = $self->{SUBS};
    my $root = $self->dir();
    my $sub_names = $self->{subs};
    if ($sub_names) {
      foreach my $sub_name (split(' ',$sub_names)) {
        
        my $name = "$root/$sub_name";
        if (-d "src/$name" && -f "src/$name/index.xml") {
          $name .= '/index';
        }
        print STDOUT ".";

        if (!-f "src/$name.xml") {
          print STDERR "ERROR: Cannot find $name\n";

        } else {
          my $sub = WMG::article->new($name);
          $sub->xml_mode(1);
          $sub->parse_file("src".$sub->{name}.".xml");
          push(@{$subs},$sub); 
        }
      }
    }  

  } elsif ($sec ne "") {
    $self->{$sec} .= $orig;

  }

  $self->SUPER::end(@_);
}

#------------------------------------------------------------------------------
# (PARSER) text
sub text
{
  my $self = shift;
  my ($text)=@_;
  if ($self->{SECTION} ne "") {
    $self->{ $self->{SECTION} } .= $text;
    if ($self->{APPEND}) {
      $self->{ $self->{SECTION} } .= $self->{APPEND};
      $self->{APPEND} = 0;
    }
  }
}

#------------------------------------------------------------------------------
# (PARSER) process tag
sub process
{
  my $self = shift;
  my ($text)=@_;
  if ($self->{SECTION} ne "") {
    $text =~ s/\?$//;
    $self->{ $self->{SECTION} } .= "<?$text?>";
  }
}

1;
