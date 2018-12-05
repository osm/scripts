use strict;
use warnings;
use utf8;

use Encode;
use Irssi;
use JSON::PP;
use LWP::UserAgent;

use vars qw($VERSION %IRSSI);

$VERSION = '1.0.0';
%IRSSI = (
    authors     => 'Oscar Linderholm',
    contact     => 'osm@recv.se',
    name        => 'Lyssnar',
    description => 'Display what you are listening to on Spotify',
    license     => 'MIT',
    changed     => '2018-12-05',
);

sub lyssnar {
    my $user = Irssi::settings_get_str('user');
    if (length($user) < 1) {
        print CLIENTCRAP 'error: user needs to be set';
        return;
    }

    my $req = new HTTP::Request GET => 'http://lyssnar.com/v1/user/' . $user . '/currently-playing';
    my $ua = new LWP::UserAgent;
    $ua->agent('irssi-lyssnar/1.0.0');

    my $content = $ua->request($req)->content;
    my $decoded = decode_json($content);

    if (defined($decoded->{"error"})) {
        print CLIENTCRAP 'an error was returned by lyssnar.com';
        return;
    }

    my $artists = '';
    foreach (@{$decoded->{'item'}->{'artists'}}) {
        $artists = length($artists) == 0 ? $_->{'name'} : $artists . ', ' . $_->{'name'};
    }

    $artists = encode('utf-8', $artists);
    my $track = encode('utf-8', $decoded->{'item'}->{'name'});
    my $url = $decoded->{'item'}->{'external_urls'}->{'spotify'};
    my $uri = 'spotify:track:' . $decoded->{'item'}->{'id'};

    my $prefixes = Irssi::settings_get_str('prefixes');
    my $postfixes = Irssi::settings_get_str('postfixes');
    my @prefixes = split(/, ?/, $prefixes);
    my @postfixes = split(/, ?/, $postfixes);
    my $prefix = $prefixes[int(rand(scalar(@prefixes)))];
    my $postfix = $postfixes[int(rand(scalar(@postfixes)))];

    my $output = 'me ' . $prefix . ' ' . $artists . ' - ' . $track . ' @ ' . $url . ' / ' . $uri . ' ' . $postfix;
    Irssi::active_win()->command($output);
}

Irssi::command_bind lyssnar => \&lyssnar;
Irssi::settings_add_str('lyssnar', 'user', '');
Irssi::settings_add_str('lyssnar', 'prefixes', 'is listening to');
Irssi::settings_add_str('lyssnar', 'postfixes', '');
