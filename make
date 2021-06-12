#!/usr/bin/env raku

use v6.d;

enum Action <build run test bench>;

class Language {
    has Str:D $.name is required;
    has Str:D @.extensions is required;
    has &.build = -> $, $ {
        die "Building $!name is not yet implemented";
    };
}

my @languages = [
    Language.new(
        name => "C",
        extensions => <c>,
        build => -> $input, $output {
            run("cc", "-o", $output, "-O", "-g",
                "-Wall", "-Wextra", "-Wpedantic", "-Wconversion",
                "-std=c99", $input);
        }
    ),
    Language.new(
        name => "Zig",
        extensions => <zig>,
        build => -> $input, $output {
            run("zig", "build-exe", "-femit-bin=$output", $input);
        }
    ),
    Language.new(
        name => "GNU assembly",
        extensions => <s>,
    ),
    Language.new(
        name => "nasm assembly",
        extensions => <asm>,
    ),
    Language.new(
        name => "raku",
        extensions => <raku>,
        build => -> $input, $output {
            my $buf = $input.slurp: :bin;
            $buf.prepend: "#!/usr/bin/env raku\n\n".encode;
            $output.spurt: $buf;
            $output.chmod: 0o755;
        }
    ),
];

class Program {
    has Str:D $.name is required;
    has IO::Path:D $.source is required;
    has IO::Path:D $.output is required;
    has Language:D $.lang is required;

    method new(IO::Path:D $source where * ~~ :f & :r) {
        my $extension = $source.extension;
        my $name = $source.extension('').basename;
        self.bless(
            :$name,
            :$source,
            output => "build/$name".IO,
            lang => @languages.first: { $extension ∈ .extensions },
        )
    }

    method build() {
        $.lang.build.($.source, $.output);
    }
}

sub MAIN(
    Action:D $action, #= build, run, test or bench
    Str:D $file where .IO ~~ :f & :r, #= the source file
) {
    my $program = Program.new: $file.IO;
    given $action {
        when build {
            $program.build;
        }

        when test {
            $program.build;

            use lib "tests";
            require ::($program.name) <&test>;
            test($program.output);
        }

        default {
            die "$action is not yet implemented";
        }
    }
}
