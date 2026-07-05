requires 'perl', '5.20.0';
requires 'HTTP::Tiny', '0.056';
requires 'JSON::PP', '2.27344';
requires 'YAML::PP', '0.38';

on 'test' => sub {
    requires 'Test::More', '1.302';
};