#!/bin/sh
# Cat's Nmap 1.x - shell/Perl polyglot
# © AC Kondo 1999–2026
exec /usr/bin/perl -x "$0" "$@"
#!perl
use strict;
use warnings;
use IO::Socket::INET;
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(time);
my ($ports, $timeout, $output, $help) = ('1-1024', 1, '', 0);
GetOptions('p=s' => \$ports, 't=i' => \$timeout, 'o=s' => \$output, 'h|help' => \$help) or die "Invalid options\n";
if ($help || @ARGV != 1) { print "Usage: bash cats_nmap_1x.sh [-p 22,80,443|1-1024] [-t seconds] [-o report.txt] HOST\n"; exit($help ? 0 : 2); }
my $host = shift @ARGV;
die "Invalid target\n" unless $host =~ /\A[A-Za-z0-9][A-Za-z0-9.-]*\z/ && length($host) <= 253;
die "Timeout must be 1-30 seconds\n" unless $timeout >= 1 && $timeout <= 30;
my %selected;
for my $part (split /,/, $ports, -1) {
    my ($a, $b);
    if ($part =~ /\A(\d{1,5})\z/) { ($a, $b) = ($1, $1); }
    elsif ($part =~ /\A(\d{1,5})-(\d{1,5})\z/) { ($a, $b) = ($1, $2); }
    else { die "Invalid port specification: $part\n"; }
    die "Invalid port range: $part\n" unless $a >= 1 && $b <= 65535 && $a <= $b;
    $selected{$_} = 1 for $a..$b;
}
my @ports = sort { $a <=> $b } keys %selected;
print "Cat's Nmap 1.x | TCP connect scan | © AC Kondo 1999–2026\n";
print "Target: $host | Ports: ", scalar(@ports), "\n";
print "Only scan hosts you own or are authorized to test.\n";
print "Confirm authorization [y/N]: ";
my $answer = <STDIN> // '';
chomp $answer;
if ($answer !~ /\Ay\z/i) { print "Cancelled.\n"; exit 0; }
my $started = time();
my @lines = ("Cat's Nmap 1.x", "Target: $host", "PORT      STATE   SERVICE");
my $open = 0;
for my $port (@ports) {
    my $sock = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => $timeout);
    if ($sock) {
        close $sock;
        my $service = getservbyport($port, 'tcp') || 'unknown';
        push @lines, sprintf('%-9s %-7s %s', "$port/tcp", 'open', $service);
        $open++;
    }
}
push @lines, sprintf('Open ports: %d | Scanned: %d | Elapsed: %.2fs', $open, scalar(@ports), time()-$started);
print join("\n", @lines), "\n";
if (length $output) {
    open my $fh, '>', $output or die "Cannot write report: $!\n";
    print {$fh} join("\n", @lines), "\n";
    close $fh or die "Cannot close report: $!\n";
    print "Report saved: $output\n";
}
