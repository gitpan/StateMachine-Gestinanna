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

sub start_to_state1 {
    $main::state_to_state1 = 1;
}

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

package My::Fourth::Machine;

@ISA=qw(My::First::Machine My::Second::Machine);

%EDGES = (
    _INHERIT => 'SUPER',
);

sub post_state1 {
    $main::post_state1 = 1;
}

sub pre_state11 {
    $main::pre_state11 = 1;
}

package main;

print "1..6\n";

my $sm2;
eval {
$sm2 = My::Fourth::Machine -> new();
};

if($@) {
    print "not ok 1\n";
    print STDERR "$@\n";
} else {
    print "ok 1\n";
}

$state_to_state1 = 0;

$sm2 -> state('start');

$sm2 -> process({
    'a.a' => 'a',
    'a.b' => 'b',
});

if($sm2 -> state eq 'state1') {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

if($state_to_state1) {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}

$pre_state11 = 0;
$post_state1 = 0;

$sm2 -> process({
    'a.d' => 'a'
});

if($sm2 -> state eq 'state11') {
    print "ok 4\n";
} else {
    print "not ok 4\n";
}

if($pre_state11) {
    print "ok 5\n";
} else {
    print "not ok 5\n";
}

if($post_state1) {
    print "ok 6\n";
} else {
    print "not ok 6\n";
}

exit 0;
