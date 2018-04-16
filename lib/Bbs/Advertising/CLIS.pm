package Bbs::Advertising::CLIS;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options prefer_commandline => 1;
use Data::Dumper;
# VERSION
# ABSTRACT: This is a Bbs::Advertising project's CLI apps collection

sub execute {
    my ($self, $args_ref, $chain_ref) = @_;
    #say Dumper $args_ref;
    my $pre_message =
     "\nWarning:\n  this is a apps collection, your can only execute it's sub_command or sub_sub_command.more detail can be obtain by --man paramter\n";
    $self->options_usage() unless @$args_ref;
}

1;
