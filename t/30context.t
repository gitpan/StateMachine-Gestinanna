use StateMachine::Gestinanna;

package My::First::Machine;

our(%EDGES);

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
    state1 => {
        state11 => {
            required => [qw(a.d)],
        },
    },
);

package My::Second::Machine;

our(%EDGES);

@ISA=qw(StateMachine::Gestinanna);

%EDGES = (
    start => {
        state1 => {
            required => [qw(b.a)],
        },
        state2 => {
            required => [qw(a.a)],
        }
    }
);

package My::Third::Machine;

@ISA=qw(My::First::Machine My::Second::Machine);

package main;

my($sm, $sm2, $context, $message);

@TESTS = (
    sub {},

    sub {
        eval {
            $sm = My::Third::Machine -> new();
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

        return $sm -> state eq 'state2';
    },

    sub {
        $context = $sm -> context;

        $sm2 = My::Third::Machine -> new(
            context => $context
        );

        return $sm2 -> state eq 'state2';
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
