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
    return;
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
    return;
}

sub pre_state11 {
    $main::pre_state11 = 1;
    return;
}

######

package My::Fifth::Machine;

@ISA = qw(StateMachine::Gestinanna);

%HASA = (
    first => 'My::First::Machine',
    second => 'My::Second::Machine'
);

######

package My::Sixth::Machine;

@ISA = qw(My::Fifth::Machine);

######
## TESTS appear below
######

package main;


my($sm2, $sm3, $sm4, $message);

@TESTS = (
    sub { },  # does nothing except let us start at 1

    sub {  # 1
        $sm2;
        eval {
            $sm2 = My::Fourth::Machine -> new();
        };

        $message = $@;
        return !$@;
    },

    sub {  # 2
        $state_to_state1 = 0;

        $sm2 -> state('start');

        $sm2 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        return $sm2 -> state eq 'state1';
    },

    sub {  # 3
        $state_to_state1 = 0;
          
        $sm2 -> state('start');
        
        $sm2 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        return $state_to_state1;
    },

    sub {  # 4
        $pre_state11 = 0;
        $post_state1 = 0;

        $sm2 -> state('start');

        $sm2 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        $sm2 -> process({
            'a.d' => 'a'
        });

        return $sm2 -> state eq 'state11';
    },

    sub {  # 5
        $pre_state11 = 0;
        $post_state1 = 0;

        $sm2 -> state('start');

        $sm2 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        $sm2 -> process({
            'a.d' => 'a'
        });

        return $pre_state11;
    },

    sub {  # 6
        $pre_state11 = 0;
        $post_state1 = 0;

        $sm2 -> state('start');

        $sm2 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        $sm2 -> process({
            'a.d' => 'a'
        });

        return $post_state1;
    },

    sub {  # 7
        eval {
           $sm3 = My::Fifth::Machine -> new();
        };
          
        $message = $@;
        return !$@;
    },

    sub {  # 8
        $sm3 -> state('first_start');

        $pre_state11 = 0;
        $post_state1 = 0;
        $state_to_state1 = 0;

        $sm3 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });   

        return $sm3 -> state eq 'first_state1';
    },

    sub {  # 9
        $sm3 -> state('first_start');

        $pre_state11 = 0;
        $post_state1 = 0;
        $state_to_state1 = 0;
            
        $sm3 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        return $state_to_state1;
    },

    sub {  # 10
        eval {
           $sm4 = My::Sixth::Machine -> new();
        };

        $message = $@;
        return !$@;
    },
    
    sub {  # 11
        $sm4 -> state('first_start');
 
        $pre_state11 = 0;
        $post_state1 = 0;
        $state_to_state1 = 0;

        $sm4 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });
    
        return $sm4 -> state eq 'first_state1';
    },

    sub {  # 12
        $sm4 -> state('first_start');
  
        $pre_state11 = 0;
        $post_state1 = 0;
        $state_to_state1 = 0;

        $sm4 -> process({
            'a.a' => 'a',
            'a.b' => 'b',
        });

        return $state_to_state1;
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
