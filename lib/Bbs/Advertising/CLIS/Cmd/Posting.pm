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
with 'MooX::Log::Any';

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


sub BUILD {
    my $self   = shift;
    my $args   = shift;
    die " You need config log" unless $self->{log_conf};
    Log::Log4perl->init($self->{log_conf});
    Log::Any::Adapter->set('Log4perl');
}

sub execute {
    my ($self, $args_ref, $chain_ref) = @_;
    my ($mission, @list, @need_content );
    $self->options_usage unless (@$args_ref);
    $self->log->info("call CLI : Posting");
    $self->log->debug( "read mission file", $self->mission );
    $mission = io($self->mission)->slurp;
    @list    = split /[\d0]#+/, $mission;
    #delete space line
    @list = grep { /body/  } @list;
    for my $part ( @list ) {
        my %save;
        my @info = split /body:|type:|title:|attachments:/, $part;
        shift @info;
        ($save{body}, $save{type}, $save{title}, $save{attachments}) =
        @info;
        for (keys %save) {
            chomp($save{$_}) if $save{$_}
        }
        if ( $save{type} =~ /Error/ ) {
            $self->log->error(
              sprintf "%s -- %s : error", $save{title}, $save{type}
                             );
            die sprintf "%s -- %s : error", $save{title}, $save{type};
        }
        push @need_content, \%save;
    }

    my $ad = Bbs::Advertising->new( {
            'log_conf'  =>  $self->log_conf,
            'mission'   =>  $self->mission,
                                    }
                                  );

}

1;
