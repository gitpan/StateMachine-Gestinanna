package StateMachine::Gestinanna;

use Data::FormValidator ();
#use Data::Dumper;  # here for testing/development - comment out for release
use YAML ();

$VERSION = '0.03';

{ no warnings;
$REVISION = sprintf("%d.%d", q$Id: Gestinanna.pm,v 1.10 2002/08/02 21:24:51 jgsmith Exp $ =~ m{(\d+).(\d+)});
}

use strict;
no strict 'refs';

# _transit() will try to go the new new $nstate but will throw an exception if unable to do so.
# $nstate - state we are going to
# $ostate - state we are going from
# $trans_func - transition code from $ostate to $nstate
# $pre_func - code to run on transition to $nstate
# $post_func - code to run on transition from $ostate
# $trans_func has precedence over ${pre|post}_func
sub _transit {
    my($self, $ostate, $nstate) = @_;

    my $code_run = 0;
    my $pre_func = "pre_${nstate}";

    if($ostate) {
        if($code_run = $self -> can("${ostate}_to_${nstate}")) {
            $code_run->();
        }
        else {
            $code_run->() if $code_run = $self -> can("post_${ostate}");
            $code_run->() if $code_run = $self -> can($pre_func);
        }
    }
    else {
        $code_run->() if $code_run = $self->can($pre_func);
    }

    $code_run = $self -> _transit_hasa($ostate, $nstate) unless($code_run);

    #$self -> state($nstate);
    return $code_run;
}

sub _transit_hasa {
    my($self, $ostate, $nstate) = @_;

    my $orig_class = ref $self || $self;
    my $code_run = 0;

    # looks like HASAs are expensive
    foreach my $p (@{"${orig_class}::HASA_KEYS_SORTED"}) {
        next unless $nstate =~ m{^${p}_};

        bless $self => ${"${orig_class}::HASA"}{$p};

        my($realoldstate, $realnewstate) = ($ostate, $nstate);
        $nstate =~ s{^${p}_}{};
        $ostate =~ s{^${p}_}{};

        eval {
            $code_run = $self -> _transit($ostate, $nstate);
            bless $self => $orig_class;
            return 1 if $code_run;
        };

        if($@) {
            bless $self => $orig_class;
            die $@ unless ref $@;
            die $@ unless $@ -> isa('StateMachine::Gestinanna::Exception');
            # should never get to the rest of this
            throw StateMachine::Gestinanna::Exception (
                -state => $p . "_" . $@->state,
                -data => $@ -> data
            );
        }

        $nstate = $realnewstate;
        $ostate = $realoldstate;
        bless $self => $orig_class;
        last;
    }

    unless($code_run) {
        foreach my $c (@{"${orig_class}::ISA"}) {
            bless $self => $c;
            eval {
                $code_run = $self -> _transit_hasa($ostate, $nstate);
                bless $self => $orig_class;
                return 1 if $code_run;
            };
            if($@) {
                bless $self => $orig_class;
                die $@;
            };
            last if $code_run;
        }
        bless $self => $orig_class;
    }

    return $code_run;
}

# transit() will try to go to the new $nstate, and will process any ErrorState transitions requested
# $nstate - state we are transitioning to
# we will transition until we have a successful transition or $nstate 
# is undefined (in which case we should remain in our original state)
sub transit {
    my($self, $nstate) = @_;

    while(defined $nstate) {
        eval { 
            $self -> _transit($self -> state, $nstate);
            $self -> state($nstate);
        };
        last unless $@;
        die $@ unless ref $@;
        die $@ unless $@->isa('StateMachine::Gestinanna::Exception');
        $nstate = $@ -> state;
        $self -> {context} -> {data} -> {error} = $@ -> data;
    }
}

# get/set the current state -- no transition is implied
sub state { 
    my $self = shift;
    return $self -> {context} -> {state} unless @_; 
    return( (
        $self -> {context} -> {state},
        $self -> {context} -> {state} = shift,
    )[0]);
}

sub data {
    my($self, $root) = @_;

    my @bits = split(/\./, $root);
    my $t = $self -> {context} -> {data};
    while(@bits) {
        my $b = shift @bits;
        $t -> {$b} = { } unless exists $t->{$b};
        $t = $t -> {$b};
    }
    return $t;
}

# clear data made available to the transition code
sub clear_data {
    my($self, $root) = @_;

    my @bits = split(/\./, $root);
    if(@bits > 1) {
        my $t = $self -> {context} -> {data};
        while(@bits > 1) {
            my $b = shift @bits;
            $t -> {$b} = { } unless exists $t->{$b};
            $t = $t -> {$b};
        }
        $t->{$bits[0]} = { };
    }
    else {
        $self -> {context} -> {data} = { };
    }
}

# add the data to the context under the specified root
# $prefix - root in the data tree
# $args - data to be added
sub add_data {
    my($self, $prefix, $args) = @_;

    return unless UNIVERSAL::isa($args, 'HASH');
    my $base = $self -> {context} -> {data};
    if($prefix) {
        my @bits = split(/\./, $prefix);
        foreach my $b (@bits) {
            if(exists $base->{$b}) {
                unless(UNIVERSAL::isa($base->{$b}, "HASH")) {
                    $base->{$b} = {
                        value => $base->{$b},
                    };
                }
            }
            else {
                $base->{$b} = { };
            }
            $base = $base -> {$b};
        }
    }
  
    my $hash;
    foreach my $k (sort keys %$args) {
        my @bits = split /\./, $k;
        $hash = $base;
        my $b;  
        while(@bits > 1) {
            $b = shift @bits;
            if(exists $hash->{$b}) {
                unless(UNIVERSAL::isa($hash->{$b}, "HASH")) {
                    $hash->{$b} = {
                        value => $hash->{$b},
                    };
                }
            }
            else {
                $hash->{$b} = { };
            }
            $hash = $hash->{$b};
        }
        $hash -> {$bits[0]} = $$args{$k};
    }
}

sub process {
   my($self, $args) = @_;

    delete @$args{grep { !defined($$args{$_}) || $$args{$_} eq '' }
                       keys %$args};

    $self -> clear_data('in');

    $self -> add_data('in', $args);

    my $best = $self -> select_state;

    $self -> add_data('out', $best -> {valid});

    $self -> transit($best -> {state});
}

sub _flatten_hash {
    local($_);
    my $a = shift;

    my %h;

    foreach my $k (keys %$a) {
        if(UNIVERSAL::isa($a->{$k}, "HASH")) {
            my $i = _flatten_hash($a -> {$k});
            my $l;
            $h{"${k}.${_}"} = $i->{$_}
                for keys %$i;
        }
        else {
            $h{$k} = $a->{$k};
        }
    }
    return \%h;
}

sub select_state {
    my $self = shift;

    # $self is the context object
    # ${"${class}::VALIDATORS"}{$self -> state} is the validator to use

    my $args = _flatten_hash($self->data('in'));

    my $na = scalar(keys %$args);
    my $bestscore = $na * $na * $na;
    my $best = { score => -1, state => $self->state, missing => $na };

    return $best unless $na;
    
    my $class = ref $self || $self;
    my $cache = \%{"${class}::EDGES_CACHE"};
    my @states = keys %{$cache->{$self->state}};
    my $validator = ${"${class}::VALIDATORS"}{$self -> state};

    return $best unless $validator;
    return $best unless @states;

    foreach my $v (@states) {
        my($valid, $missing, $invalid, $unknown) =
            $validator->validate($args, $v);
                
        my($nv, $nm, $ni, $nu) = ( 
            scalar(keys %$valid),
            scalar(@$missing),
            scalar(@$invalid),
            scalar(@$unknown),
        );

        my $score = $nv * $na * $na;
        $score /= $nm if $nm;
        $score /= $ni if $ni;
        $score /= $nu if $nu;

        if(($score > $best->{score} && ($nm <= @{$best -> {missing}||[]}))) {
            if($ni) {
                $best -> {invalid} = $invalid;
            }
            else {
                
                $best = { 
                    score => $score,
                    valid => $valid,
                    missing => $missing,
                    invalid => $invalid,
                    unknown => $unknown,
                    state => $v,
                };
            }
            last if $score >= $bestscore;
        }
    }

    return $best;
}

sub generate_validators {
    my($class) = shift;

    $class = ref $class || $class;

    $class -> _generate_states;

    my $states = \%{"${class}::EDGES_CACHE"};
    %{"${class}::VALIDATORS"} = ( );
    @{"${class}::HASA_KEYS_SORTED"} = sort { length $b <=> length $a } keys %{"${class}::HASA"};
    my $vs = \%{"${class}::VALIDATORS"};

    while(my($state, $reqs) = each %$states) {
        $vs->{$state} = Data::FormValidator->new($reqs);
    }
}

sub _generate_states {
    my($class) = shift;
    local($_);

    $class = ref $class || $class;

    return if defined %{"${class}::EDGES_CACHE"};

    # need to collect state transitions and feed them into Data::FormValidator
    # able to inherit: SUPER, ALL, NONE (default for now)
    # need this at the state->state level
    $_ -> _generate_states foreach @{"${class}::ISA"};
    ${"${class}::HASA"}{$_} -> _generate_states(${"${class}::HASA"}{$_}) foreach keys %{"${class}::HASA"};

    %{"${class}::EDGES_CACHE"} = ( );

    unless(keys %{"${class}::EDGES"}) {
        %{"${class}::EDGES"} = ( );
    }

    my $cache = \%{"${class}::EDGES_CACHE"};
    my $states = \%{"${class}::EDGES"};
    my $inherit = [$states -> {_INHERIT} || 'ALL'];
    my @states;

    {
        my %hash = map { $_ => 1 } (map { keys %{"${_}::EDGES_CACHE"} } @{"${class}::ISA"});


        @hash{grep { $_ ne '_INHERIT' } keys %$states} = ( );

        @states = keys %hash;
    }

    foreach my $state (@states) {
        next if $state eq '_INHERIT';
        my $def = $states->{$state};
        my %cdef = ( );
        my @defs = ( );
        unshift @$inherit, ($def -> {_INHERIT}) if defined $def -> {_INHERIT};

        @defs = grep { exists ${"${_}::EDGES_CACHE"}{$state} } @{"${class}::ISA"};
        for($inherit->[0]) {
            /^SUPER$/ && do { @defs = ($defs[0]); last; };
            /^ALL$/ && last;
            /^NONE$/ && do { @defs = ( ); last; };
        }
        $cache->{$state} = _merge_state_defs(
            $inherit,
            (map { ${"${_}::EDGES_CACHE"}{$state} } @defs), 
            $def
        );
        shift @$inherit if defined $def -> {_INHERIT};
    }

    while(my($p, $h) = each %{"${class}::HASA"}) {
        @states = keys %{"${h}::EDGES_CACHE"};

        foreach my $state (@states) {
            next if $state eq '_INHERIT';
            my $def = $states->{"${p}_${state}"};
            my %cdef = ( );
            my @defs = ( );
            unshift @$inherit, ($def -> {_INHERIT}) if defined $def -> {_INHERIT};

            @defs = ( 
                      ${"${h}::EDGES_CACHE"}{$state},
                      #grep { exists ${"${_}::EDGES_CACHE"}{"${p}_${state}"} } @{"${class}::ISA"}
                    );
            for($inherit->[0]) {
                /^SUPER$/ && do { @defs = ($defs[0]); last; };
                /^ALL$/ && last;
                /^NONE$/ && do { @defs = ( ); last; };
            }
            my $tc = _merge_state_defs(
                $inherit,
                #(map { ${"${_}::EDGES_CACHE"}{$state} } @defs),
                @defs,
                $def
            );
            $cache->{"${p}_${state}"}->{"${p}_$_"} = $tc->{$_}
                for keys %$tc;
            shift @$inherit if defined $def -> {_INHERIT};
        }
    }
}

sub _merge_state_defs {
    my $inherit = shift;
    my(@defs) = reverse @_;

    return { } unless @defs;

    my %hash = map { $_ => 1 } (map { keys %$_ } @defs);

    my @states = keys %hash;

    my $ret = { };

    foreach my $state (@states) {
        my @parts = grep {defined} (map { $_->{$state} } @defs);
        for($inherit->[0]) {
            /^SUPER$/ && do { @parts = ($parts[0], $parts[-1]); last; };
            /^ALL$/ && last;
            /^NONE$/ && do { @parts = ($parts[-1]);  last; }; 
        }
        $ret -> {$state} = _deep_merge_hash(@parts);
    }

    return $ret;
}

sub _deep_merge_hash {
    my(@hashes) = @_;

    my %hash = map { $_ => 1 } (map { keys %$_ } @hashes);
    my @keys = keys %hash;

    my $ret = { };

    foreach my $k (@keys) {
        my @items = grep { defined } ( map { $_->{$k} } @hashes );
        next unless @items;
        if(UNIVERSAL::isa($items[0], 'HASH')) {
            $ret->{$k} = _deep_merge_hash(@items);
        }
        else {
            $ret->{$k} = [
                map { ref $_ ? @$_ : $_ } @items
            ];
        }
    }

    return $ret;
}

sub new {
    my($class, %p) = @_;

    $class = ref $class || $class;

    $class -> generate_validators unless defined ${"${class}::VALIDATORS"};
 
    my $self = bless { } => $class;

    $self -> context($p{context}) if $p{context};
    $self -> state($p{state}) if $p{state};

    return $self;
}

sub context {
    my $self = shift;

    return YAML::Dump($self->{context}) unless @_;

    $self -> {context} = YAML::Load($_[0]);
}

package StateMachine::Gestinanna::Exception;

use vars qw(@ISA);

use Error ();

@ISA = qw(Error);

use overload 'bool' => 'bool';
use strict;

sub bool { 1; }

sub state {
    my $self = shift;

    return $self -> {'-state'};
}

sub data {
    my $self = shift;

    return $self -> {'-data'} || { };
}


1;

__END__

=head1 NAME

StateMachine::Gestinanna - provides context and state machine for wizard-like applications

=head1 SYNOPSIS

 package My::Wizard;

 @ISA = qw(StateMachine::Gestinanna);

 %EDGES => {
     # state edge descriptions
     start => {
         show => {
             # conditions for transition
         },
         .
         :
     },
     .
     :
 };

 # code for state transitions
 sub start_to_show {
     my $statemachine = shift;
     # do something if going from start to show
 }

 ###
 
 package main;

 my $sm = new My::Wizard(context => $context);
 $sm -> process($data);
 my $state = $sm -> state;

=head1 DESCRIPTION

StateMachine::Gestinanna is designed to make creation of web-based 
wizards almost trivial.  The module supports inheritance of state 
information and methods so classes of wizards may be created.

=head1 CREATING A STATE MACHINE

The state machine consists of two parts: the conditions for 
transitioning between states (the edges), and the code that is 
run when there is a state transition.  The meaning of a 
particular state (e.g., displaying a web page) is left to the 
application using the state machine.  This allows for maximum 
flexibility in user interfaces.

=head2 Edge Descriptions

The package variable C<%EDGES> contains the edge descriptions.  
The keys of the hash are the states the edges are from and refer 
to a hash whose keys are the states the edges are to.  These keys 
then point to a hash with a description of the requirements for 
an edge transition

The requirements should be suitable for giving to 
L<Data::FormValidator|Data::FormValidator>.  See 
L<Data::FormValidator> for more information.

=head2 Code Run During a Transition

Three different methods may be associated with a transition.  In 
this section, replace C<from> and C<to> in the method names with 
the names of the appropriate states.

If the code needs to preempt the expected target state, it can 
throw a StateMachine::Gestinanna::Exception with the new target 
state.  The state machine will start over with the new target state.

When no error states are thrown and the transition is successful, 
the state machine will halt.

=over 4

=item from_to_to

This method handles the complete transition and is the only method used 
if it is available.  The name of this method is based on the name 
of the two states: C<${from_state}_to_${to_state}>.  For example, if 
we are transitioning from the C<foo> state to the C<bar> state, 
this method would be named C<foo_to_bar>.

=item post_from

If the C<from_to_to> method is unavailable, this method is called, 
if it is available.  

=item pre_to

If the C<from_to_to> method is unavailable, this method is called, 
if it is available.  

=back 4

=head2 Throwing Exceptions

The state machine will catch any exceptions of the StateMachine::Gestinanna::Exception 
class and try to extract a new target state and supplimental data.  
This exception class inherits from the L<Error|Error> module.

=head2 Inheritance

State machines have two forms of inheritance: ISA and HASA.

=head3 ISA Inheritance

State machines can inherit all, some, or none of the edges in 
their inheritance tree.  The default is to merge all the edges 
from all the super-classes.  This behavior may be changed by using 
the C<_INHERIT> key.

 %EDGES = (
     _INHERIT => 'SUPER',
     .
     :
 );

The following values are recognized.

=over 4

=item ALL

This is the default behavior.  All edges from all the classes in 
C<@ISA> are inherited.  If the same edge is in multiple classes, 
the requirements are merged (may be modified by specifying the 
_INHERIT flag in the requirements section for a particular edge).

=item SUPER

This is similar to inheritance in Perl.  The first class in the 
C<@ISA> tree that has a particular edge describes that edge.

=item NONE

This is used to keep any edges from being inherited.

=back 4

Note that this setting does not affect the inheritance of class 
methods.  The code triggered by a transition follows the 
inheritance rules of Perl.

=head3 HASA Inheritance

A state machine may contain copies of other state machines and put 
their state names in their own name space.  For example, if a module 
by the name of C<My::First::Machine> has a state of C<step1> and a 
second module has the following HASA definition, then C<step1> 
becomes the new state of C<first_step1> in C<My::Second::Machine>.

 package My::Second::Machine;

 %HASA = (
    first => 'My::First::Machine',
 );

The methods called on transition may be overridden in the parent 
machine by defining them with the prefix: 
My::Second::Machine::first_state1_to_first_state2 overrides 
My::First::Machine::state1_to_state2.  This is done outside Perl's 
inheritance mechanisms, so calling the method on the state machine 
object will not show the same behavior.

=head1 METHODS

=head2 add_data ($root, $data)

This will add the information in $data to the internal data 
stored in the state machine.  The data will be placed under 
$root.  If $root contains periods (.), it will be split on them 
and serve as a set of keys into a multi-dimensional hash.

=head2 clear_data ($root)

This will remove all data under $root that is stored in the state 
machine.

=head2 context ($context)

If called with no arguments, returns a string representing the 
current context of the state machine.  If called with a single 
argument, restores the state machine to the context represented 
by C<$context>.

The context is serialized using L<YAML|YAML>.

=head2 data ($root)

This will retrieve a hash of data stored in the state machine.  
The $root can be used to retrieve only a sub-set of the data.

Parts of the $root may be separated by periods (.).  For example,
C<data("foo.bar")> will return $data{foo}{bar}.  C<data("foo")> 
will retrieve anything added with C<add_data("foo", {})>.

The following roots are used by the state machine:

=over 4

=item in

This is the data given to the C<process> method.  This is used to 
determine which state the machine should transition to.

=item out

This is the data processed by the Data::FormValidator object for 
the selected state.  Additional processing may take place in the 
code triggered by the transition.

=item error

This is any data specified in the error state transition object 
(the thrown StateMachine::Gestinanna::Exception).

=back 4

=head2 new (%config)

Constructs a new state machine instance.  Any class initialization 
will take place also the first time the class is used.  This 
involves caching inherited information and creating the 
validators.  Any changes to the %EDGES hash will be ignored after 
this takes place.

The %config hash may have the following items.

=over 4

=item context

This is a string previously returned by the C<context> method.  
This can be used to set the machine to a previous state.

=item state

This will set the machine to the given state regardless of the 
context.

=back 4

=head2 process ($data)

Given a reference to a hash of data, this will select the 
appropriate state to transition to, and then transition to the 
new state.  This is usually the method you need.

=head2 select_state ( )

Given the data and current state in the context, selects the new 
state.  This is used internally by C<process>.

=head2 state ($state)

If called without an argument, returns the current state.  If 
called with an argument, sets the state to the argument and 
returns the previous state.

=head2 transit ($state)

This will try and transition from the current state to the new 
state C<$state>.  If there are any errors, error states may be 
processed.  This is used internally by C<process>.

=head1 SEE ALSO

L<Data::FormValidator>,
L<Error>,
L<YAML>,
the test scripts in the distribution.

=head1 AUTHOR

James G. Smith <jsmith@cpan.org>
    
=head1 COPYRIGHT
    
Copyright (C) 2002 Texas A&M University.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

