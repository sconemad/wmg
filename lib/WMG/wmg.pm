package WMG::wmg;

=head1 NAME

WMG::wmg - wmg main module

=head1 SYNOPSIS

  WMG::wmg::run();

=head1 DESCRIPTION

Main driver for wmg

=head1 COPYRIGHT

Coyright 2002-2006 Andrew Wedgbury. All Rights Reserved

=head1 AUTHOR

Andrew Wedgbury <lt>wedge@sconemad.com<gt>

=cut

use IO::File;
use Getopt::Std;
use Time::Local;
use File::Copy;
use File::Find;
use Cwd;

use WMG::article;
use WMG::output;
use WMG::weblog;
use WMG::image;
use WMG::gallery;
use WMG::calender;
use WMG::news;
use WMG::localiser;

#------------------------------------------------------------------------------
sub run
{
  # Print header

  $wmg_ver = $WMG::output::VERSION;
  print "wmg $wmg_ver\n";

  do_options();

  my $arg = "@ARGV";
  $artpath = $opt_p || "/articles";
  $editor = $ENV{EDITOR} || "emacs";
  my $site_def = "sitedef";

  if (! -f $site_def) {
    die "No site definition file '$site_def' - not a WMG directory?";
  }

  # OPT: New article

  if (defined $opt_n) {
    do_new_article();
    exit(0);
  }
  
  # Interpret remaining command line as filter
  
  $filter = $arg || ".*";
  if ($filter =~ /^(\d{1,3})$/) {
    $filternum = $1;
  }

  # Load articles

  print "\nLOADING ARTICLES\n";
  
  $blog = WMG::weblog->new($artpath);
  $blog->add();
  
  $index = WMG::article->new("/index");
  $index->xml_mode(1);
  $index->parse_file("src/index.xml");
  print "\nOK\n";
  

  # OPT: Edit article n

  if (defined $opt_e) {
    do_edit_article();
    exit 0;
  }
  
  # OPT: List articles

  if (defined $opt_l) {
    do_list_articles();
    exit 0;
  }
  
  # Load site setup

  if (-f $site_def) {
    print "\nLOADING SITE SETUP\n";
    
    my $defcode = "";
    open(SITEDEF,$site_def);
    while (<SITEDEF>) { $defcode .= $_; }
    close(SITEDEF);
    $site = {};
    $site->{INDEX}=$index;
    $site->{BLOG}=$blog;
    $site->{BLOG_ARCHIVE}=1;
    eval $defcode; 
    print "OK\n";
  }
  
  # Compile
  
  if (defined $opt_c) {
    print "\nCOMPILING\n";
    $blog->output($site,$filter);
    $index->output($site,$filter);
    print "OK\n";
  }

  # Localise

  if (defined $opt_a) {
    print "\nLOCALISING\n";
    find( {wanted=>\&localise, no_chdir=>1}, 'html');
    print "OK\n";
  }
  
}

#------------------------------------------------------------------------------
sub localise
{
  return if ($_ !~ /\.(html)$/);
  $_ =~ /^html(\/.+)$/;
  my $name = $1;
  open(TMP,">tmp");
  select(TMP);
  my $loc = WMG::localiser->new($name);
  $loc->parse_file("html/$name");
  select(STDOUT);
  close(TMP);
  move("tmp","html/$name");
}

#------------------------------------------------------------------------------
sub do_options
{
  undef $opt_l;
  undef $opt_e;
  undef $opt_n;
  undef $opt_c;
  undef $opt_p;
  undef $opt_a;
  undef $opt_h;
  my $opts = "lencp:ah";
  my $optnum = scalar @ARGV;
  my $optret = getopts($opts);
  
  if (!$optnum || !$optret || defined $opt_h) {
    print STDERR "No options specified\n" if (!$optnum);
    
    my $dom = '@sconemad';
    print << "XXX";
    
 Perl-driven web site generator
 Copyright (c) 2003-2006 Andrew Wedgbury <wedge$dom.com>
 Project homepage: http://www.sconemad.com/wmg
      
 Usage: wmg [OPTIONS]... <filter>
   
   -l list articles
   -e edit article(s)
   -n new article. In this case <filter> specifies the actual title. By default
      reads STDIN for content section. Combine with -e to open in editor.
   -c compile articles
   -p <path> specify a different article path (default: 'articles').
   -a localise paths (using .. etc) for local browsing.
   -h display this help

   <filter>, if specified allows you to match specific articles, months or 
   index pages by name to operate on. Can be a regex or an article index 
   (shown by -l option, where 1 is the latest article).

XXX

    exit 1;
  }
}

#------------------------------------------------------------------------------
sub do_new_article
{
  select(STDOUT); $| = 1;
  print "\nNEW ARTICLE\n";
  my $uniq=0;
  do {
    if (++$uniq >= 100) {
      die "Unable to select unique ID for new article";
    }
    my @t = localtime();
    my $id = sprintf("%04d%02d%02d%02d%02d%02d",
                     $t[5]+1900,$t[4]+1,$t[3],$t[2],$t[1],$t[0]+$uniq);
    $path = "src/$artpath/$id";
    ++$uniq;
    } while (-e $path);
  
  mkdir($path);
  die "Could not create dir '$path'" if (!-d $path);
  
  print "Creating article in: $path\n";
  
  my $artfile = "$path/article.xml";
  
  if (-e $artfile) {
    die "File $artfile alredy exists";
  }
  
  open(FILE,">$artfile") || die "Cannot open file $artfile";
    print FILE "<?xml version='1.0' ?>\n";                                          
  my $title = $arg || "title";
  my $author = $ENV{USER} || "Unknown";
  
  print FILE "<article title=\"$title\" author=\"$author\">\n\n";
  print FILE "<description></description>\n\n";
  
  print FILE "<content>\n";
  if (!defined $opt_e) {
    while (my $l = <STDIN>) {
      last if ($l =~ /^\.$/);
      print FILE $l;  
    }
  }
  print FILE "</content>\n\n";
  
  print FILE"</article>\n";
    close FILE;

  if (defined $opt_e) {
    $artfile = getcwd() . "/$artfile";
    system "$editor $artfile";
  }
}

#------------------------------------------------------------------------------
sub do_edit_article
{
  print "\nEDIT ARTICLES\n";
  
  my $artpaths = "";
  my $i=0;
  foreach my $art (@{$blog->{SUBS}}) {
    ++$i;
    if ($filternum) {
      next if ($i != $filternum);
    } else {
      next if ($art->{name} !~ /$filter/);
    }
    
    $artpaths .= getcwd() . "/src".$art->{name}."/article.xml ";
  }

  if ($artpaths) {
    system "$editor $artpaths";
  } else {
    print "NO ARTICLES MATCHING '$filter'\n";
  }
}

#------------------------------------------------------------------------------
sub do_list_articles
{
  print "\nLISTING ARTICLES\n";
  my $i = 1+@{$blog->{SUBS}};
  foreach my $art (reverse @{$blog->{SUBS}}) {
    --$i;
    if ($filternum) {
      next if ($i != $filternum);
    } else {
      next if ($art->{name} !~ /$filter/);
    }
    
    printf("[%03d] %s %s %s\n",
           $i,
           $art->pub() ? "+" : "-",
           $art->date_string(),
           $art->{title});
  }
}

1;
