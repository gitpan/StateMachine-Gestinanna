use StateMachine::Gestinanna;

package My::First::Machine;

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

print "1..3\n";

my $sm;

eval {
$sm = My::Third::Machine -> new();
};

if($@) {
    print "not ok 1\n";
} else {
    print "ok 1\n";
}

$sm -> state('start');

$sm -> process({
    'a.a' => 'a',
    'a.b' => 'b',
});

if($sm -> state eq 'state2') {
    print "ok\n";
} else {
    print "not ok\n";
    print STDERR "state: ", $sm -> state, "\n";
}

my $context = $sm -> context;

my $sm2 = My::Third::Machine -> new(
    context => $context
);

if($sm2 -> state eq 'state2') {
    print "ok\n";
} else {
    print "not ok\n";
    print STDERR "state: ", $sm2 -> state, "\n";
}


exit 0;
