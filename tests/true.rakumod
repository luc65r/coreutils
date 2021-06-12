use Test;

sub test(IO::Path:D $program where * ~~ :f & :x) is export {
    my $p = run $program, :out, :err;
    is $p.exitcode, 0, "exitcode";
    is $p.out.slurp(:close), "", "stdout";
    is $p.err.slurp(:close), "", "stderr";
}
