package Bbs::Advertising::Role::Check;
use Modern::Perl;
use Moo::Role;

# VERSION
# ABSTRACT: Check http repose
with 'MooX::Log::Any';

requires 'api_info','url','ua';

sub error_secode {
    my $self       =  shift;
    my $error_info =  shift;
    $self->log->error(
        'Report secode recognition error : ', $error_info->{code}
                    );
    my $res_api    =  $self->ua->post(
             $self->url->{error_api} =>  json => $error_info
                                     )->result;
    if ( !$res_api->json('/code')  ) {
        $self->log->error('Report secode recognition error is succeed');
    }else{
        $self->log->error('Report secode recognition error is failed');
    }


}

1;
