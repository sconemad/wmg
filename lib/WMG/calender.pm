package WMG::calender;

=head1 NAME

WMG::calendar - wmg calendar

=head1 COPYRIGHT

Coyright 2002-2006 Andrew Wedgbury. All Rights Reserved

=head1 AUTHOR

Andrew Wedgbury <lt>wedge@sconemad.com<gt>

=cut

use strict;
use vars qw($VERSION @days @mths);

$VERSION = '1.0';

@days=qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
@mths=qw(January February March April May June July August September October November December);

sub new {
  my $proto=shift;
  my $class=ref($proto) || $proto;
  my $self = {};

  $self->{MONTHS} = {};
  $self->{LINK} = {};
  $self->{CLASS} = {};

  bless($self,$class);
  return $self;
}

my @now=[];

sub add_month
{
  my $self = shift;
  my ($month)=@_;
  $self->{MONTHS}->{$month}=1;
}

sub add_link
{
  my $self = shift;
  my ($dcode,$href,$owr)=@_;

  if ($owr || !defined $self->{LINK}->{$dcode}) {
    $self->{LINK}->{$dcode}=$href;
  }
}

sub write
{
  my $self = shift;
  @now = localtime();

  print "<table class='wcal'>\n"; 

  foreach my $mcode (sort {$a <=> $b} keys %{$self->{MONTHS}}) {
    if ($mcode !~ /(\d\d\d\d)(\d\d)/) {
      print STDERR "Bad mcode: $mcode\n";
      exit 1;
    }
    my ($year,$month) = ($1,$2);

    my $leap = (!($year % 4) && ($year % 100)) || !($year % 400);
    my @mlen=(31,$leap?29:28,31,30,31,30,31,31,30,31,30,31);
    my $maxd = $mlen[$month-1];
    my @t = localtime( Time::Local::timelocal(0,0,0,1,$month-1,$year) );
    my $mstart = $t[6];

    my $i=0;
    my $d=1;

    print "<tr><th colspan='7'>$mths[$month-1] $year</th></tr>\n";

    print "<tr>";
    for ($i=0; $i<7; ++$i) { 
      my $day = substr($days[$i],0,3);
      print "<th class='$day'>$day</th>"; 
    }
    print "</tr>\n";

    print "<tr>"; 

    for ($i=0; $i<$mstart; ++$i) { 
      print "<td></td>"; 
    }

    for ( ; $i<7; ++$i) { 
      $self->do_day($year,$month,$d++);
    }

    print "</tr>\n"; 

    OUTER: while (1) {
      print "<tr>";
      for ($i=0; $i<7; ++$i) { 
        $self->do_day($year,$month,$d++);
        if ($d > $maxd) {
          last OUTER;
        }
      }
      print "</tr>\n"; 
    }

    ++$i;
    for ( ; $i<7; ++$i) { 
      print "<td></td>";
    }

    print "</tr>\n"; 
  }

  print "</table>\n"; 
}

sub write_year
{
  my $self = shift;
  @now = localtime();

  print "<table class='wcal' cellspacing='0'>\n"; 

  my $maxgrid = 37;
  my $prev_year = 0;

  foreach my $mcode (sort {$a <=> $b} keys %{$self->{MONTHS}}) {
    if ($mcode !~ /(\d\d\d\d)(\d\d)/) {
      print STDERR "Bad mcode: $mcode\n";
      exit 1;
    }
    my ($year,$month) = ($1,$2);
 
    if ($year ne $prev_year) {
      my $wd=0;
      print "<tr>";
      print "<th>$year</th>";
      for (my $i=0; $i<$maxgrid; ++$i) { 
        my $day = substr($days[$wd],0,1);
        print "<th class='$day'>$day</th>"; 
        $wd = 0 if (++$wd > 6);
      }
      print "</tr>\n";
    }

    $prev_year = $year;

    my $leap = (!($year % 4) && ($year % 100)) || !($year % 400);
    my @mlen=(31,$leap?29:28,31,30,31,30,31,31,30,31,30,31);
    my $maxd = $mlen[$month-1];
    my @t = localtime( Time::Local::timelocal(0,0,0,1,$month-1,$year) );
    my $wd = $t[6];

    my $i=0;
    my $d=1;

    print "<tr>"; 

    print "<th>".substr($mths[$month-1],0,3)."</th>";

    for ($i=0; $i<$wd; ++$i) { 
      print "<td></td>"; 
    }

    for ($d=1; $d<=$maxd; ++$d) { 
      $self->do_day($year,$month,$d,$wd);
      $wd = 0 if (++$wd > 6);
      ++$i;
    }

    for (; $i<$maxgrid; ++$i) { 
      print "<td></td>"; 
    }

    print "</tr>\n";

  }
  print "</table>\n"; 
}

sub do_day
{
  my $self = shift;
  my ($year,$month,$day,$wd)=@_;
  my $dcode = sprintf("%4d%02d%02d",$year,$month,$day);
  my $link = $self->{LINK}->{$dcode};
  my $class = $self->{CLASS}->{$dcode};

  print "<td";
  if (defined $class) {
    print " class='$class'";
  } elsif (defined $wd) {
    print " class='". substr($days[$wd],0,3) ."'";
  }
  if ($now[5]+1900 == $year && $now[4]+1 == $month && $now[3] == $day) {
    print " id='today'";
  }
  print ">";
 
  if (defined $link) {
    print "<a href='$link'>$day</a>"; 
  } else {
    print "$day"; 
  }

  print "</td>";
}

1;
