use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::Deep::JSON;
use Test::DZil;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -default => 1,
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
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    x_default => 1,
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
        'metadata correct when -default is explicitly set to true',
    );
}

{
    # if we always provide x_default in the metadata, this test is pretty
    # redundant with most of t/01-basic.t.
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ MetaJSON  => ],
                    [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                    [ OptionalFeature => FeatureName => {
                            -default => 0,
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
            dynamic_config => 0,
            optional_features => {
                FeatureName => {
                    x_default => 0,
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
        'metadata correct when -default is explicitly set to false',
    );
}

done_testing;
