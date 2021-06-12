use Test;

sub tmp-file(--> IO::Path:D) {
    my $rand = ("a".."z", "A".."Z", 0..9).flat.roll(8).join;
    IO::Spec::Unix.tmpdir.add($rand)
}

sub rand-uint8(--> uint8) {
    (0..255).roll
}

sub test(IO::Path:D $program where * ~~ :f & :x) is export {
    subtest "empty input" => {
        my $p = run $program, :in, :out, :err;
        $p.in.spurt: "", :close;
        is $p.exitcode, 0, "exitcode";
        is $p.out.slurp(:close), "", "stdout";
        is $p.err.slurp(:close), "", "stderr";
    }

    subtest "small input" => {
        my $input = "this is\na small input\n";
        my $p = run $program, :in, :out, :err;
        $p.in.spurt: $input, :close;
        is $p.exitcode, 0, "exitcode";
        is $p.out.slurp(:close), $input, "stdout";
        is $p.err.slurp(:close), "", "stderr";
    }

    subtest "multiple inputs" => {
        my @fs = tmp-file.open(:x, :bin) xx 2;
        LEAVE .path.unlink for @fs;
        my @is = buf8.new(rand-uint8() xx 100) xx 2;
        for @fs.kv -> $i, $f {
            $f.spurt: @is[$i];
        }

        my $input = buf8.new(rand-uint8() xx 100);

        my $p = run $program, @fs[0], "-", @fs[1], :in, :out, :err, :bin;
        $p.in.spurt: $input, :close;
        is $p.exitcode, 0, "exitcode";
        is $p.out.slurp(:close), @is[0] ~ $input ~ @is[1], "stdout";
        is $p.err.slurp(:close), buf8.new, "stderr";
    }
}
