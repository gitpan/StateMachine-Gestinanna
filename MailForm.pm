package StateMachine::Gestinanna::Examples::MailForm;

use StateMachine::Gestinanna;
use Net::SMTP;

use vars qw(@ISA %EDGES);

@ISA = qw(StateMachine::Gestinanna);

%EDGES = (
    showform => {
        submitform => {
            required => [qw(
                mail_from 
                mail_to 
                subject
            )],
            optional => [qw(
                env_fields
                smtp_host
            )],
            constraints => {
                mail_from => "email",
                mail_to   => "email",
            },
        }
    },
    submitform => {
        showform => {
            required => [qw(another)],
            constraints => {
                another => '/^yes$/',
            },
        },
    },
);

sub new {
    my $class = shift;

    my $self = $class -> SUPER::new(@_);

    return unless $self;

    # set start state
    $self -> state('showform') unless $self -> state;

    return $self;
}

sub showform_to_submitform {
    my $sm = shift;

    # check certain things, and then send the email
    # when this returns, email will have been sent, or an exception thrown
    # a lot of this code is borrowed from CGI::Application::Mailform
    my $params = $sm -> data("out");

    my $mailfrom = $params->{'mail_from'};
    my $mailto = $params->{'mail_to'};
    my $subject = $params->{'subject'};

    # Get the message body
    my $msgbody = $sm -> build_msgbody($params);

    # Connect to SMTP server
    my $smtp_connection = $sm -> connect_smtp($params);

    return $smtp_connection unless ref $smtp_connection;

    # Here's where we "do the deed"...
    $smtp_connection->mail($mailfrom);
    $smtp_connection->to($mailto);

    # Enter data mode
    $smtp_connection->data();

    # Send the message content (header + body)
    $smtp_connection->datasend("From: $mailfrom\n");
    $smtp_connection->datasend("To: $mailto\n");
    $smtp_connection->datasend("Subject: $subject\n");
    $smtp_connection->datasend("\n");
    $smtp_connection->datasend($msgbody);
    $smtp_connection->datasend("\n");

    # Exit data mode
    $smtp_connection->dataend();


    # Be polite -- disconnect from the server!
    $smtp_connection->quit();
    return;
}

# Establish SMTP connection
sub connect_smtp {
    my $self = shift;
    my $params = shift;

    my $smtp_host = $params -> {'smtp_host'};

    my $smtp_connection;

    if (length($smtp_host)) {
        # Use provided host
        $smtp_connection = Net::SMTP->new($smtp_host);
        if(!defined($smtp_connection)) {
            $sm -> add_data('error', {
                message => "Unable to connect to '$smtp_host'",
            });
            return 'error';
        }
    } else {
        # Use default host
        $smtp_connection = Net::SMTP->new();
        if(!defined($smtp_connection)) {
            $sm -> add_data('error', {
                message => "Unable to establish SMTP connection",
            });
            return 'error';
        }
    }

    return $smtp_connection;
}

# Here's where the majority of the work gets done.
# Based on the settings in the instance script and
# the CGI form data, an email message body is created.
sub build_msgbody {
    my $self = shift;
    my $params = shift;

    # The longest journey begins with a single step...
    my $msgbody = '';

    ## Populate message body with form data
    #
    my @form_fields = keys %$params;
    my $ff_count = 1;
    $msgbody .= "The following data has been submitted:\n\n";
    foreach my $field (@form_fields) {
        next if $field =~ m{^(s(mtp_host|ubject)|mail_(from|to)|env_fields)$};
        $msgbody .= "$ff_count\. $field\:\n" . $self->clean_data($params -> {$field}). "\n\n\n";
        $ff_count++;
    }
    $msgbody .= "\n";

    ## Populate message body with environment data
    #
    my $env_fields = $params -> {'env_fields'};
    # Do we actually have any env data requested?
    if (@$env_fields) {
        my $ef_count = 1;
        $msgbody .= "Form environment data:\n\n";
        foreach my $field (@$env_fields) {
            $msgbody .= "$ef_count\. $field\:\n" . $self->clean_data($ENV{$field}). "\n\n\n";
            $ef_count++;
        }
    }

    # Send back the complete message body
    return $msgbody;
}

# This method cleans up data for inclusion into the email message
sub clean_data {
    my $self = shift;
    my $field_data = shift;

    # Set undef strings to a null string
    $field_data = '' unless (defined($field_data));

    # Strip leading & trailing white space
    $field_data =~ s/^\s*//;
    $field_data =~ s/\s$//;

    # If we have no answer, put "[n/a]" in there.
    $field_data = '[n/a]' unless (length($field_data));

    return $field_data;
}

1;

__END__

=head1 NAME

StateMachine::Gestinanna::Examples::MailForm - example mail form state machine

=head1 SYNOPSIS

 package My::MailForm;

 use base qw/StateMachine::Gestinanna::Examples::MailForm/;

 our %EDGES = (
     showform => {
         submitform => {
             required => [qw(
                 name
                 message
             )],
             overrides => {
                 smtp_host => 'localhost',
                 mail_to => 'me@localhost',
                 env_fields => [qw(REMOTE_HOST)],
                 mail_from => 'you@localhost',
             },
         },
     },
 );

 1;
 __END__

In an HTML::Mason component (for example):

 <%once>
     use My::MailForm;
 </%once>
 <%init>
     # assume session info is set up for us

     # instantiate & initialize state machine object
     my $sm = My::MailForm -> new($session -> {context});

     # go to next state
     $sm -> process(%ARGS);

     my $view = $sm -> state;
     my $viewdata = {
          in    => $sm -> data('in'),
          out   => $sm -> data('out'),
          error => $sm -> data('error'),
     },

     # save for next go-around
     $session -> {context} = $sm -> context;
 </%init>
 %# possible states: showform, submitform, error
 <& "views/$view", %$viewdata &>

=head1 DESCRIPTION

This example state machine reproduces much of the example 
L<CGI::Application::Mailform|CGI::Application::Mailform>.
Instead of initializing the object with parameters, however, you 
may make them part of the state machine definition as overrides.
This has the added benefit of allowing any or all of them to be 
specified in the form being submitted.

Any information submitted in the form that is not one of the four 
variables (C<env_fields>, C<mail_from>, C<mail_to>, and C<smtp_host>) 
and is allowed by the validation will be sent to the C<mail_to> 
address as an email.  In addition, any environment variables listed 
in C<env_fields> will also be sent.

The four variables mentioned above are required for the state 
machine to transit to the C<submitform> state (actually, C<env_fields> 
and C<smtp_host> are optional).  The C<mail_to> and 
C<mail_from> variables must appear to be e-mail addresses.

E-mail is only sent if the C<smtp_host> is available and the transition 
is made to the C<submitform> state from the C<showform> state.  
Once the transition is finished (and the C<process> method has 
returned), the e-mail has been sent or an error has been reported.

=head1 SEE ALSO

L<CGI::Application::Mailform>,
L<StateMachine::Gestinanna>.

=head1 AUTHOR

James G. Smith, <jsmith@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2002  Texas A&M University.  All rights reserved.
