use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Warnings;
use Test::Fatal;
use Test::Deep;
use Test::Deep::JSON;
use Test::DZil;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            # use default description, phase, type
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            optional_features => {
                FeatureName => {
                    description => 'FeatureName',
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
        })),
        'metadata correct when minimal config provided',
    );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-RuntimeRequires' => {
                            -description => 'desc',
                            -always_recommend => 1,
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            optional_features => {
                FeatureName => {
                    description => 'desc',
                    prereqs => {
                        runtime => { requires => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                runtime => { recommends => { A => 0 } },
                develop => { requires => { A => 0 } },
            },
        })),
        'metadata correct when extracting feature name, phase and relationship from name',
    );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-Test' => {
                            -description => 'desc',
                            -always_recommend => 1,
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            optional_features => {
                FeatureName => {
                    description => 'desc',
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
        })),
        'metadata correct when extracting feature name and phase from name',
    );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'desc',
                            -phase => 'test',
                            # use default relationship
                            A => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            optional_features => {
                FeatureName => {
                    description => 'desc',
                    prereqs => {
                        test => { requires => { A => 0 } },
                    },
                },
            },
            prereqs => {
                test => { requires => { Tester => 0 } },
                # no test recommendations
                develop => { requires => { A => 0 } },
            },
        })),
        'metadata correct when given explicit phase',
    );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -description => 'desc',
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
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            optional_features => {
                FeatureName => {
                    description => 'desc',
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
        })),
        'metadata correct when given explicit phase and relationship',
    );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => 'FeatureName-Test' => {
                            -description => 'desc',
                            A => 0,
                        }
                    ],
                    [ OptionalFeature => 'FeatureName-Runtime' => {
                            -description => 'desc',
                            B => 0,
                        }
                    ],
                ),
            },
        },
    );

    $tzil->build;
    my $json = $tzil->slurp_file('build/META.json');

    cmp_deeply(
        $json,
        json(superhashof({
            optional_features => {
                FeatureName => {
                    description => 'desc',
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
        })),
        'metadata is merged from two plugins',
    );
}

{
    like( exception {
        Builder->from_config(
            { dist_root => 't/corpus/dist/DZT' },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        [ GatherDir => ],
                        [ MetaJSON  => ],
                        [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                        [ OptionalFeature => FeatureName => {
                                _prereq_phase => 'test',
                                -description => 'desc',
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

done_testing;
