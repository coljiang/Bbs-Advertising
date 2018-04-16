package Bbs::Advertising::CLIS::Cmd::Reply;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options {prefer_commandline => 1, with_config_from_file => 1};
use Types::Standard qw/ Str HashRef/;
use Log::Any::Adapter;

# VERSION
# ABSTRACT: This is subroutine of CLI apps that replp bbs
with 'MooX::Log::Any';

option 'target'  => (
    is    => 'rw',
    isa   => Str,
    short    => 't',
    required => 1,
    doc   => 'Mission file include mail, tid'
);

option 'source'  => (
    is    => 'rw',
    isa   => Str,
    short    => 's',
    required => 1,
    doc   => 'source file include bbs_id bbs_pwd etc..'
);

option 'log_conf'=> (
    is    =>  'rw',
    isa   =>   HashRef[Str],
    short    => 'l',
    requeire => 1,
    doc   =>  'log config file'
);

option 'api_info' => (
    is    =>   'rw',
    isa   =>   HashRef[Str],
    short    => 'a',
    requeire => 1,
    doc   =>  'proxy client config'
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
    $self->log('call CLI : reply');
	my @common_header  = qw/ bbs_id mail /;
	my @m_header       = ( @common_header, 'tid', 'last_reply' );
	#mission_header
	my @s_header       = ( @common_header, 'id', 'mail_pw', 'bbs_pw',
	                       'login', 'ban'
	                     );
	my $mission   =  Bbs::Advertising::_read_csv($opt->target,
	                                             \@common_header,
	                                            );
	my $source    = Bbs::Advertising::_read_csv($opt->source,
	                                            \@s_header,
	                                            );
    my @key_uints= qw/ year month day hour minute second /;
    for my $doc ( keys %$mission ) {
        my @var_units= split /-|T|:/,  $mission->{$doc}->{last};
        my $init_form= {map { $key_uints[$_] => $var_units[$_] },
                         (0..$#key_uints)};
        $init_form->{time_zone} = 'Asia/Shanghai';
        my $dur      = DateTime->now->delta_ms(
                         DateTime->new( $init_form )
                                              )
                       ->in_units('minutes');
        unless ( $dur < 65 ) {
            my $form = "tid:%s not enought 1 hours";
            $self->log->info( sprintf ( $form,
                                        $mission->{$doc}->{tid}
                                      )
                            );
        }




    }

}


1;
