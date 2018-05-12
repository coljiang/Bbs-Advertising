package Bbs::Advertising::CLIS::Cmd::Mission;
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
use Mail::IMAPClient;
use Email::MIME;


# VERSION
# ABSTRACT: This is subroutine of CLI apps that create mission list file
with 'MooX::Log::Any';

=head1 Attributes

 attributes of Class

=cut

option 'server'  => (
    is        => 'rw',
    isa       => Str,
    short     => 's',
    required  => 1,
    format    => 's',
    doc       => 'mail server'
);


option 'user'  => (
    is        => 'ro',
    isa       => Str,
    short     => 'u',
    required  => 1,
    format    => 's',
    doc       => 'user for mail server'
);


option 'pw'  => (
    is        => 'ro',
    isa       => Str,
    short     => 'p',
    required  => 1,
    format    => 's',
    doc       => 'pass wd for mail server'
);


option 'day'  => (
    is        => 'ro',
    isa       => Num,
    short     => 'd',
    required  => 1,
    format    => 'i',
    doc       => 'select mail to current time minus this time'
);

option 'path'  => (
    is        => 'ro',
    isa       => Str,
    format    => 's',
    doc       => 'The dir that save attachment file'
);

option 'map'  => (
    is        => 'ro',
    isa       => Str,
    required  => 1,
    format    => 's',
    doc       => 'source_map file path'
);

option 'mission'  => (
    is        => 'rw',
    isa       => Str,
    format    => 's',
    doc       => 'mission file path',
    coerce    => sub { chomp( my $date = `date +%m_%d`); $_[0].$date  }
);


option 'title'  => (
    is        => 'rw',
    isa       => Str,
    format    => 's',
    doc       => 'To select subject of mail contain this str'
);

option 'log_conf' => (
    is        => 'ro',
    isa       => HashRef[Str],
    doc       => 'Config Set'
);

=head1 Method

=cut

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
    $self->log->info('call CLI : create mission file');
    ##get mail
    my $imap = Mail::IMAPClient->new(
        Server    =>   $self->server,
        User      =>   $self->user,
        Password  =>   $self->pw,
        Ssl       =>   1,
                                    );
	my($day, $month, $year)=(localtime)[3,4,5];
	$year += 1900;
	$month++;
	my $dt        = DateTime->new(
	    year      => $year,
	    month     => $month,
	    day       => $day,
	    time_zone => 'Asia/Shanghai'
	                             );
    $self->log->info( "Select mail from ", $self->day, ' day ago');
	$imap->select('INBOX');
	my @msgs = $imap->since($dt->epoch - 3600 *24 * $self->day);
    for my $msg ( @msgs ){
	    my $str     = $imap->message_string($msg);
	    my $con     = Email::MIME->new($str);
        my %header  = $con->header_str_pairs;
	    say Dumper \%header;die;
	}

}


1;
