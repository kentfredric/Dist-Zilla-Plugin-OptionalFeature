use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;

use lib 't/lib';
use SpecCompliant;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            # use default phase, type
                            -description => 'feature description',
                            -prompt => 0,
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'feature description',
                    prereqs => {
                        runtime => { requires => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 0,
                            require_develop => 1,
                            prompt => 0,
                            phase => 'runtime',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        }),
        'metadata correct when minimal config provided',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    is_valid_spec($tzil);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-BuildSuggests' => {
                            -description => 'feature description',
                            -always_recommend => 1,
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {    # strip phase/type as it is extracted
                    description => 'feature description',
                    prereqs => {
                        build => { suggests => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                build => { recommends => { A => 0 } },
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName-BuildSuggests',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 1,
                            require_develop => 1,
                            prompt => 0,
                            phase => 'build',
                            type => 'suggests',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        }),
        'metadata correct when extracting feature name, phase and relationship from name',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    is_valid_spec($tzil);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-Test' => {
                            -description => 'feature description',
                            -always_recommend => 1,
                            -prompt => 0,
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'feature description',
                    prereqs => {
                        test => { requires => { A => 0 } }
                    },
                },
            },
            prereqs => {
                test => {
                    requires => { Tester => 0 },
                    recommends => { A => 0 },
                },
                develop => { requires => { A => 0 } }
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName-Test',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 1,
                            require_develop => 1,
                            prompt => 0,
                            phase => 'test',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        }),
        'metadata correct when extracting feature name and phase from name',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    is_valid_spec($tzil);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description',
                            -phase => 'test',
                            -type => 'recommends',
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'feature description',
                    prereqs => {
                        test => { recommends => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 0,
                            require_develop => 1,
                            prompt => 0,
                            phase => 'test',
                            type => 'recommends',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        }),
        'metadata correct when given explicit phase',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    is_valid_spec($tzil);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'feature description',
                            -phase => 'test',
                            -relationship => 'suggests',
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'feature description',
                    prereqs => {
                        test => { suggests => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 0,
                            require_develop => 1,
                            prompt => 0,
                            phase => 'test',
                            type => 'suggests',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        }),
        'metadata correct when given explicit phase and relationship',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    is_valid_spec($tzil);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

TODO:
{
    todo_skip 'CPAN::Meta::Merge cannot yet merge two related optional_features sections', 2
        if Dist::Zilla->VERSION >= 5.022;

    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaYAML => ],
                    [ MetaJSON => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-Test' => {
                            -description => 'feature description',
                            -prompt => 0,
                            A => 0,
                        }
                    ],
                    [ OptionalFeature => 'FeatureName-Runtime' => {
                            -description => 'feature description',
                            -prompt => 0,
                            B => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'feature description',
                    prereqs => {
                        test => { requires => { A => 0 } },
                        runtime => { requires => { B => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => { A => 0, B => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName-Test',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 0,
                            require_develop => 1,
                            prompt => 0,
                            phase => 'test',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                },
                {
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName-Runtime',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 0,
                            require_develop => 1,
                            prompt => 0,
                            phase => 'runtime',
                            type => 'requires',
                            prereqs => { B => 0 },
                        },
                    },
                }),
            }),
        }),
        'metadata is merged from two plugins',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    is_valid_spec($tzil);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    like( exception {
        Builder->from_config(
            { dist_root => 't/corpus/dist/DZT' },
            {
                add_files => {
                    path(qw(source dist.ini)) => simple_ini(
                        [ GatherDir => ],
                        [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                        [ OptionalFeature => FeatureName => {
                                _prereq_phase => 'test',
                                -description => 'feature description',
                                A => 0,
                            }
                        ],
                    ),
                },
            },
        ) },
        qr/^Invalid options: _prereq_phase/,
        'private attrs cannot be set directly',
    );
}

{
    my $tzil;

    cmp_deeply(
        [ warnings {
        $tzil = Builder->from_config(
            { dist_root => 't/corpus/dist/DZT' },
            {
                add_files => {
                    path(qw(source dist.ini)) => simple_ini(
                        [ GatherDir => ],
                        [ MetaConfig => ],
                        [ MetaYAML => ],
                        [ MetaJSON => ],
                        [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                        [ OptionalFeature => FeatureName => {
                                -hello => 'oh hai',
                                -description => 'feature description',
                                -prompt => 0,
                                A => 0,
                            }
                        ],
                    ),
                },
            },
        ) } ],
        [ re(qr/^\[OptionalFeature\] warning: unrecognized option\(s\): -hello/) ],
        'unrecognized options are accepted, with a warning',
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    description => 'feature description',
                    prereqs => {
                        runtime => { requires => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                develop => { requires => { A => 0 } },
            },
            x_Dist_Zilla => superhashof({
                plugins => supersetof({
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureName',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureName',
                            description => 'feature description',
                            always_recommend => 0,
                            require_develop => 1,
                            prompt => 0,
                            phase => 'runtime',
                            type => 'requires',
                            prereqs => { A => 0 },
                        },
                    },
                }),
            }),
        }),
        'metadata is still correct even with an unrecognized option',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    is_valid_spec($tzil);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
