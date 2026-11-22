#!/usr/bin/env perl
# Reads plain pane text on stdin and prints path candidates in capture order,
# one per line, as PATH or PATH<TAB>LINE. It never touches the file system:
# the caller resolves paths, removes repeats, and checks for regular text files.
# Escape sequences, including terminal hyperlinks, are not handled.
# Run the built-in tests with: perl rex/extract-paths.pl --self-test
#
# Each row is scanned once, left to right. At each position a URL of any
# scheme is tried first, then a plain path:
#   - A URL is consumed whole, so no plain path matches inside it. Only a
#     local file:// URL is kept, and it is decoded to an absolute path.
#   - A plain path contains a slash. Bare names are ignored. A path starts
#     at the start of the row or after whitespace, an opener, =, a box-drawing
#     character, or a literal \n in printed output. Plain paths are ASCII
#     and may end with :LINE.
# A match that follows an opener whose closer is not on the row is cut, and a
# match with $ in or after it is templated; both are skipped.
use strict;
use warnings;

# URLs, as in extract-urls.pl but with any scheme. Non-ASCII ends a URL.
my $url_char = qr{[^\x80-\xff\s"'`<>\\()\[\]\{\}]};
# Try each run of scheme characters only once, even when :// is absent.
my $url = qr{(?<![A-Za-z0-9+.\-])[A-Za-z][A-Za-z0-9+.\-]*+://(?:$url_char++|\($url_char*+\)|\[$url_char*+\])*+};

my $seg = qr{[A-Za-z0-9._\-+@%]++};
my $box = qr{\xe2[\x94\x95][\x80-\xbf]};
# The path must not run into a URL scheme, a directory slash, a variable, or
# non-ASCII text other than a box-drawing border.
my $path = qr{
    (?:^|(?<=[\s(\[\{<"'`=])|(?<=$box)|(?<=\\n))
    ((?:~|$seg)?(?:/++$seg)++)
    (?!://|[/\$]|(?!$box)[\x80-\xff])
    (?::0*+([1-9][0-9]*+)(?![A-Za-z0-9_]))?
}x;
my $token = qr{($url)|$path};

my %closer = ("(" => ")", "[" => "]", "{" => "}", "<" => ">", '"' => '"', "'" => "'", "`" => "`");

# Returns the decoded absolute path of a local file:// URL, or undef.
sub file_url_path {
    my ($host, $path) = $_[0] =~ m{\A(?i:file)://([^/?#]*)(/[^?#]*)} or return;
    return if ($host ne '' && lc $host ne 'localhost') || $path =~ /%(?![0-9A-Fa-f]{2})/;
    $path =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
    return if $path =~ /[\x00-\x1f\x7f]/ || !utf8::decode(my $copy = $path);
    return $path;
}

sub extract_paths {
    my ($input, $output) = @_;
    while (my $row = <$input>) {
        chomp $row;
        while ($row =~ /$token/g) {
            my ($url, $path, $line) = ($1, $2, $3);
            my $closer = $-[0] && $closer{substr $row, $-[0] - 1, 1};
            next if $closer && index($row, $closer, $+[0]) < 0;
            if (defined $url) {
                next if $url =~ /\$/;
                $url =~ s/[,.?!;:]+\z//;
                $path = file_url_path($url) // next;
            }
            else {
                $path =~ s/\.+\z//;
            }
            next if $path =~ m{/\z};
            print {$output} $path, (defined $line ? "\t$line" : ''), "\n";
        }
    }
}

sub run_extract {
    my ($text) = @_;
    open my $input, '<', \$text or die "Cannot open test input: $!";
    open my $output, '>', \my $actual or die "Cannot open test output: $!";
    extract_paths($input, $output);
    close $output or die "Cannot close test output: $!";
    return $actual // '';
}

sub self_test {
    require Test::More;
    require File::Temp;
    my $bar = "\x{e2}\x{94}\x{82}";
    my @cases = (
        # Name, input, expected stdout
        ["empty input",
            "",
            ""],
        ["long token without a URL scheme separator",
            ("A" x 130_000) . " file:///tmp/a.txt",
            "/tmp/a.txt\n"],
        # Plain paths
        ["rg output",
            "rex/init.lua:12:require",
            "rex/init.lua\t12\n"],
        ["two line references to one file",
            "rex/a.lua:3:x\nrex/a.lua:9:y",
            "rex/a.lua\t3\nrex/a.lua\t9\n"],
        ["absolute, ./, ../, and ~/ paths",
            "/etc/zshrc.local ./a/b.md ../c.txt ~/notes/todo.md",
            "/etc/zshrc.local\n./a/b.md\n../c.txt\n~/notes/todo.md\n"],
        ["ignore bare names, including names with dots or line numbers",
            "make: *** [Makefile:12: all] Error README.md",
            ""],
        ["relative path with an explicit ./",
            "make: *** [./Makefile:12: all] Error",
            "./Makefile\t12\n"],
        ["names are not filtered by extension",
            "/etc/hosts src/Makefile lib/libfoo.so.1 img/logo.PNG ~/.zshrc",
            "/etc/hosts\nsrc/Makefile\nlib/libfoo.so.1\nimg/logo.PNG\n~/.zshrc\n"],
        ["column after the line",
            "src/main.rs:12:5:",
            "src/main.rs\t12\n"],
        ["zero line",
            "src/main.rs:0",
            "src/main.rs\n"],
        ["leading zeros",
            "src/main.rs:007",
            "src/main.rs\t7\n"],
        ["line followed by letters is not a line",
            "src/main.rs:12abc",
            "src/main.rs\n"],
        ["trailing periods",
            "docs/guide.md. ... ./Makefile.",
            "docs/guide.md\n./Makefile\n"],
        ["path after =",
            "--config=etc/app.toml",
            "etc/app.toml\n"],
        ["paths after literal newline escapes in printed output",
            'output:\nrex/init.lua\nscripts/sync-rex-docs.py\n',
            "rex/init.lua\nscripts/sync-rex-docs.py\n"],
        ["path after a box-drawing border",
            "${bar}src/a.lua:4${bar}",
            "src/a.lua\t4\n"],
        ["paths in closed openers",
            "(src/a.lua) \"src/b.lua:2\" [src/c.lua]",
            "src/a.lua\nsrc/b.lua\t2\nsrc/c.lua\n"],
        ["repeated slashes",
            "src//a.lua",
            "src//a.lua\n"],
        ["several references on one row keep their order",
            "x/1.md /y/2.md:3 file:///z/3.md ~/4.md",
            "x/1.md\n/y/2.md\t3\n/z/3.md\n~/4.md\n"],
        # Rejected matches
        ["trailing slash",
            "src/dir.d/ dir/",
            ""],
        ["variables",
            "\$HOME/a.lua src/a.lua\$x src/a\$b/c.lua",
            ""],
        ["unclosed quote",
            "\"src/a.lua",
            ""],
        ["non-ASCII text is not a boundary",
            "\x{c3}\x{a9}src/a.lua \x{e2}\x{86}\x{92}src/b.lua",
            ""],
        ["path cut by non-ASCII text",
            "docs/caf\x{c3}\x{a9}.md",
            ""],
        ["no start inside a word or after a colon",
            "a.lua:src/b.lua x.md~/c.md",
            ""],
        ["inside web URLs",
            "https://example.com/docs/guide.md (https://example.com/a/b.html)",
            ""],
        ["inside other-scheme URLs",
            "ssh://host/srv/a.conf s3://bucket/key/data.json",
            ""],
        ["path-like prefix of a URL",
            "src/a.https://example.org/b x/y.md+git://h/c.md",
            ""],
        # file:// URLs
        ["file URL with an empty host",
            "file:///etc/zprofile.d/a.sh",
            "/etc/zprofile.d/a.sh\n"],
        ["file URL with localhost",
            "file://localhost/tmp/a.txt.",
            "/tmp/a.txt\n"],
        ["case-insensitive file scheme",
            "FILE:///tmp/a.txt FiLe://LOCALHOST/tmp/b.txt",
            "/tmp/a.txt\n/tmp/b.txt\n"],
        ["preserve a percent-encoded trailing period",
            "file:///tmp/a%2E.",
            "/tmp/a.\n"],
        ["percent-encoded spaces",
            "file:///Users/me/My%20Notes/a%20b.md",
            "/Users/me/My Notes/a b.md\n"],
        ["%23 and fragments",
            "file:///tmp/issue%23.md file:///tmp/a.md#L12 file:///tmp/b.md?x=1",
            "/tmp/issue#.md\n/tmp/a.md\n/tmp/b.md\n"],
        ["nonlocal host",
            "file://server/share/a.txt",
            ""],
        ["malformed escape",
            "file:///tmp/a%2.txt file:///tmp/%zz.txt",
            ""],
        ["decoded control character",
            "file:///tmp/a%0A.txt file:///tmp/a%09.txt",
            ""],
        ["missing path or directory",
            "file:// file://localhost file:///tmp/",
            ""],
        ["invalid UTF-8",
            "file:///tmp/%ff.txt",
            ""],
        ["cut or templated URL",
            "(file:///tmp/a.txt \"file:///tmp/b.txt file:///\$TMP/c.txt",
            ""],
        ["file URL and path keep capture order",
            "src/a.lua file:///tmp/b.txt src/c.lua:3",
            "src/a.lua\n/tmp/b.txt\nsrc/c.lua\t3\n"],
    );
    Test::More::is(run_extract($_->[1]), $_->[2], $_->[0]) for @cases;

    # The output must not depend on whether the referenced file exists.
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $text = "$dir/missing.txt:4 file://$dir/missing.txt\n";
    my $expected = "$dir/missing.txt\t4\n$dir/missing.txt\n";
    Test::More::is(run_extract($text), $expected, "missing file is still reported");
    open my $fh, '>', "$dir/missing.txt" or die "Cannot create test file: $!";
    close $fh;
    Test::More::is(run_extract($text), $expected, "existing file gives the same output");

    Test::More::done_testing();
}

if (@ARGV) {
    die "Usage: $0 [--self-test]\n" unless @ARGV == 1 && $ARGV[0] eq '--self-test';
    self_test();
}
else {
    extract_paths(\*STDIN, \*STDOUT);
}
