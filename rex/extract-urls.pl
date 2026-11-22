#!/usr/bin/env perl
# Reads pane text on stdin and prints every URL occurrence in capture order,
# one per line. The caller orders and deduplicates them.
# Run the built-in tests with: perl rex/extract-urls.pl --self-test
#
# Each row is handled on its own:
#   1. Print any OSC 8 hyperlink targets. Replace cursor-forward gaps with a
#      space, then remove the remaining escape sequences.
#   2. Match a scheme (http, https, file) followed by runs of URL
#      characters or complete, non-nested groups in parentheses or brackets.
#      Raw braces are delimiters.
#   3. Remove trailing punctuation (,.?!;:).
# A URL split across rows by a real newline is not joined.
use strict;
use warnings;

my $scheme_prefix = qr{(?:https?|file)://};
# Only ASCII. Any non-ASCII byte, such as a box-drawing border, a dash, or a
# non-breaking space, ends the URL.
my $url_char = qr{[^\x80-\xff\s"'`<>\\()\[\]\{\}]};

# Match runs of ordinary characters to avoid Perl's repeat limit.
my $url_re = qr{($scheme_prefix(?:$url_char++|\($url_char*+\)|\[$url_char*+\])+)};

# OSC 8 is ESC ] 8 ; params ; URI (BEL | ST).
my $osc8_link = qr{\e\]8;[^\a\e;]*;($scheme_prefix[^\s\x00-\x1f\x7f]+?)(?:\a|\e\\)};
# Rex's VT capture writes skipped blank cells as CSI n C (cursor forward).
my $cursor_forward = qr{\e\[\d*C};
# The capture is re-rendered from the screen, so only CSI and OSC sequences
# appear. Carriage returns are whitespace and already end a URL.
my $terminal_escape = qr{\e\][^\a\e]*(?:\a|\e\\)?|\e\[[0-?]*[ -\/]*[@-~]};

sub extract_urls {
    my ($input, $output) = @_;
    while (my $row = <$input>) {
        print {$output} "$1\n" while $row =~ m{$osc8_link}g;
        $row =~ s{$cursor_forward}{ }g;
        $row =~ s{$terminal_escape}{}g;

        while ($row =~ /$url_re/g) {
            my $url = $1;
            $url =~ s/[,.?!;:]+\z//;
            print {$output} "$url\n";
        }
    }
}

sub self_test {
    require Test::More;
    my @cases = (
        # Name, input, expected stdout
        ["empty input",
            "",
            ""],
        ["plain URL",
            "see https://example.com/a?b=c#d",
            "https://example.com/a?b=c#d\n"],
        ["several URLs keep order and drop trailing punctuation",
            "https://example.com/a, then http://example.org.",
            "https://example.com/a\nhttp://example.org\n"],
        ["stop before a shell command separator",
            "curl https://example.com/a; echo done",
            "https://example.com/a\n"],
        ["drop a trailing prose colon",
            "See https://example.com/a:",
            "https://example.com/a\n"],
        ["repeats are printed in capture order",
            "https://example.org/new\nhttps://example.org/old https://example.org/new",
            "https://example.org/new\nhttps://example.org/old\nhttps://example.org/new\n"],
        ["stop at a closing quote",
            "url=\"https://example.com/a\" x",
            "https://example.com/a\n"],
        ["stop at a closing parenthesis",
            "(https://example.com/a).",
            "https://example.com/a\n"],
        ["stop at a closing bracket",
            "[https://example.com/a]",
            "https://example.com/a\n"],
        ["stop at either raw brace",
            "{https://example.com/a} https://example.com/b{suffix} https://example.com/c}suffix",
            "https://example.com/a\nhttps://example.com/b\nhttps://example.com/c\n"],
        ["keep percent-encoded braces",
            "https://example.com/%7Ba%7D",
            "https://example.com/%7Ba%7D\n"],
        ["no opener keeps parentheses",
            "https://example.com/wiki/Foo_(bar)",
            "https://example.com/wiki/Foo_(bar)\n"],
        ["keep balanced parentheses inside a wrapped URL",
            "(https://example.com/wiki/Foo_(bar)).",
            "https://example.com/wiki/Foo_(bar)\n"],
        ["IPv6 host",
            "http://[::1]:3000/docs",
            "http://[::1]:3000/docs\n"],
        ["keep IPv6 brackets inside a wrapped URL",
            "[http://[::1]:3000/docs]",
            "http://[::1]:3000/docs\n"],
        ["extract both adjacent Markdown links",
            "[one](https://example.com/a)[two](https://example.org/b)",
            "https://example.com/a\nhttps://example.org/b\n"],
        ["stop at a box-drawing border",
            "\x{e2}\x{94}\x{82}https://example.com/a\x{e2}\x{94}\x{82}",
            "https://example.com/a\n"],
        ["stop at a non-ASCII letter",
            "https://example.com/caf\x{c3}\x{a9}",
            "https://example.com/caf\n"],
        ["long URL is not truncated",
            "https://example.com/" . ("a" x 70_000),
            "https://example.com/" . ("a" x 70_000) . "\n"],
        ["no scheme, no link",
            "www.example.com git\@github.com:o/r.git 10.0.0.1:80",
            ""],
        ["a cursor-forward gap separates words",
            "https://example.com/a\e[5Cnext",
            "https://example.com/a\n"],
        ["ANSI color codes are removed",
            "\e[32mhttps://example.com\e[0m",
            "https://example.com\n"],
        ["OSC 8 target comes before visible text",
            "https://example.org/a \e]8;;https://example.org/b\alink\e]8;;\e\\",
            "https://example.org/b\nhttps://example.org/a\n"],
    );
    for my $case (@cases) {
        my ($name, $text, $expected) = @$case;
        open my $input, '<', \$text or die "Cannot open test input: $!";
        my $actual = '';
        open my $output, '>', \$actual or die "Cannot open test output: $!";
        extract_urls($input, $output);
        close $output or die "Cannot close test output: $!";
        Test::More::is($actual, $expected, $name);
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
