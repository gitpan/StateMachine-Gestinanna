use StateMachine::Gestinanna;

######

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

######

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

######

package My::Third::Machine;

@ISA=qw(My::First::Machine My::Second::Machine);

######

package My::Fourth::Machine;

our(@ISA, %EDGES);

@ISA=qw(My::First::Machine My::Second::Machine);

%EDGES = (
    _INHERIT => 'SUPER',
);

######

package My::Fifth::Machine;

our(@ISA, %HASA);

@ISA = qw(StateMachine::Gestinanna);

%HASA = (
    first => 'My::First::Machine',
    second => 'My::Second::Machine'
);

######

package main;

my($sm, $sm2, $sm3, $message);

our(@TESTS);

@TESTS = (
    sub { },

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
        eval {
            $sm2 = My::Fourth::Machine -> new();
        };
        $message = $@;
        return !$@;
    },

    sub {
        $sm2 -> state('start');

        $sm2 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        return $sm2 -> state eq 'state1';
    },

    sub {
        eval {
           $sm3 = My::Fifth::Machine -> new();
        };
        $message = $@;
        return !$@;
    },

    sub {
        $sm3 -> state('first_start');

        $sm3 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        return $sm3 -> state eq 'first_state1';
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
