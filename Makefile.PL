use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'StateMachine::Gestinanna',
    VERSION_FROM => 'Gestinanna.pm',
    AUTHOR => 'James Smith <jsmith@cpan.org>',
    ABSTRACT_FROM => 'Gestinanna.pm',
    PREREQ_PM => {
        Data::FormValidator => 1.9,
        Error => 0.15,
        YAML => 0.35,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
