use strict;
use warnings;
package SpecCompliant;

use Exporter 'import';
our @EXPORT = ('is_valid_spec');

use YAML::Tiny;
use JSON::Any;
use Test::CPAN::Meta::YAML::Version;
use Test::CPAN::Meta::JSON::Version;
use Test::More;

sub is_valid_spec
{
    my $tzil = shift;

    subtest is_valid_spec => sub
    {
        my $yaml = $tzil->slurp_file('build/META.yml');
        my $data = eval { YAML::Tiny->read_string($yaml)->[0] };
        if (!ok($data, 'YAML is valid'))
        {
            diag(YAML::Tiny->errstr);
        }
        else
        {
            my $meta_yaml_spec = Test::CPAN::Meta::YAML::Version->new(data => $data);
            ok(!$meta_yaml_spec->parse(), 'no spec errors in META.yml')
                or diag($_) foreach $meta_yaml_spec->errors;
        }

        my $json = $tzil->slurp_file('build/META.json');
        my $meta_json_spec = Test::CPAN::Meta::JSON::Version->new(data => JSON::Any->new->decode($json));
        ok(!$meta_json_spec->parse(), 'no spec errors in META.json')
            or do { diag($_) foreach $meta_json_spec->errors };
    };
}

1;
