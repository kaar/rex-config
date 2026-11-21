#!/usr/bin/env perl
# Reads pane text on stdin and prints deduplicated URLs, one per line.
# OSC 8 targets are collected before terminal escapes are removed.
# Run the built-in tests with: perl rex/extract-urls.pl --self-test
#
# Patterns run as one alternation per line, so an earlier match consumes its
# text and a later pattern cannot re-match inside it (https://www.example.com
# is one URL, not also a www match). Priority order:
#
#   URL  https/http/ftp/file URLs, kept verbatim
#   GIT  git@host:path / ssh://git@host/path  -> https://host/path
#   WWW  bare www. domains                    -> http://www...
#   IP   v4 address, optional port and path   -> http://1.2.3.4...
use strict;
use warnings;

my $ipv6_literal = qr{\[[0-9a-f:.]+\]}i;
my $url_char = qr{[-\w+&\@\#/%?=~|!:,.;]};
# (?-1) recurses into the parenthesized group so nested pairs stay intact.
my $url_parens = qr{(\((?:$url_char++|(?-1))*+\))};
# Parentheses belong in the path, query, or fragment, not the authority.
# Match runs of ordinary characters to avoid Perl's per-match repeat limit.
my $url_tail_with_parens = qr{[-\w+&\@%=~|!:,.;]*+[/?\#](?:$url_char*+$url_parens)++};
my $domain_label = qr{[a-zA-Z0-9](?:-?[a-zA-Z0-9])*};
my $www_domain = qr{www\.[a-zA-Z](?:-?[a-zA-Z0-9])+(?:\.$domain_label)*\.[a-zA-Z]{2,}};
# Not part of a longer dotted number, such as a version string.
my $bare_ipv4 = qr{(?<![\w.])\d{1,3}(?:\.\d{1,3}){3}(?!\d|\.\d)};

sub emit {
    my ($output, $seen, $url) = @_;
    if ($url =~ m{\Ahttps?:}i) {
        my ($authority) = $url =~ m{\Ahttps?://([^/?#]+)}i;
        return unless defined $authority;
        $authority =~ s/.*\@//; # Ignore user info when checking the host.
        # Skip single-label hosts that often come from clipped terminal text.
        return unless $authority =~ m{
            \A (?: localhost | [\w-]+(?:\.[\w-]+)+\.? | $ipv6_literal )
            (?::\d+)? \z
        }ix;
    }
    print {$output} "$url\n" unless $seen->{$url}++;
}

sub is_osc8_uri {
    my ($uri) = @_;
    return $uri =~ m{\A(?:https?|ftp|file)://[^\s\x00-\x1f\x7f]+\z};
}

sub extract_urls {
    my ($input, $output) = @_;
    my %seen;

    while (my $line = <$input>) {
        # OSC 8 is ESC ] 8 ; params ; URI (BEL | ST). Parameters cannot contain
        # semicolons, but URI values can. An empty URI is the closing sequence.
        # Extract the target before removing terminal escapes below.
        while ($line =~ m{\e\]8;[^\a\e;]*;([^\a\e]*)(?:\a|\e\\)}gx) {
            emit($output, \%seen, $1) if is_osc8_uri($1);
        }

        $line =~ s/\e\[[0-9;?]*[a-zA-Z]//g;      # CSI: colors, cursor movement
        $line =~ s/\e\][^\a\e]*(?:\a|\e\\)?//g;  # OSC: hyperlinks, titles

        while (
            $line =~ m{
                (?<url>
                    (?:https?|ftp|file):/?//
                    (?:
                        (?: (?:[-\w+&%=:!,.;~|]*\@)? $ipv6_literal $url_tail_with_parens?
                          | $url_tail_with_parens
                        )
                        $url_char*
                      | $url_char+
                    )
                    # Exclude trailing prose punctuation, but keep matched pairs.
                    (?<=[-\w+&\@\#/%=~|)\]])
                )
              | (?:ssh://)?git\@(?<git_host>[^\s'"`:]+)[:/](?<git_path>[^\s'"`]+)
              | (?<www>$www_domain(?:/[^\s'"`]+)*)
              | (?<ip>$bare_ipv4(?::\d{1,5})?(?:/[^\s'"`]+)*)
            }gx
        ) {
            if    (defined $+{url})      { emit($output, \%seen, $+{url}) }
            elsif (defined $+{git_host}) { emit($output, \%seen, "https://$+{git_host}/$+{git_path}") }
            elsif (defined $+{www})      { emit($output, \%seen, "http://$+{www}") }
            elsif (defined $+{ip})       { emit($output, \%seen, "http://$+{ip}") }
        }
    }
}

sub capture_extraction {
    my ($text) = @_;
    open my $input, '<', \$text or die "Cannot open test input: $!";
    my $actual = '';
    open my $output, '>', \$actual or die "Cannot open test output: $!";
    extract_urls($input, $output);
    close $output or die "Cannot close test output: $!";
    return $actual;
}

sub self_test {
    require Test::More;

    my $long_url = 'https://example.com/' . ('a' x (70 * 1024));
    my @cases = (
        # Name, input, expected stdout
        ['empty input', '', ''],
        ['URL is not also matched as bare www',
            'https://www.example.com/path.md', "https://www.example.com/path.md\n"],
        ['localhost with port and path',
            'http://localhost:3000/docs', "http://localhost:3000/docs\n"],
        ['explicit IPv4 URL',
            'https://192.168.1.1:8080/', "https://192.168.1.1:8080/\n"],
        ['plain-text IPv6 URL with port',
            'http://[::1]:3000', "http://[::1]:3000\n"],
        ['plain-text IPv6 URL ending at the host',
            'See http://[2001:db8::1].', "http://[2001:db8::1]\n"],
        ['bare IPv4 does not rematch inside an IPv6 URL',
            'http://[::ffff:192.0.2.1]/docs', "http://[::ffff:192.0.2.1]/docs\n"],
        ['balanced parentheses in a URL path',
            'https://example.com/wiki/Foo_(bar)', "https://example.com/wiki/Foo_(bar)\n"],
        ['nested parentheses with surrounding punctuation',
            '(https://example.com/wiki/Foo_(bar(baz))).',
            "https://example.com/wiki/Foo_(bar(baz))\n"],
        ['ignore a surrounding closing parenthesis and period',
            '(https://example.com).', "https://example.com\n"],
        ['parenthetical prose is not part of the host',
            'https://example.com(note)', "https://example.com\n"],
        ['long URL is not truncated', "$long_url.", "$long_url\n"],
        ['explicit GitHub URL',
            'https://github.com/owner/repo/blob/main/docs/installation.md',
            "https://github.com/owner/repo/blob/main/docs/installation.md\n"],
        ['Git SSH remote becomes a web URL',
            'git@github.com:owner/repo.git', "https://github.com/owner/repo.git\n"],
        ['deduplicate a bare www domain and its explicit URL',
            "www.example.com\nhttp://www.example.com\n", "http://www.example.com\n"],
        ['bare www domain with a multi-part suffix',
            'www.example.co.uk/path', "http://www.example.co.uk/path\n"],
        ['bare IPv4 address with port',
            '10.0.0.1:8080', "http://10.0.0.1:8080\n"],
        ['bare IPv4 address before a full stop',
            'Listening on 10.0.0.1.', "http://10.0.0.1\n"],
        ['multiple URLs keep order and omit trailing punctuation',
            'See https://example.com/search?q=test#results, then http://example.org.',
            "https://example.com/search?q=test#results\nhttp://example.org\n"],

        ['skip clipped www in prose', 'ok   https://www not doubled', ''],
        ['skip clipped host', 'https://gith', ''],
        ['skip single-label intranet host', 'http://intranet:8080/docs', ''],
        ['skip single-label host with path', 'https://gith/path.md', ''],
        ['do not mistake user info for a hostname', 'https://user.name@gith', ''],
        ['skip single-label host with trailing dot', 'https://www./docs', ''],
        ['quoted local path is not a GitHub link', "'docs/installation.md'", ''],
        ['quoted repository shorthand is not a GitHub link', '"owner/repo"', ''],
        ['skip a version string with five parts', 'version 1.2.3.4.5', ''],
        ['skip an IPv4-like string with a long last part', '1.2.3.4567', ''],
        ['skip an IPv4-like string after a word', 'v1.2.3.4', ''],

        ['ANSI color codes are removed',
            "\e[32mhttps://example.com\e[0m", "https://example.com\n"],
        ['OSC 8 target with ST terminator',
            "\e]8;;https://example.com\e\\link text\e]8;;\e\\", "https://example.com\n"],
        ['skip OSC 8 target with clipped host', "\e]8;;https://gith\aignored\e]8;;\a", ''],
        ['OSC 8 IPv6 target with BEL terminator',
            "\e]8;;http://[::1]:3000\aopen\e]8;;\a", "http://[::1]:3000\n"],
    );

    for my $case (@cases) {
        my ($name, $input, $expected) = @$case;
        Test::More::is(capture_extraction($input), $expected, $name);
    }

    Test::More::done_testing();
}

if (@ARGV) {
    die "Usage: $0 [--self-test]\n" unless @ARGV == 1 && $ARGV[0] eq '--self-test';
    self_test();
}
else {
    extract_urls(\*STDIN, \*STDOUT);
}
