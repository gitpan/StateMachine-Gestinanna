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
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
