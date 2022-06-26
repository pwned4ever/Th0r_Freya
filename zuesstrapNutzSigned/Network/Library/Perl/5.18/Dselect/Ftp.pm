# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

package Dselect::Ftp;

use strict;
use warnings;

our $VERSION = '0.02';
our @EXPORT = qw(
    %CONFIG
    yesno
    nb
    do_connect
    do_mdtm
    view_mirrors
    add_site
    edit_site
    edit_config
    read_config
    store_config
);

use Exporter qw(import);
use Carp;
use Net::FTP;
use Data::Dumper;

my %CONFIG;

sub nb {
  my $nb = shift;
  if ($nb > 1024**2) {
    return sprintf('%.2fM', $nb / 1024**2);
  } elsif ($nb > 1024) {
    return sprintf('%.2fk', $nb / 1024);
  } else {
    return sprintf('%.2fb', $nb);
  }

}

sub read_config {
  my $vars = shift;
  my ($code, $conf);

  local($/);
  open(my $vars_fh, '<', $vars)
    or die "couldn't open '$vars': $!\n" .
           "Try to relaunch the 'Access' step in dselect, thanks.\n";
  $code = <$vars_fh>;
  close $vars_fh;

  my $VAR1; ## no critic (Variables::ProhibitUnusedVariables)
  $conf = eval $code;
  die "couldn't eval $vars content: $@\n" if ($@);
  if (ref($conf) =~ /HASH/) {
    foreach (keys %{$conf}) {
      $CONFIG{$_} = $conf->{$_};
    }
  } else {
    print "Bad $vars file : removing it.\n";
    print "Please relaunch the 'Access' step in dselect. Thanks.\n";
    unlink $vars;
    exit 0;
  }
}

sub store_config {
  my $vars = shift;

  # Check that config is completed
  return if not $CONFIG{done};

  open(my $vars_fh, '>', $vars)
    or die "couldn't open $vars in write mode: $!\n";
  print { $vars_fh } Dumper(\%CONFIG);
  close $vars_fh;
}

sub view_mirrors {
  print <<'MIRRORS';
Please see <http://ftp.debian.org/debian/README.mirrors.txt> for a current
list of Debian mirror sites.
MIRRORS
}

sub edit_config {
  my $methdir = shift;
  my $i;

  #Get a config for ftp sites
  while(1) {
    $i = 1;
    print "\n\nList of selected ftp sites :\n";
    foreach (@{$CONFIG{site}}) {
      print "$i. ftp://$_->[0]$_->[1] @{$_->[2]}\n";
      $i++;
    }
    print "\nEnter a command (a=add e=edit d=delete q=quit m=mirror list) \n";
    print 'eventually followed by a site number : ';
    chomp($_ = <STDIN>);
    /q/i && last;
    /a/i && add_site();
    /d\s*(\d+)/i &&
    do {
         splice(@{$CONFIG{site}}, $1 - 1, 1) if ($1 <= @{$CONFIG{site}});
         next;};
    /e\s*(\d+)/i &&
    do {
         edit_site($CONFIG{site}[$1 - 1]) if ($1 <= @{$CONFIG{site}});
         next; };
    /m/i && view_mirrors();
  }

  print "\n";
  $CONFIG{use_auth_proxy} = yesno($CONFIG{use_auth_proxy} ? 'y' : 'n',
                                  'Go through an authenticated proxy');

  if ($CONFIG{use_auth_proxy}) {
    print "\nEnter proxy hostname [$CONFIG{proxyhost}] : ";
    chomp($_ = <STDIN>);
    $CONFIG{proxyhost} = $_ || $CONFIG{proxyhost};

    print "\nEnter proxy log name [$CONFIG{proxylogname}] : ";
    chomp($_ = <STDIN>);
    $CONFIG{proxylogname} = $_ || $CONFIG{proxylogname};

    print "\nEnter proxy password [$CONFIG{proxypassword}] : ";
    chomp ($_ = <STDIN>);
    $CONFIG{proxypassword} = $_ || $CONFIG{proxypassword};
  }

  print "\nEnter directory to download binary package files to\n";
  print "(relative to $methdir)\n";
  while(1) {
    print "[$CONFIG{dldir}] : ";
    chomp($_ = <STDIN>);
    s{/$}{};
    $CONFIG{dldir} = $_ if ($_);
    last if -d "$methdir/$CONFIG{dldir}";
    print "$methdir/$CONFIG{dldir} is not a directory !\n";
  }
}

sub add_site {
  my $pas = 1;
  my $user = 'anonymous';
  my $email = qx(whoami);
  chomp $email;
  $email .= '@' . qx(cat /etc/mailname || dnsdomainname);
  chomp $email;
  my $dir = '/debian';

  push (@{$CONFIG{site}}, [ '', $dir, [ 'dists/stable/main',
                                        'dists/stable/contrib',
                                        'dists/stable/non-free' ],
                               $pas, $user, $email ]);
  edit_site($CONFIG{site}[@{$CONFIG{site}} - 1]);
}

sub edit_site {
  my $site = shift;

  local($_);

  print "\nEnter ftp site [$site->[0]] : ";
  chomp($_ = <STDIN>);
  $site->[0] = $_ || $site->[0];

  print "\nUse passive mode [" . ($site->[3] ? 'y' : 'n') . '] : ';
  chomp($_ = <STDIN>);
  $site->[3] = (/y/i ? 1 : 0) if ($_);

  print "\nEnter username [$site->[4]] : ";
  chomp($_ = <STDIN>);
  $site->[4] = $_ || $site->[4];

  print <<'EOF';

If you're using anonymous ftp to retrieve files, enter your email
address for use as a password. Otherwise enter your password,
or "?" if you want dselect-ftp to prompt you each time.

EOF

  print "Enter password [$site->[5]] : ";
  chomp($_ = <STDIN>);
  $site->[5] = $_ || $site->[5];

  print "\nEnter debian directory [$site->[1]] : ";
  chomp($_ = <STDIN>);
  $site->[1] = $_ || $site->[1];

  print "\nEnter space separated list of distributions to get\n";
  print "[@{$site->[2]}] : ";
  chomp($_ = <STDIN>);
  $site->[2] = [ split(/\s+/) ] if $_;
}

sub yesno($$) {
  my ($d, $msg) = @_;

  my ($res, $r);
  $r = -1;
  $r = 0 if $d eq 'n';
  $r = 1 if $d eq 'y';
  croak 'incorrect usage of yesno, stopped' if $r == -1;
  while (1) {
    print $msg, " [$d]: ";
    $res = <STDIN>;
    $res =~ /^[Yy]/ and return 1;
    $res =~ /^[Nn]/ and return 0;
    $res =~ /^[ \t]*$/ and return $r;
    print "Please enter one of the letters 'y' or 'n'\n";
  }
}

##############################

sub do_connect {
    my($ftpsite,$username,$pass,$ftpdir,$passive,
       $useproxy,$proxyhost,$proxylogname,$proxypassword) = @_;

    my($rpass,$remotehost,$remoteuser,$ftp);

  TRY_CONNECT:
    while(1) {
	my $exit = 0;

	if ($useproxy) {
	    $remotehost = $proxyhost;
	    $remoteuser = $username . '@' . $ftpsite;
	} else {
	    $remotehost = $ftpsite;
	    $remoteuser = $username;
	}
	print "Connecting to $ftpsite...\n";
	$ftp = Net::FTP->new($remotehost, Passive => $passive);
	if(!$ftp || !$ftp->ok) {
	  print "Failed to connect\n";
	  $exit=1;
	}
	if (!$exit) {
#    $ftp->debug(1);
	    if ($useproxy) {
		print "Login on $proxyhost...\n";
		$ftp->_USER($proxylogname);
		$ftp->_PASS($proxypassword);
	    }
	    print "Login as $username...\n";
	    if ($pass eq '?') {
		    print 'Enter password for ftp: ';
		    system('stty', '-echo');
		    $rpass = <STDIN>;
		    chomp $rpass;
		    print "\n";
		    system('stty', 'echo');
	    } else {
		    $rpass = $pass;
	    }
	    if(!$ftp->login($remoteuser, $rpass))
	    { print $ftp->message() . "\n"; $exit=1; }
	}
	if (!$exit) {
	    print "Setting transfer mode to binary...\n";
	    if(!$ftp->binary()) { print $ftp->message . "\n"; $exit=1; }
	}
	if (!$exit) {
	    print "Cd to '$ftpdir'...\n";
	    if(!$ftp->cwd($ftpdir)) { print $ftp->message . "\n"; $exit=1; }
	}

	if ($exit) {
	    if (yesno ('y', 'Retry connection at once')) {
		next TRY_CONNECT;
	    } else {
		die 'error';
	    }
	}

	last TRY_CONNECT;
    }

#    if(!$ftp->pasv()) { print $ftp->message . "\n"; die 'error'; }

    return $ftp;
}

##############################

# assume server supports MDTM - will be adjusted if needed
my $has_mdtm = 1;

my %months = ('Jan', 0,
	      'Feb', 1,
	      'Mar', 2,
	      'Apr', 3,
	      'May', 4,
	      'Jun', 5,
	      'Jul', 6,
	      'Aug', 7,
	      'Sep', 8,
	      'Oct', 9,
	      'Nov', 10,
	      'Dec', 11);

my $ls_l_re = qr<
    ([^ ]+\ *){5}                       # Perms, Links, User, Group, Size
    [^ ]+                               # Blanks
    \ ([A-Z][a-z]{2})                   # Month name (abbreviated)
    \ ([0-9 ][0-9])                     # Day of month
    \ ([0-9 ][0-9][:0-9][0-9]{2})       # Filename
>x;

sub do_mdtm {
    my ($ftp, $file) = @_;
    my ($time);

    #if ($has_mdtm) {
	$time = $ftp->mdtm($file);
#	my $code = $ftp->code();
#	my $message = $ftp->message();
#	print " [ $code: $message ] ";
	if ($ftp->code() == 502 || # MDTM not implemented
	    $ftp->code() == 500) { # command not understood (SUN firewall)
	    $has_mdtm = 0;
	} elsif (!$ftp->ok()) {
	    return;
	}
    #}

    if (! $has_mdtm) {
	require Time::Local;

	my @files = $ftp->dir($file);
	if (($#files == -1) ||
	    ($ftp->code == 550)) { # No such file or directory
	    return;
	}

#	my $code = $ftp->code();
#	my $message = $ftp->message();
#	print " [ $code: $message ] ";

#	print "[$#files]";

	# get the date components from the output of 'ls -l'
	if ($files[0] =~ $ls_l_re) {

            my($month_name, $day, $year_or_time, $month, $hours, $minutes,
	       $year);

	    # what we can read
	    $month_name = $2;
	    $day = 0 + $3;
	    $year_or_time = $4;

	    # translate the month name into number
	    $month = $months{$month_name};

	    # recognize time or year, and compute missing one
	    if ($year_or_time =~ /([0-9]{2}):([0-9]{2})/) {
		$hours = 0 + $1; $minutes = 0 + $2;
		my @this_date = gmtime(time());
		my $this_month = $this_date[4];
		my $this_year = $this_date[5];
		if ($month > $this_month) {
		    $year = $this_year - 1;
		} else {
		    $year = $this_year;
		}
	    } elsif ($year_or_time =~ / [0-9]{4}/) {
		$hours = 0; $minutes = 0;
		$year = $year_or_time - 1900;
	    } else {
		die 'cannot parse year-or-time';
	    }

	    # build a system time
	    $time = Time::Local::timegm(0, $minutes, $hours, $day, $month, $year);
	} else {
	    die 'regex match failed on LIST output';
	}
    }

    return $time;
}

1;

__END__
