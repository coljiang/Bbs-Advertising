package Bbs::Advertising::Role::IO;
use Modern::Perl;
use IO::All;
use Moo::Role;

# VERSION
# ABSTRACT: Input/Output file
with 'MooX::Log::Any';
requires 'mission';

sub save_mail_content {
    my $self = shift;
    my $need_content = shift;
    my $output;
    for ( my$i=0; $i<@$need_content; $i++ ) {
        my $mail_c = $need_content->[$i];
        $output .= $i.'#' x 20 ."\n";
        my @keys = keys %{$mail_c};
        my @sort = qw/ body type title /;
        @sort    =  @keys == 4 ? (@sort, 'attachments') :
                    @sort;
#        say Dumper $mail_c;die;
        my @list = map { $_,  ref $mail_c->{$_} ?
                              join ",", @{$mail_c->{$_}}
                              :  $mail_c->{$_}
                       } @sort;

        $output .= sprintf "%s:%s\n" x @sort, @list;
    }
    $output > io($self->mission);
    $self->log->info("Save Mail result to ", $self->mission);
}
1;
