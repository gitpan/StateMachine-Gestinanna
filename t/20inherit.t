use StateMachine::Gestinanna;

######

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

######

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

######

package My::Third::Machine;

@ISA=qw(My::First::Machine My::Second::Machine);

######

package My::Fourth::Machine;

@ISA=qw(My::First::Machine My::Second::Machine);

%EDGES = (
    _INHERIT => 'SUPER',
);

######

package My::Fifth::Machine;

@ISA = qw(StateMachine::Gestinanna);

%HASA = (
    first => 'My::First::Machine',
    second => 'My::Second::Machine'
);

######

package main;

print "1..6\n";

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
    print "ok 2\n";
} else {
    print "not ok 2\n";
    print STDERR "state: ", $sm -> state, "\n";
}

my $sm2;
eval {
$sm2 = My::Fourth::Machine -> new();
};

if($@) {
    print "not ok 3\n";
    print STDERR "$@\n";
} else {
    print "ok 3\n";
}

$sm2 -> state('start');

$sm2 -> process({
    'a.a' => 'a',
    'a.b' => 'b',
});

if($sm2 -> state eq 'state1') {
    print "ok 4\n";
} else {
    print "not ok 4\n";
}

my $sm3;

eval {
   $sm3 = My::Fifth::Machine -> new();
};

if($@) {
    print "not ok 5\n";
    print STDERR "$@\n";
} else {
    print "ok 5\n";
}

$sm3 -> state('first_start');

$sm3 -> process({
    'a.a' => 'a',
    'a.b' => 'b',
});

if($sm3 -> state eq 'first_state1') {
    print "ok 6\n";
} else {
    print "not ok 6\n";
}

exit 0;