use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'ArpCLI',
    VERSION_FROM     => 'lib/ArpCLI.pm',
    ABSTRACT         => 'ARP Networks Platform API command-line client',
    AUTHOR           => 'Todd <todd@local>',
    EXE_FILES        => ['bin/arpcli'],
    PREREQ_PM        => {
        'HTTP::Tiny' => '0.056',
        'JSON::PP'   => '2.27344',
        'YAML::PP'   => '0.38',
    },
    TEST_REQUIRES    => {
        'Test::More' => '1.302',
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'file:///home/todd/git/sw/arpcli',
            },
        },
    },
);