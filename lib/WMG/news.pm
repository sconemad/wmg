package WMG::news;

=head1 NAME

WMG::news - wmg RSS news module

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

my $rss_tags = "channel|image|item|title|link|description|pubDate";

sub make_news
{
  my $filter = shift || ".*";
  my $news="";
  my $rssdir = $ENV{HOME}."/rss";
  opendir(DIR,$rssdir);
  my @dir = readdir(DIR);
  closedir(DIR);

  my $c=0;
  foreach my $file(@dir) {
    next if ($file =~ /^\./);
    next if ($file !~ /$filter/);

    print STDERR "NEWS: $file\n";

    my $rss = WMG::news->new($file);
    $rss->xml_mode(1);
    $rss->parse_file("$rssdir/$file");

    my $channel_title = $rss->{title};
    
    print "Adding news feed: $channel_title\n";
    my $channel_link = $rss->{link};
  
    $news .= "<h3><a href='$channel_link'>$channel_title</a></h3>\n";

    my $i=0;
    foreach my $item (@{$rss->{ITEMS}}) {
      last if (++$i > 10);
      print STDERR "ITEM: " . $item->{title} . " : " . $item->{link} . "\n";
      my $desc = $item->{description};
      $desc =~ s/\"/\'/g;
      $news .= "<p class='newsitem'>".
	  "<a href='".$item->{link}."' title=\"$desc\">".
	  $item->{title}."</a>".
	  "</p>\n";
    }
  }
  return $news;
}

# Constructor
sub new {
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self = $class->SUPER::new();
  
  # Article path
  $self->{FILE}=shift;

  # Sub articles
  $self->{ITEMS}=[];

  # Parse data
  $self->{SECTION}='';
  $self->{SEEKTAGS}= $rss_tags;
  $self->{STACK}=[];

  bless($self,$class);
  return $self;
}

#------------------------------------------------------------------------------
# (PARSER) start tag
sub start
{
  my $self = shift;
  my ($tag,$args,undef,$orig)=@_;
  my $stack = $self->{STACK};

  if ($tag =~ /^($self->{SEEKTAGS})$/) {
    my $ptag = $self->{SECTION};
    push(@$stack,$ptag);
    $self->{SECTION}=$tag;

    if ($tag eq 'item') {
      my $item = {};
      push(@{$self->{ITEMS}},$item);
      $self->{ITEM} = $item;
    }

    if ($tag eq 'image') {
      my $image = {};
      $self->{IMAGE} = $image;
      $self->{ITEM} = $image;
    }

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
    $self->{SECTION} = pop(@$stack) || "";
    
    if ($tag =~ /item|image/) {
      $self->{ITEM} = 0;
    }
  }

  $self->SUPER::end(@_);
}

#------------------------------------------------------------------------------
# (PARSER) text
sub text
{
  my $self = shift;
  my ($text)=@_;

  $text =~ s/\&\#34;/\"/g;
  $text =~ s/\&\#38;/\&/g;
  $text =~ s/\&\#60;/\</g;
  $text =~ s/\&\#62;/\>/g;

  if ($self->{SECTION} ne "") {

    my $item = $self->{ITEM};
    if ($item) {
      if ($self->{SECTION} =~ /title|link|description|pubDate/) {
        $item->{$self->{SECTION}} .= $text;
      }
    } else {
      $self->{ $self->{SECTION} } .= $text;
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
