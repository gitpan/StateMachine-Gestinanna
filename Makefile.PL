use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'StateMachine::Gestinanna',
    VERSION_FROM => 'Gestinanna.pm',
    AUTHOR => 'James Smith <jsmith@cpan.org>',
    ABSTRACT_FROM => 'Gestinanna.pm',
    PREREQ_PM => {
        Class::Container => 0.07,
        Data::FormValidator => 1.9,
        Error => 0.15,
        Params::Validate => 0.24,
        YAML => 0.35,
    },
    PM => {
        'Gestinanna.pm' => '$(INST_LIBDIR)/Gestinanna.pm',
        'MailForm.pm' => '$(INST_LIBDIR)/Gestinanna/Examples/MailForm.pm',
    },
    MAN3PODS => {
        'Gestinanna.pm' => '$(INST_MAN3DIR)/StateMachine::Gestinanna.$(MAN3EXT)',
        'MailForm.pm' => '$(INST_MAN3DIR)/StateMachine::Gestinanna::Examples::MailForm.$(MAN3EXT)',
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
