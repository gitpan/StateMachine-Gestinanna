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

print "1..2\n";

my $sm = My::Machine -> new();


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

if($sm -> state eq 'state1') {
    print "ok\n";
} else {
    print "not ok\n";
    print STDERR "state: ", $sm -> state, "\n";
}

exit 0;
