use StateMachine::Gestinanna;

package My::Machine;

@ISA=qw(StateMachine::Gestinanna);

%EDGES = (
    start => {
        state1 => {
            required => [qw(a.a a.b)],
        },
        state2 => {
            required => [qw(a.b)],
        },
        state3 => {
            required => [qw(a.c)],
        },
    },
    start1 => {
        state11 => {
            required => [qw(a.d)],
        },
    },
);

package main;


my($sm, $message);

@TESTS = (
    sub {},

    sub {
        eval {
            $sm = My::Machine -> new();
        };

        $message = $@;
        return !$@;
    },

    sub {
        $sm -> state('start');

        $sm -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        return $sm -> state eq 'state1';
    },
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
