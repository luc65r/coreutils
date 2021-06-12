#!/usr/bin/env raku

use v6.d;

enum Action <build run test bench>;

class Language {
    has Str:D $.name is required;
    has Str:D @.extensions is required;
    has &.build = -> $ {
        die "Building $!name is not yet implemented";
    };
}

my @languages = [
    Language.new(
        name => "C",
        extensions => <c>,
        build => -> $program {
            run("cc", "-o", $program.output, "-O", "-g",
                "-Wall", "-Wextra", "-Wpedantic", "-Wconversion",
                "-std=c99", $program.source);
        }
    ),
    Language.new(
        name => "Zig",
        extensions => <zig>,
        build => -> $program {
            run("zig", "build-exe", "-femit-bin=" ~ $program.output, $program.source);
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
        build => -> $program {
            my $buf = $program.source.slurp: :bin;
            $buf.prepend: "#!/usr/bin/env raku\n\n".encode;
            $program.output.spurt: $buf;
            $program.output.chmod: 0o755;
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
        $.lang.build.(self);
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
