package Bbs::Advertising::Role::IO;
use Modern::Perl;
use IO::All;
use Moo::Role;
use Data::Dumper;

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
        $output .= $mail_c->{msg}.'#' x 20 ."\n";
        my @keys = keys %{$mail_c};
        my @sort = qw/ body type title /;
        @sort    =  @keys == @sort + 2 ? (@sort, 'attachments') :
                    @sort;
#        say Dumper $mail_c;die;
        my @list = map { $_,  ref $mail_c->{$_} ?
                              join ",", @{$mail_c->{$_}}
                              :  $mail_c->{$_}
                       } @sort;
                       #       say Dumper \@list;
        $output .= sprintf "%s:%s\n" x @sort, @list;
    }
    $output > io($self->mission);
    $self->log->info("Save Mail result to ", $self->mission);
}

sub read_mail_mission {
    my $self = shift;
    my $path = shift;
    my ($mission, @list, @need_content );
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
    return \@need_content;

}
1;
