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
use IO::All;

# VERSION
# ABSTRACT: This is subroutine of CLI apps that posting bulletin

option 'mission' =>(
    is    => 'rw',
    isa   => Str,
    short    => 'm',
    required => 1,
    format => 's',
    doc   => 'Mission file include parse mail result'
);


option 'log_conf'=> (
    is    =>  'rw',
    isa   =>   HashRef[Str],
    short    => 'l',
    requeire => 1,
    doc   =>  'log config file'
);

option 'map'   => (
    is    => 'rw',
    isa   => Str,
    required => 1,
    doc   => 'map file path'

);

option 'target'=> (
    is    =>  'rw',
    isa   =>   Str,
    format => 's',
    requeire => 1,
    doc   =>  'mission note file'
);

with 'MooX::Log::Any','Bbs::Advertising::Role::IO';

sub BUILD {
    my $self   = shift;
    my $args   = shift;
    die " You need config log" unless $self->{log_conf};
    Log::Log4perl->init($self->{log_conf});
    Log::Any::Adapter->set('Log4perl');
}

sub execute {
    my ($self, $args_ref, $chain_ref) = @_;
    my ( $need_content );
    $self->options_usage unless (@$args_ref);
    $self->log->info("call CLI : Posting");
    $need_content = $self->read_mail_mission;
    my @common_header  = qw/ bbs_id mail /;
    my @s_header       = ( @common_header, 'id', 'mail_pw', 'bbs_pw',
                           'login', 'ban'
                         );
	my @m_header       = qw/ tid mail last/;
    my $ad_obj    =  Bbs::Advertising->new(
      {log_conf => $self->log_conf}
                                          );
    my $source    =  $ad_obj->_read_csv($self->map,
                                       \@s_header);
	my $mission   =  $ad_obj->_read_csv($self->target,
	                                    \@m_header,
	                                    );
    my @sort_all_m = sort {
                    my($num_a ) = $source->{$a}->{mail} =~/(\d+)\@/;
                    my($num_b ) = $source->{$b}->{mail} =~/(\d+)\@/;
                    $num_a <=> $num_b;
                          } keys %$source;
        #get last user
    for my$info ( @$need_content ) {
        my $user = $self->_get_user (  \@sort_all_m);
        next if $info->{type} =~ /Finish/;
	    my $ad = Bbs::Advertising->new( {
	            'log_conf'  =>  $self->log_conf,
	            'mission'   =>  $info,
                'target'    =>  $self->target
	                                    }
	                                  );
           $ad->postings;
    }
}

sub _get_user {
    my $self  = shift;
    my $all_m = shift;
    my $last;
    my $content = io $self->target;
    while ( my $line  = $content->chomp->getline  ) { $last = $line   }
    my $mail    = (split /,/, $last)[1];
    my $i = -1;
    my %index = map { $i++; $_ , $i  } @$all_m;
    if( $index{$mail} ) {
        return $all_m->[++$index{$mail}]
    }else{
        $self->log->error( "can't not find post user" );
        die "can't not find post user"
    };

}
1;
