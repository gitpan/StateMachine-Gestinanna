@TESTS = (
    sub {},

    sub {
        eval {
            require StateMachine::Gestinanna;
        };

        return !$@;
    }
);

print "1..", $#TESTS, "\n";

my $r;

for my $i (1..$#TESTS) {
    $r = undef;

    eval { $r = $TESTS[$i] -> (); };
    if($r) {
        print "ok $i\n";
    }
    else {
        if($ENV{DEBUG}) {
            $message = undef;
            warn "\n--- DEBUG for test $i\n";
            local($StateMachine::Gestinanna::DEBUG) = 1;
            local($StateMachine::Gestinanna::CC::DEBUG) = 1;
            eval {
                $TESTS[$i] -> ();
            };
            print STDERR "$message\n" if defined $message;
            warn "--- END DEBUG for test $i\n";
        }
        print "not ok $i\n";
    }
}

exit 0;
