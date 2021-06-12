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
        build => -> $program {
            my $object = $program.build-dir.add: $program.name ~ ".o";
            run("as", "--64", "-march=generic64", "-o", $object, $program.source);
            run("ld", "-o", $program.output, $object);
        }
    ),
    Language.new(
        name => "nasm assembly",
        extensions => <asm>,
        build => -> $program {
            run("nasm", "-f", "bin", "-o", $program.output, $program.source);
        }
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
    has IO::Path:D $.build-dir is required where * ~~ :d & :w;
    has IO::Path:D $.source is required where * ~~ :f & :r;
    has IO::Path:D $.output is required;
    has Language:D $.lang is required;

    method new(IO::Path:D $source where * ~~ :f & :r) {
        my $extension = $source.extension;
        my $name = $source.extension('').basename;
        my $build-dir = "build".IO;
        self.bless(
            :$build-dir,
            :$name,
            :$source,
            output => $build-dir.add($name),
            lang => @languages.first($extension ∈ *.extensions),
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
