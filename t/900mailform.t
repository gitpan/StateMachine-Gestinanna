package My::MailForm;

use vars qw(@ISA %EDGES);
use strict;

@ISA = qw(StateMachine::Gestinanna::Examples::MailForm);

%EDGES = (
    showform => {
        submitform => {    
            required => [qw(
                test_string
                pid
            )],
            overrides => {
                subject => 'Test email for MailForm state machine',
            },
        },
    },
);

package main;
my($sm, $message);
use vars qw(@TESTS);

@TESTS = (
    sub {},
    sub {
        eval {
            require StateMachine::Gestinanna::Examples::MailForm;
        };

        $message = $@;

        return !$@;
    },

    sub {
        eval {
            $sm = new My::MailForm;
        };

        $message = $@;
        return !$@;
    },

### TODO: need to prompt for smtp server, mail_from, and mail_to for testing
###       need to email with a test subject, etc.
###       or get it from the $ENV.
### (this is actually used during development, but commented out for distribution)
#    sub {
#        my($mailfrom, $mailto, $smtphost) = qw(user@some.dom user@some.dom smtp-relay.some.dom);
#
#        $sm -> process({
#            mail_from => $mailfrom,
#            mail_to => $mailto,
#            test_string => qq{
#This email is testing the StateMachine::Gestinanna::Examples::MailForm 
#module.  Please disregard it.  See the documentation for more information.
#            },
#            pid => $$,
#        });
#
#        return $sm -> state eq 'submitform';
#    },
);

eval { require Net::SMTP; };

@TESTS = ( ) if $@;

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
            local($StateMachine::Gestinanna::Examples::MailForm::DEBUG) = 1;
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
