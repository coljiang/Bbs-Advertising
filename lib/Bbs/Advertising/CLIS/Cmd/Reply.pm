package Bbs::Advertising::CLIS::Cmd::Reply;
use Modern::Perl;
use Moo;
use MooX::Cmd;
use MooX::Options  with_config_from_file => 1, prefer_commandline => 1;
use Types::Standard qw/ Str HashRef/;
use Log::Any::Adapter;
use Log::Log4perl;
use Bbs::Advertising;
use Data::Dumper;
use DateTime;

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


option 'map'   => (
    is    => 'rw',
    isa   => Str,
    short    => 'm',
    required => 1,
    doc   => 'map file path'

);

option 'code_image_path' => (
    is    => 'rw',
    isa   => Str,
    short    => 'c',
    required => 1,
    doc   => 'the dir save image for secode'
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
    $self->log->info('call CLI : reply');
    my(@messages);
	my @common_header  = qw/ bbs_id mail /;
	my @m_header       = qw/ tid mail last/;
	#mission_header
	my @s_header       = ( @common_header, 'id', 'mail_pw', 'bbs_pw',
	                       'login', 'ban'
	                     );
    my $ad_obj    =  Bbs::Advertising->new({log_conf => $self->log_conf});
	my $mission   =  $ad_obj->_read_csv($self->target,
	                                    \@m_header,
	                                    );
	my $source    =  $ad_obj->_read_csv($self->map,
	                                   \@s_header,
	                                   );
  #  print Dumper $mission;
    my @key_uints= qw/ year month day hour minute second /;
    my @all_m    = keys %$mission;
    my @sort_all_m = sort {
                    my($num_a ) = $mission->{$a}->{mail} =~/(\d+)\@/;
                    my($num_b ) = $mission->{$b}->{mail} =~/(\d+)\@/;
                    $num_a <=> $num_b;
                          } @all_m;
    #all missions
    for my $doc ( @sort_all_m ) {
        my @var_units= split /-|T|:/,  $mission->{$doc}->{last};
        my $init_form= {map { $key_uints[$_] => $var_units[$_] }
                         (0..$#key_uints)};
        $init_form->{time_zone} = 'Asia/Shanghai';
        my $dur      = DateTime->now->delta_ms(
                         DateTime->new( $init_form )
                                              )
                       ->in_units('minutes');
        $self->log->debug('dur time in min ', Dumper $dur );
        if ( $dur < 65 ) {
            my $form = "tid:%s not enought 1 hours";
            $self->log->info( sprintf ( $form,
                                        $mission->{$doc}->{tid}
                                      )
                            );
            next;
        }

        my $message = join '-', (map{  'up' } (0..6));
        my %init_args = (
          log_conf  =>   $self->log_conf,
          bbs_id    =>   $source->{$doc}->{bbs_id},
          bbs_pw    =>   $source->{$doc}->{bbs_pw},
          api_info  =>   $self->api_info,
          code_image_path =>  $self->code_image_path,
                        );
        my $bbs_ad = Bbs::Advertising->new(%init_args);
        $bbs_ad->reply_bbs($mission->{$doc}->{tid}, $message);
        $self->log->info( 'reply bbs success tid : ' , $mission->{$doc}->{tid} );
        $mission->{$doc}->{last} = DateTime->now(time_zone => "Asia/Shanghai");
        $ad_obj->_update_map(\@sort_all_m, \@m_header, $mission, $self->target);
        $self->log->info('update ',$self->target);
    }

}


1;
