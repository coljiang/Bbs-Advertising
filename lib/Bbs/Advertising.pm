package Bbs::Advertising;
use strict;
use warnings;
use Moo;
use Mojo::UserAgent;
use Modern::Perl;
use Encode qw( encode decode from_to  );
use MIME::Base64;
use Types::Standard qw(:all);
use Log::Log4perl qw(:easy);
use Data::Dumper;
use IO::All;
# VERSION: 0.001
# ABSTRACT: Send Ad to bbs

with 'MooX::Log::Any';

=head1 DESCRIPTION

This is a main package for send ad to bbs

=cut

=head1 ATTRIBUTES

=over 4

=item

=cut

has [ qw( bbs_id bbs_pw ) ] => (
   is    => 'rw',
   isa   => Str
);

has code_image_path => (
    is   => 'rw',
    isa  =>  Str,
    default => sub { './' }
);

has api_info => (
    is   => 'rw',
    isa  => HashRef[Str],
    default => sub {
        {
        "softwareId"=> 1,
        "softwareSecret" => "k",
        "username"=> "j",
        "password"=>"1",
        };
                   },
);

has login_form => (
    is    => 'rw',
    isa   => HashRef[Any],
    default => sub {
    {
    formhash => undef,
    referer =>'http://www.cssanyu.org/bbs2/forum.php?mod=forumdisplay&fid=41',
    loginfield =>'username',
    questionid =>'0',
    answer =>'',
    seccodehash => undef,
    seccodemodid =>'member::logging',
    seccodeverify =>undef
    }
    },
);

has reply_form => (
    is     =>   'rw',
    isa    =>   HashRef[Any],
    default=> sub {
    {
    seccodemodid => 'forum::viewthread',
    posttime     => time(),
    usesig       => undef,
    subject      => undef,
    }
    }
);

has ua => (
    is    => 'lazy',
    isa   => Object,
    builder => 1
);

has url => (
    is    => 'ro',
    isa   =>  HashRef[Str],
    builder => 1
);
sub _build_url {
    my $self = shift;
    {
        form_hash => 'http://www.cssanyu.org/bbs2/member.php?mod=logging&action=login&infloat=yes&handlekey=login&inajax=1&ajaxtarget=fwin_content_login',
        code_info => 'http://www.cssanyu.org/bbs2/misc.php?mod=seccode&action=update&idhash=cSAF0C4K3&0.824328346894786&modid=member::logging',
        code_image=> 'http://www.cssanyu.org/bbs2/',
        login     => 'http://www.cssanyu.org/bbs2/member.php?mod=logging&action=login&loginsubmit=yes&handlekey=login&loginhash=LJEW9&inajax=1',
        api       => 'https://v2-api.jsdama.com/upload',
        reply     => 'http://www.cssanyu.org/bbs2/forum.php?mod=post&action=reply&fid=41&tid=%sextra=&replysubmit=yes&infloat=yes&handlekey=fastpost&inajax=1',
        reply_from=> 'http://www.cssanyu.org/bbs2/forum.php?mod=viewthread&tid=%s&page=1'

    }
}
sub _build_ua {
    my $self = shift;
    my $ua = Mojo::UserAgent->new;
    $ua->connect_timeout(18)->inactivity_timeout(18)->request_timeout(36);
    $ua;
}
has image_header => (
    is    =>  'ro',
    isa   => HashRef[Str],
    default => sub {
        {
             Accept => 'image/webp,image/apng,image/*,*/*;q=0.8',
            'Accept-Encoding' => 'gzip, deflate',
            'Accept-Language' => 'zh-CN,zh;q=0.9',
             Connection => 'keep-alive',
             Host => 'www.cssanyu.org',
             Referer => 'http://www.cssanyu.org/bbs2/misc.php?mod=seccode&action=update&idhash=cSAF0C4K3&0.824328346894786&modid=member::logging',
            'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36',
        };

                   }
);

sub BUILD {
    my $self   = shift;
    Log::Log4perl->easy_init($DEBUG);
}

sub _login {
    my $self    = shift;
    my $logger  = get_logger();
    $logger->debug('call login');
    my $form_hash   = $self->_get_form_hash($self->url->{form_hash});
    my $code_result = $self->_get_code;
    $self->login_form->{username} = $self->bbs_id;
    $self->login_form->{formhash} = $form_hash;
    $self->login_form->{password} = $self->bbs_pw;
    $self->login_form->{seccodehash} = $code_result->{secode_hash};
    $self->login_form->{seccodeverify} = $code_result->{code};
    my $login_res = $self->ua->post($self->url->{login} =>
      form => $self->login_form)->result->body;
    my $login_retun  =  decode('gbk',$login_res);
    my $id = $self->bbs_id;
    $login_retun =~ /$id/ ? $logger->info( 'Login Success' ) :
    $logger->error( 'Login Failed : '.$login_retun  ) and
    my $err_info     =  decode('utf-8', '验证码填写错误');
    if ($login_retun =~ /$err_info/) {
       $logger->error( 'secode error' );
       #$self->login;
       die 'secode error'
    }else{
       $logger->info('login success')
    }
    return $self;
}
sub _get_form_hash {
    my $self  = shift;
    my $url   = shift;
    my $logger  = get_logger();
    unless ( $url ) {
        $logger->error( 'not url for get form hash' );
        die "not url for get formhash";
    }
    my $res_from  = $self->ua->get($url)->result->body;
    my (  $form_hash ) =
        $res_from =~ /<input type="hidden" name="formhash" value="(.*?)"/;
    if ( $form_hash ) {
        $logger->debug( 'Hash form => ', $form_hash );
    }else{
        $logger->debug( 'Hash form is null: '.$url."reply\n".$res_from );
        die 'Hash form is null';
    }
    return $form_hash;
}

sub _get_code {
    my $self  = shift;
    my $logger  = get_logger();
    my $res_code_info         =
        $self->ua->get($self->url->{code_info})->result->body;
    my ( $pic_url  )   = $res_code_info =~ /src="(misc.php\?[\w&=]+)/;
    my ( $secode_hash )= $pic_url =~ /idhash=(\w+)/;
    $self->url->{code_image} .= $pic_url;
    my $image_tx      = $self->ua->build_tx(GET => $self->url->{code_image});
    $image_tx->req->headers->from_hash({})
      ->from_hash( $self->image_header );
    my $image_res = $self->ua->start($image_tx)->result->body;
    chomp(my $time      = `date +%F_%R`);
    my $code_image_file  = $self->code_image_path.$self->bbs_id.$time.
      'secode.png';
    $image_res > io($code_image_file);
    $self->api_info->{captchaData} = encode_base64($image_res);
    my $res_api = $self->ua->post('https://v2-api.jsdama.com/upload'
      => json => $self->api_info)->result;
    until ( $res_api->code ) {
        $logger->info( 'wait code 3s ');
        sleep(3);
        $res_api = $self->ua->post('https://v2-api.jsdama.com/upload'
          => json => $self->api_info)->result;
    };
    if ( $res_api->json('/code') ) {
        $logger->error( encode( 'unicode', $res_api->json('/message' ) ));
        die " api error"
    }
    my $code =  $res_api->json('/data/recognition');
    $logger->info('secode : '.$code);
    return {
        'secode_hash' => $secode_hash,
        'code'        => $code
           }
};

sub reply_bbs {
    my $self        = shift;
    my $turl        = shift;
    my $message     = shift;
    $self->_login;
    my $logger      = get_logger();
    $logger->debug('call reply_bbs');
    unless ($turl) {
        $logger->error( 'turl is null' );
        die "input turl";
    }
    my $tid_url     = sprintf $self->{url}->{reply}, $turl;
    my $hash_url    = sprintf $self->{url}->{reply_from},$turl;
    $logger->info ( 'turl : '.$tid_url );
    my $form_hash   = $self->_get_form_hash( $hash_url );
    my $code_result = $self->_get_code;
    my $data        = $self->reply_form;
    from_to($message, "utf-8", "gbk");
    $data->{seccodehash}  = $code_result->{secode_hash};
    $data->{seccodeverify}= $code_result->{code};
    $data->{formhash}     = $form_hash;
    $data->{message}      = $message;
    my $login_return= $self->ua->post($tid_url => form => $data)
      ->result->body;
    $login_return   =  decode('gbk',$login_return);
    my $err_info    =  decode('utf-8', '验证码填写错误');
    $logger->debug( $login_return);
    if ($login_return=~ /$err_info/) {
       $logger->error( 'secode error' );
       $logger->error('login_return');
       $self->reply_bbs;
    }
}




1;
