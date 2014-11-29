use strict;
use warnings FATAL => 'all';

use utf8;
use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;

use lib 't/lib';
use SpecCompliant;

my $tzil = Builder->from_config(
    { dist_root => 't/does_not_exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ MetaYAML => ],
                [ MetaJSON => ],
                [ MakeMaker => ],
                [ Prereqs => TestRequires => { Tester => 0 } ],   # so we have prereqs to test for
                [ OptionalFeature => FeatureOne => {
                        -description => 'feature description 1',
                        -phase => 'runtime',
                        -relationship => 'requires',
                        -prompt => 1,
                        -default => 1,
                        'Foo' => '1.0', 'Bar' => '2.0',
                    },
                ],
                [ OptionalFeature => FeatureTwo => {
                        -description => 'feature description 2',
                        -phase => 'runtime',
                        -relationship => 'requires',
                        -prompt => 1,
                        -default => 1,
                        'Baz' => '3.0',
                    },
                ],
            ),
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $distmeta = $tzil->distmeta;

# splice out all FinderCodes, since we don't know how many of them there are
$distmeta->{x_Dist_Zilla}{plugins} = [
    grep { $_->{class} ne 'Dist::Zilla::Plugin::FinderCode' } @{ $distmeta->{x_Dist_Zilla}{plugins} }
];

cmp_deeply(
    $distmeta,
    superhashof({
        dynamic_config => 1,
        optional_features => {
            FeatureOne => {
                x_default => 1,
                description => 'feature description 1',
                prereqs => {
                    runtime => { requires => {
                        'Foo' => '1.0',
                        'Bar' => '2.0',
                    } },
                },
            },
            FeatureTwo => {
                x_default => 1,
                description => 'feature description 2',
                prereqs => {
                    runtime => { requires => {
                        'Baz' => '3.0',
                    } },
                },
            },
        },
        prereqs => {
            configure => { requires => { 'ExtUtils::MakeMaker' => ignore } },
            test => { requires => { Tester => 0 } },
            # no test recommendations
            develop => { requires => {
                'Foo' => '1.0',
                'Bar' => '2.0',
                'Baz' => '3.0',
            } },
        },
        x_Dist_Zilla => superhashof({
            plugins => [    # note we are testing the order as well
                superhashof({ class => 'Dist::Zilla::Plugin::GatherDir' }),
                superhashof({ class => 'Dist::Zilla::Plugin::MetaConfig' }),
                superhashof({ class => 'Dist::Zilla::Plugin::MetaYAML' }),
                superhashof({ class => 'Dist::Zilla::Plugin::MetaJSON' }),
                superhashof({ class => 'Dist::Zilla::Plugin::MakeMaker' }),
                superhashof({ class => 'Dist::Zilla::Plugin::Prereqs' }),
                {
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureOne',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureOne',
                            description => 'feature description 1',
                            always_recommend => 0,
                            require_develop => 1,
                            prompt => 1,
                            default => 1,
                            phase => 'runtime',
                            type => 'requires',
                            prereqs => {
                                'Foo' => '1.0',
                                'Bar' => '2.0',
                            },
                        },
                    },
                },
                {
                    class   => 'Dist::Zilla::Plugin::OptionalFeature',
                    name    => 'FeatureTwo',
                    version => Dist::Zilla::Plugin::OptionalFeature->VERSION,
                    config => {
                        'Dist::Zilla::Plugin::OptionalFeature' => {
                            name => 'FeatureTwo',
                            description => 'feature description 2',
                            always_recommend => 0,
                            require_develop => 1,
                            prompt => 1,
                            default => 1,
                            phase => 'runtime',
                            type => 'requires',
                            prereqs => {
                                'Baz' => '3.0',
                            },
                        },
                    },
                },
                superhashof({
                    class   => 'Dist::Zilla::Plugin::DynamicPrereqs',
                    name    => 'via OptionalFeature',
                    version => Dist::Zilla::Plugin::DynamicPrereqs->VERSION,
                }),
            ],
        }),
    }),
    'metadata correct, including plugin order, when two optional features are used',
) or diag 'got distmeta: ', explain $tzil->distmeta;

TODO: {
    local $TODO = 'x_ keys should be valid everywhere!';
    is_valid_spec($tzil);
}

my $content = $tzil->slurp_file('build/Makefile.PL');

like(
    $content,
    qr!
# inserted by .*$
\Qif (prompt('install feature description 1? [Y/n]', 'Y') =~ /^y/i) {\E
  \$\QWriteMakefileArgs{PREREQ_PM}{'Bar'} = \E\$\QFallbackPrereqs{'Bar'} = '2.0';\E
  \$\QWriteMakefileArgs{PREREQ_PM}{'Foo'} = \E\$\QFallbackPrereqs{'Foo'} = '1.0';\E
\}
\Qif (prompt('install feature description 2? [Y/n]', 'Y') =~ /^y/i) {\E
  \$\QWriteMakefileArgs{PREREQ_PM}{'Baz'} = \E\$\QFallbackPrereqs{'Baz'} = '3.0';\E
\}
!m,
    # } to mollify vim
    'Makefile.PL contains the correct code, in order, for two optional features',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
