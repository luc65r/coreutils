use Test;

sub test(IO::Path:D $program where * ~~ :f & :x) is export {
    my $p = run $program, :out, :err;
    ok $p.exitcode == 0, "exitcode";
    ok $p.out.slurp(:close) eq "Hello, world!\n", "stdout";
    ok $p.err.slurp(:close) eq "", "stderr";
}
