package Bbs::Advertising::CLIS::Cmd::Posting;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options  with_config_from_file => 1, prefer_commandline => 1;
use Types::Standard qw/ Str HashRef Num/;
use Log::Any::Adapter;
use Log::Log4perl;
use Bbs::Advertising;
use Data::Dumper;
use DateTime;

# VERSION
# ABSTRACT: This is subroutine of CLI apps that posting bulletin
with 'MooX::Log::Any';

option 'mission' =>(
    is    => 'rw',
    isa   => Str,
    short    => 'm',
    required => 1,
    doc   => 'Mission file include parse mail result'
);


option 'log_conf'=> (
    is    =>  'rw',
    isa   =>   HashRef[Str],
    short    => 'l',
    requeire => 1,
    doc   =>  'log config file'
);


sub BUILD {
    my $self   = shift;
    my $args   = shift;
    die " You need config log" unless $self->{log_conf};
    Log::Log4perl->init($self->{log_conf});
    Log::Any::Adapter->set('Log4perl');
}

sub execute {
    my ($self, $args_ref, $chain_ref) = @_;
    $self->options_usage unless (@$args_ref);
    $self->log->info("call CLI : Posting");
    $self->log->debug( "read mission file" );
    my $ad = Bbs::Advertising->new( {
            'log_conf'  =>  $self->log_conf,
            'mission'   =>  $self->mission,
                                    }
                                  );

}

1;
