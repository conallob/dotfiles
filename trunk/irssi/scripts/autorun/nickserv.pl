#
# Nickserv Irssi Script by Michal 'Spock' Januszewski <spock@gentoo.org>
#
# 2004-01-12
#  - version 1.1
#    added support for nick recovery
#
# 2003-02-25
#  - version 1.0

use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '1.01';
%IRSSI = (
	name		=> 'nickserv',
	description	=> 'Allows to automatically set your nick and identify yourself when connecting to an IRC network with NickServ.',
	authors		=> "Michal 'Spock' Januszewski",
	contact		=> 'spock@gentoo.org',
	url		=> 'http://dev.gentoo.org/~spock/',
	license		=> 'GPL'
);

my ($timeout) = 60;					# maximum amount of time for Nickserv to respond to our query
my (@nicks);						# main data 
my ($last_request) = 0;					# timestamp of the last request
my ($stat_win) = Irssi::window_find_refnum(1);		# get status window handle
my (%nicks_recovered);

# loads nicks setup from file (default: ~/.irssi/nickserv)
sub load_nicks {
	@nicks = ();

	my ($file) = Irssi::get_irssi_dir."/nickserv";	# data file
	open FILE, "< $file" || return;

	my ($line,$i) = 0;;
	while ($line = <FILE>) {
		if ($line =~ /([a-zA-Z0-9_\-\`\[\]\{\}\|]+)\s+([a-zA-Z0-9_\-\`\[\]\{\}\|]+)\s+([a-zA-Z0-9_\-\`\[\]\{\}\|\.]+)\s+(1|0)/) { #`
			$nicks[$i]{'nick'} = $1;
			$nicks[$i]{'pass'} = $2;
			$nicks[$i]{'ircnet'} = $3;
			$nicks[$i]{'on_connect'} = $4;
			$i++;
		}
	}
	close FILE;
}

# saves nicks configuration to the setup file
sub save_nicks {

	my ($file) = Irssi::get_irssi_dir."/nickserv";	# data file
	my ($i);
	open FILE, "> $file" || return;
    
	for ($i = 0; $i < $#nicks+1; $i++) {
		print FILE $nicks[$i]{'nick'}."\t".$nicks[$i]{'pass'}."\t".$nicks[$i]{'ircnet'}."\t".$nicks[$i]{'on_connect'}."\n";    
	}

	close FILE;
}

# handle the nickserv notices
sub event_notice {

	my ($server, $text, $nick, $address) = @_;
	return unless $nick eq 'NickServ';			# we don't want to process notices not sent by the nickserv

	my $mynick = lc $server->{'nick'};
	my $ircnet = lc $server->{'chatnet'};
	my ($i);

	if ($text =~ /This nickname is registered/ || $text =~ /This nickname is owned by someone else/) {

		for ($i = 0; $i < $#nicks+1; $i++) {		# check whether we have the requested nick in the database	
			if (lc $nicks[$i]{'nick'} eq $mynick && lc $nicks[$i]{'ircnet'} eq $ircnet) {
				$server->command("QUOTE NickServ identify ".$nicks[$i]{'pass'});
				$last_request = time;
				Irssi::signal_stop();
	    		}
		}                

	} elsif ((($text =~ /NickServ IDENTIFY/) || ($text =~ /NickServ RELEASE/) ||
        		($text =~ /please choose a different nick/) || ($text =~ /isn\'t currently in use/) ||
			($text =~ /isn\'t being held/) ||
			($text =~ /If this is your nickname, type/)) && (time - $last_request < $timeout)) {

		Irssi::signal_stop();				# just don't let Irssi display anything to the user ;>

	} elsif ($text =~ /Password accepted/ && (time - $last_request < $timeout)) {

		$stat_win->print("Nickserv has accepted the password.",MSGLEVEL_CRAP);
	        Irssi::signal_stop();

	} elsif ($text =~ /has been killed/ && exists($nicks_recovered{"$ircnet"})) {

		$server->command("NICK ".$nicks_recovered{"$ircnet"});
		delete $nicks_recovered{"$ircnet"};

	}	
}

# set nick on connect
sub event_connected {
	my ($server) = @_;
	my $ircnet = lc $server->{'chatnet'};
	my ($i);

	for ($i = 0; $i < $#nicks+1; $i++) {
		if ($nicks[$i]{'on_connect'} == 1 && lc $nicks[$i]{'ircnet'} eq $ircnet) {
			$server->command("NICK ".$nicks[$i]{'nick'});
			$stat_win->print("Automatically setting nick to ".$nicks[$i]{'nick'},MSGLEVEL_CRAP);
		}		
	}
}

# handle nicks already in use
sub event_nick_taken {
	my ($server, $text, $nick, $address) = @_;

	my $mynick = lc $server->{'nick'};
	my $ircnet = lc $server->{'chatnet'};
	my ($i);
	my ($mynick, $attnick) = split(/ /,$text);

	for ($i = 0; $i < $#nicks+1 && $nicks_recovered{"$ircnet"} ne $attnick; $i++) {
		if (lc $nicks[$i]{'nick'} eq $attnick && lc $nicks[$i]{'ircnet'} eq $ircnet) {
			$server->command("QUOTE NickServ recover $attnick ".$nicks[$i]{'pass'});
			$server->command("QUOTE NickServ ghost $attnick ".$nicks[$i]{'pass'});
			$server->command("QUOTE NickServ release $attnick ".$nicks[$i]{'pass'});
			$stat_win->print("Recovering nick $attnick",MSGLEVEL_CRAP);
			$nicks_recovered{"$ircnet"} = $attnick;
			$last_request = time;
			Irssi::signal_stop();
		}
	}
}

# add a new entry to our nick list
sub subcmd_add {

	my ($data,$server,$witem) = @_;
	my ($nick,$pass,$ircnet,$on_conn) = split / +/,$data;
	my ($i,$changed) = 0;

	$on_conn = 0 unless ($on_conn);

	unless ($nick && $pass && $ircnet) {
		print "\nUsage: ";
		print "   /nickserv add <nick> <password> <chatnet> [0|1] - last parameter is used for ASNOC, default: 0";
		print "   ASNOC = Automatically Set Nick On Connect";
		print "   This command could also be used to change password/ASNOC setting for existing entries.";
		return;
	}

	for ($i = 0; $i < $#nicks+1 && !$changed; $i++) {
		if ($nicks[$i]{'nick'} eq $nick && $nicks[$i]{'ircnet'} eq $ircnet) {
	    
			# just modify the ASNOC setting
			if ($nicks[$i]{'on_connect'} != $on_conn) {		
				print "Automatically Set Nick On Connect is now set to: $on_conn.";
				$nicks[$i]{'on_connect'} = $on_conn;
				save_nicks();
				#load_nicks();
				$changed = 1;
			}

			# no need to modify or add anything
			if ($nicks[$i]{'pass'} eq $pass) {

				if (!$changed) {
					print "You already have an entry for nick $nick in $ircnet ircnet.";
				}
			
				$changed = 1;
	
		    	# just change the password for the given nick
		    	} else {
				print "Entry data for nick $nick in the IRC network '$ircnet' has been updated.";
				print "Old password: ".$nicks[$i]{'pass'};
				print "New password: $pass";
				$nicks[$i]{'pass'} = $pass;
				save_nicks();
				#load_nicks();
				$changed = 1;
		    	}
		}
	}

	# add a new entry
	if (!$changed) {
		print "Entry data for nick $nick in the IRC network '$ircnet' has been added.";
		$nicks[$i]{'nick'} = $nick;
		$nicks[$i]{'pass'} = $pass;
		$nicks[$i]{'ircnet'} = $ircnet;
		$nicks[$i]{'on_connect'} = $on_conn;
		save_nicks();
		#load_nicks();
	}

	$changed = 0;

	# check if there is another nick(s) with ASNOC set to "1" for the current chatnet - if so, disable ASNOC for it/them
	if ($on_conn == 1) {
		for ($i = 0; $i < $#nicks+1; $i++) {
			if ($nicks[$i]{'nick'} ne $nick && $nicks[$i]{'ircnet'} eq $ircnet && $nicks[$i]{'on_connect'} == 1) {
				$nicks[$i]{'on_connect'} = 0;
				$changed++;
			}
		}
		save_nicks();
		#load_nicks();

		print "Automatically disabled $changed ASNOC entries for the IRC network '$ircnet'." if ($changed);
	}
}

# remove a nick from the list
sub subcmd_remove {

	my ($id,$server,$witem) = @_;

	unless ($id) {
		print "\nUsage: ";
		print "  /nickserv remove <id>\n";
		return;
	}

	if ($id < 0 || $id > $#nicks+1) {
		print "Invalid ID.";
		return;    
	}

	$id--;
	print "Entry data for nick ".$nicks[$id]{'nick'}." in the IRC network '".$nicks[$id]{'ircnet'}."' has been deleted.";
	splice(@nicks,$id,1);	
	save_nicks();
	#load_nicks();
}

# show the nicks database to the user
sub subcmd_list {

	my ($i, $max_nick, $max_pass, $max_ircnet, $max_num) = (0,4,8,6,2);	# set default values to lenghts of the headers
    
	# find longest entries
	for ($i = 0; $i < $#nicks+1; $i++) {
		$max_nick = length($nicks[$i]{'nick'}) if (length($nicks[$i]{'nick'}) > $max_nick);
		$max_pass = length($nicks[$i]{'pass'}) if (length($nicks[$i]{'pass'}) > $max_pass);
		$max_ircnet = length($nicks[$i]{'ircnet'}) if (length($nicks[$i]{'ircnet'}) > $max_ircnet);
	}

	$max_num = $max_num > int($i/10) ? $max_num : int($i/10);		# is the ID lenght enough?
	$max_nick += 2; $max_pass += 2, $max_num += 2;			# add some space between the columns

	if ($#nicks > -1) {							# do we have anything to show?

		print "\n".pack("A$max_num", "ID").pack("A$max_nick","Nick").pack("A$max_pass","Password").pack("A$max_ircnet","Ircnet")."  ASNOC";	# header
		print "-" x ($max_nick+$max_pass+$max_ircnet+$max_num+7);	# delimiter
    
	        for ($i = 0; $i < $#nicks+1; $i++) {
    			print pack("A$max_num", ($i+1)).pack("A$max_nick",$nicks[$i]{'nick'}).
			pack("A$max_pass",$nicks[$i]{'pass'}).pack("A$max_ircnet",$nicks[$i]{'ircnet'})."    ".$nicks[$i]{'on_connect'};
		} 

		print "-" x ($max_nick+$max_pass+$max_ircnet+$max_num+7)."\n";	# delimiter
	}
	
	print "Total ".($#nicks+1)." nicks in database.";			# summary
}

sub cmd_nickserv {

	my ($data,$server,$witem) = @_;
    
	if ($data =~ /^\!/) {				# direct NickServ request
		$data =~ s/^\!\s*//;
		$server->command("QUOTE NickServ $data");
	} elsif ($data =~ /^add/) {
		$data =~ s/^add\s*//;
		subcmd_add($data,$server,$witem);
	} elsif ($data =~ /^list/) {
		$data =~ s/^list\s*//;
		subcmd_list($data,$server,$witem);
	} elsif ($data =~ /^remove/) {
		$data =~ s/^remove\s*//;
		subcmd_remove($data,$server,$witem);
	} else {
		my ($banner) = "Nickserv script v$VERSION (c) 2003 by Spock <spock\@gentoo.org>";
		print "\n$banner";
		print "-" x length($banner);	
		print "Usage: ";
		print "   /nickserv !command <params> - pass a request directly to the nickserv";
		print "   /nickserv add <nick> <password> <chatnet> [0|1] - add an entry, last param is used for ASNOC";
		print "   /nickserv remove <id> - delete an entry by ID";
		print "   /nickserv list - list entries\n";
		print "ASNOC = Automatically Set Nick On Connect"; 
		print "The command 'add' could also be used to change password/ASNOC setting for existing entries.";
	}
}

load_nicks();

Irssi::command_bind('nickserv', 'cmd_nickserv');
Irssi::signal_add('message irc notice', 'event_notice');
Irssi::signal_add('event connected', 'event_connected');
Irssi::signal_add('event 433', 'event_nick_taken');
