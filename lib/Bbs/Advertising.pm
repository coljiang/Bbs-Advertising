package Bbs::Advertising;
use strict;
use warnings;
use Moo;
use Mojo::UserAgent;
use Modern::Perl;
use Encode qw( encode decode from_to  );
use MIME::Base64;
use Types::Standard qw(:all);
use Log::Log4perl;
use Log::Any::Adapter;
use Data::Dumper;
use IO::All;
use Mail::IMAPClient;
use URL::Encode qw/url_decode url_encode/;
# VERSION: 0.001
# ABSTRACT: Send Ad to bbs


=head1 DESCRIPTION

This is a main package for send ad to bbs

=cut

=head1 ATTRIBUTES

=over 4

=item

=cut

has bbs_id   => (
   is     => 'rw',
   isa    => Str,
   writer => 'set_bbs_id',
);
has bbs_pw   => (
   is    => 'rw',
   isa   => Str,
   writer => 'set_bbs_pw',
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
    builder => 1,
    writer => 'set_ua',
);

has url => (
    is    => 'ro',
    isa   =>  HashRef[Str],
    builder => 1
);
=item map
map ralation file
=cut
has map => (
    is  => 'rw',
    isa => Str,
    default => sub { './source_map' }
);

=item target
mission_list ralation file
=cut
has target => (
    is  => 'rw',
    isa => Str,
    default => sub { './source_map' }
);
=item report_dir
report file path
=cut
has report_dir => (
    is  =>  'rw',
    isa =>  Str,
    default => sub { './report.csv';  }
);
=item proxy_url
proxy url
=cut
has proxy_url => (
    is => 'rw',
    isa => Str
);
=item bbs_image
bbs image
=cut
has bbs_image=> (
    is  => 'rw',
    isa =>  Str,
    default => sub { './image_data' }
);


=item proxy_server

 A file save proxy ip
 e.g. 182.34.20.1

=cut

has  proxy_server  => (
    is   => 'rw',
    isa  =>  Str,
    predicate => 1,
);

=item bulletin

 mail prase result

=cut

has  bulletin  => (
    is   => 'ro',
    isa  =>  HashRef[Str],
    predicate => 1,
);


with 'MooX::Log::Any','Bbs::Advertising::Role::Check';

=p
before 'reply_bbs' => sub {
                my $self = shift;
                if ($self->has_proxy_server) {
                    $self->log->info( 'Set proxy ', $self->proxy_server );
                    #                   $self->_ua_add_proxy
                    my $ua    = $self->ua;
                    my $serve = $self->proxy_server;
                    $ua->proxy->http($serve)->https($serve);
                }
                          };
=cut

sub _build_url {
    my $self = shift;
    {
        form_hash => 'http://7www.cssanyu.org/bbs2/member.php?mod=logging&action=login&infloat=yes&handlekey=login&inajax=1&ajaxtarget=fwin_content_login',
        code_info => 'http://7www.cssanyu.org/bbs2/misc.php?mod=seccode&action=update&idhash=cSAF0C4K3&0.824328346894786&modid=member::logging',
        code_image=> 'http://7www.cssanyu.org/bbs2/',
        login     => 'http://7www.cssanyu.org/bbs2/member.php?mod=logging&action=login&loginsubmit=yes&handlekey=login&loginhash=LJEW9&inajax=1',
        api       => 'https://v2-api.jsdama.com/upload',
        error_api => 'https://v2-api.jsdama.com/report-error',
        reply     => 'http://7www.cssanyu.org/bbs2/forum.php?mod=post&action=reply&fid=41&tid=%sextra=&replysubmit=yes&infloat=yes&handlekey=fastpost&inajax=1',
        reply_from=> 'http://7www.cssanyu.org/bbs2/forum.php?mod=viewthread&tid=%s&page=1',
        secqaa_url=> 'http://7www.cssanyu.org/bbs2/misc.php?mod=secqaa&action=update&idhash=qSC1Rl2Q',
        creat_from=> 'http://7www.cssanyu.org/bbs2/member.php?mod=register',
        submit_req=> 'http://7www.cssanyu.org/bbs2/member.php?mod=register&inajax=1',
        subit_imag=> 'http://7www.cssanyu.org/bbs2/home.php?mod=spacecp&ac=avatar',
        post_imag => 'http://7www.cssanyu.org/bbs2/uc_server/index.php',
        post_form => 'http://7www.cssanyu.org/bbs2/forum.php?mod=post&action=newthread&fid=41',
        post_data => 'http://7www.cssanyu.org/bbs2/forum.php?mod=post&action=newthread&fid=41&extra=&topicsubmit=yes',

    }
}

sub _build_ua {
    my $self = shift;
    my $ua = Mojo::UserAgent->new;


    $ua->connect_timeout(60)->inactivity_timeout(60)->request_timeout(100);
}

sub _ua_add_proxy {
    my $self  = shift;
    my $ua    = $self->ua;
    my $ip    = io($self->proxy_server)->chomp->getline;
    if ( $ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        $ua->on(start => sub {
            my ($ua, $tx) = @_;
            $tx->req->headers->header(
            'X_FORWARDED_FOR'=> $ip
        )});
    }else{
        die "Parameter - proxy_server : Error";
    }
    $self->log->info("Set header : X_FORWARDED_FOR - $ip ");
}
sub _new_ua {
    my $self = shift;
    my $ua = Mojo::UserAgent->new;

    $ua->connect_timeout(60)->inactivity_timeout(60)->request_timeout(100);
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
    my $args   = shift;
    die " You need config log" unless $args->{log_conf};
    Log::Log4perl->init($args->{log_conf});
    Log::Any::Adapter->set('Log4perl');
}


sub _login {
    my $self    = shift;
#    my $logger  = get_logger();
    $self->log->debug('call login');
    my $form_hash   = $self->_get_form_hash($self->url->{form_hash});
    my $code_result = $self->_get_code;
    $self->login_form->{username} = $self->bbs_id;
    $self->login_form->{formhash} = $form_hash;
    $self->login_form->{password} = $self->bbs_pw;
    $self->login_form->{seccodehash} = $code_result->{secode_hash};
    $self->login_form->{seccodeverify} = $code_result->{code};
    my $login_res = $self->ua->post($self->url->{login} =>
      form => $self->login_form  )->result->body;
    my $login_retun  =  decode('gbk',$login_res);
    my $id = $self->bbs_id;
    $login_retun =~ /$id/ ? $self->log->info( 'Login Success' ) :
    $self->log->error( 'Login Failed : '.$login_retun  ) and
    my $err_info     =  decode('utf-8', '验证码填写错误');
    if ($login_retun =~ /$err_info/) {
       $self->log->error( 'secode error' );
       my $error_info= $self->api_info;
       $error_info->{captchaId} =$code_result->{captcha_id};
       $error_info->{code}      =$code_result->{code};
       $self->error_secode($error_info);
       $self->_login;
       # die 'secode error'
    }else{
       $self->log->info('login success');
       my $res = $self->ua->get($self->url->{subit_imag})->result;
       if(!$res->is_success) {
            say decode('gbk',$res->body);
            die 'init error';
       }

    }
    return $self;
}
sub _get_form_hash {
    my $self  = shift;
    my $url   = shift;
    my $qr    = shift;
    $qr ||= qr/<input type="hidden" name="formhash" value="(.*?)"/;
#    my $logger  = get_logger();
    unless ( $url ) {
        $self->log->error( 'not url for get form hash' );
        die "not url for get formhash";
    }
    my $res_from  = $self->ua->get($url)->result->body;
    my (  $form_hash ) =
        $res_from =~ /$qr/;
    if ( $form_hash ) {
        $self->log->debug( 'Hash form => ', $form_hash );
    }else{
        $res_from  =  decode('gbk', $res_from);
        $self->log->debug( 'Hash form is null: '.$url."reply\n".$res_from );
        die 'Hash form is null';
    }
    return $form_hash;
}

sub _get_code {
    my $self  = shift;
#    my $logger  = get_logger();
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
      #print $code_image_file,"\n";
    $image_res > io($code_image_file);
    $self->api_info->{captchaData} = encode_base64($image_res);
    my $res_api = $self->ua->post('https://v2-api.jsdama.com/upload'
      => json => $self->api_info)->result;
    until ( $res_api->code ) {
        $self->log->info( 'wait code 3s ');
        sleep(3);
        $res_api = $self->ua->post('https://v2-api.jsdama.com/upload'
          => json => $self->api_info)->result;
    };
    if ( $res_api->json('/code') ) {
        $self->log->error( encode( 'unicode', $res_api->json('/message' ) ));
        #  $self->log->error( Dumper($self->api_info) );
        die " api error"
    }
    my $code =  $res_api->json('/data/recognition');
    my $capture = $res_api->json('/data/captchaId');
    $self->log->info('secode : '.$code);
    return {
        'secode_hash' => $secode_hash,
        'code'        => $code,
        'captcha_id'  => $capture
           };
};



sub reply_bbs {
    my $self        = shift;
    my $turl        = shift;
    my $message     = shift;
    my $_self_call  = shift;
    my $ord_str;
    $self->_ua_add_proxy if ($self->proxy_server && !$_self_call);
    $self->_login unless $_self_call;
#    my $logger      = get_logger();
    $self->log->debug('call reply_bbs');
    unless ($turl) {
        $self->log->error( 'turl is null' );
        die "input turl";
    }
    my $tid_url     = sprintf $self->{url}->{reply}, $turl;
    my $hash_url    = sprintf $self->{url}->{reply_from},$turl;
    $self->log->info ( 'turl : '.$hash_url );
    my $form_hash   = $self->_get_form_hash( $hash_url );
    my $code_result = $self->_get_code;
    # my $code_result;
    my $data        = $self->reply_form;
    #   from_to($message, "utf-8", "gbk");
    #$message =  decode('utf8', $message);
    #$message =  encode("gbk",  $message);
    # say $message;
    #$ord_str .=  sprintf("\\%o", ord) foreach ( split //, $message);
    #   $message =   url_encode($message);
    #say $ord_str;die;
    $data->{seccodehash}  = $code_result->{secode_hash};
    $data->{seccodeverify}= $code_result->{code};
    $data->{formhash}     = $form_hash;
    $data->{message}      = $message;
    #   $data->{subject}      = '++';
    $data->{posttime}     = time;
    my $login_return= $self->ua->post($tid_url =>
                           {
                           'Accept-Language' => 'zh-CN,zh;q=0.9',
                           'Accept-Encoding' => 'gzip, deflate',
                           },
                           form => $data => charset => 'gbk')->result->body;
    $login_return   =  decode('gbk',$login_return);
    my $err_info    =  decode('utf-8', '验证码填写错误');
    $self->log->debug( $login_return);
    if ($login_return=~ /$err_info/) {
       $self->log->error( 'secode error in reply' );
       my $error_info= $self->api_info;
       $error_info->{captchaId} =$code_result->{captcha_id};
       $error_info->{code} =$code_result->{code};
       $self->error_secode($error_info);
       $self->reply_bbs($turl, $message,1);
    }else{
        $self->log->info("Reply is success : ",$hash_url);
    }
}

sub create_user {
    my $self   = shift;
    #para : map report_dir(option)
    $self->_ua_add_proxy;
    my($map_relation);
#    my $logger  = get_logger();
    $self->log->debug('call create_user');
    my @map_header = qw/
       id mail bbs_id mail_pw  bbs_pw
                   /;
    my @report_header =  (@map_header, 'login', 'ban');
#    my $io             = io($self->map);
#    chomp(my $header   = $io->getline);
#    $self->log->debug( 'header : '.$header );
#    my @headers        = split ',', $header;
#    while (  my $line = $io->getline )  {
#        chomp( $line );
#        $self->log->debug('read line : '.$line);
#        my @val = ( split ',', $line );
#        my $relation = $self
#          ->_set_value( \@headers, \@val,\@report_header ,$logger);
#        my $mail_id = $relation->{mail};
#        unless ( $map_relation->{$mail_id} ) {
#            $map_relation->{$mail_id} = $relation;
#            $map_relation->{$mail_id}->{basic} =
#              (split '@', $mail_id)[0];
#        }else{
#            $self->log->error( $mail_id." dup" );
#            die "mail id dup";
#        }
#    }
    $map_relation = $self->_read_csv($self->map,\@report_header);
    my @sort_list = sort { $map_relation->{$a}->{id}
                             <=>
                           $map_relation->{$b}->{id}
                         }
      keys %$map_relation;
    for my $sort_id  ( @sort_list ) {
        next if ($map_relation->{$sort_id}->{login});
        $self->set_bbs_id($map_relation->{$sort_id}->{bbs_id});
        $self->set_bbs_pw($map_relation->{$sort_id}->{bbs_pw});
        #   $self->_login; ###jc_test
        $self->log->debug( 'create user : '.$sort_id );
        $self->log->debug( 'bbs_id : '.$map_relation->{$sort_id}->{bbs_id} );
        $self->_request_mail( $map_relation->{$sort_id} );
        $self->_create_bbs_user( $map_relation->{$sort_id} );
        unless ($self->_update_bbs_image){
            $self->log->info( 'update map file' );
            $map_relation->{$sort_id}->{login} = 1;
            $self->_update_map(
               \@sort_list, \@report_header, $map_relation, $self->map
                              );
            $self->set_ua($self->_new_ua);
            $self->_update_proxy_file->_ua_add_proxy;
        }
    }




}

sub postings {
    my $self  = shift;
    my $_self_call  = shift;
    my ( @need_post, $note, $content, $last, $info );
    $self->log->info("call postings");
    $self->_ua_add_proxy if ($self->proxy_server && !$_self_call);
    $self->_login unless $_self_call;
    my $code_result = $self->_get_code;
    $info->{formhash} = $self->_get_form_hash(
                           $self->url->{post_form}
                                             );
    $info->{posttime} = $self->_get_form_hash(
                            $self->url->{post_form},
      qr/<input type="hidden" name="posttime".*?value="(\d+)"/
                                             );
    $info->{wysiwyg}  = 1;
    $info->{replycredit_extcredits} = 0;
    $info->{"replycredit_times"}    = "1";
    $info->{"replycredit_membertimes"} = "1";
    $info->{"replycredit_random"} = "100";
    $info->{"allownoticeauthor"} = "1";
    $info->{"usesig"} = "1";
    $info->{seccodemodid} = "forum::post";
    $info->{seccodehash}  = $code_result->{secode_hash};
    $info->{seccodeverify}=  $code_result->{code};
    $info->{subject}      = decode('utf8',$self->bulletin->{title});
    $info->{message}      = decode('utf8',$self->bulletin->{body});
    $info->{typeid}       = $self->bulletin->{type};
    my $login_return= $self->ua->post($self->url->{post_data} =>
                           {
                           'Accept-Language' => 'zh-CN,zh;q=0.9',
                           'Accept-Encoding' => 'gzip, deflate',
                           },
                           form => $info => charset => 'gbk')->result->body;
    $login_return   =  decode('gbk',$login_return);
    my $err_info    =  decode('utf-8', '验证码填写错误');
    if ($login_return=~ /$err_info/) {
       $self->log->error( 'secode error in reply' );
       my $error_info= $self->api_info;
       $error_info->{captchaId} =$code_result->{captcha_id};
       $error_info->{code} =$code_result->{code};
       $self->error_secode($error_info);
       $self->postings(1);
    }elsif( $login_return =~ /document has moved <a href="forum.php\?mod=viewthread&amp;tid=(\d)/) {
        my $tid = $1;
        $self->log->info("post is success : ",
          sprintf $self->{url}->{reply}, $tid
                        );
        return $tid;
    }else{
        $self->log->error( 'post is error : '.$login_return );
        die "post error";
    }




}

sub _set_value {
    my $self   = shift;
    my $keys   = shift;
    my $values = shift;
    my $need_key = shift;
    my $logger = shift;
    #$self->log->debug( 'keys : '.join  ',', @$keys );
    #$self->log->debug( 'vals : '.join  ',', @$values );
    my %relation;
    unless( int(@$keys) == int(@$values)) {
        my @form   = map { "$_ numbers is %s, $_ var : %s" }
          ( qw/key value/ );
        my $form_m = join "\n", @form;
        my $keys_str = join  ',', @$keys;
        my $vars_str = join ',', @$values;
        my $message = sprintf $form_m, (@$keys + 1),
            $keys_str, (@$values + 1), $vars_str;
        die "set_value error";
    }
    for ( my $i=0; $i<@$keys; $i++ ) {
             $relation{$keys->[$i]} = $values->[$i];
    }
    my %need_relation = map { $_ =>  $relation{$_} }  @$need_key;
    #say Dumper \%relation;die;
    return \%need_relation;
}

sub _read_csv{
    my $self = shift;
    my $file = shift;
    my $need_h = shift;
    #my $logger = shift;
    my($map_relation);
    my $io             = io($file);
    chomp(my $header   = $io->getline);
    $self->log->debug( 'header : '.$header );
    my @headers        = split ',', $header;
    while (  my $line = $io->getline )  {
        chomp( $line );
        $self->log->debug('read line : '.$line);
        my @val = ( split ',', $line );
        my $relation = $self
          ->_set_value( \@headers, \@val,$need_h );
        my $mail_id = $relation->{mail};
        unless ( $map_relation->{$mail_id} ) {
            $map_relation->{$mail_id} = $relation;
            $map_relation->{$mail_id}->{basic} =
              (split '@', $mail_id)[0];
        }else{
            $self->log->error( $mail_id." dup" );
            die "mail id dup";
        }
    }
    return $map_relation;

}
sub _create_bbs_user {
   my $self      = shift;
   my $user_info = shift;
#   my $logger    = get_logger();
   my $login_url = $self->_get_login_url($user_info);
   my $form_hash = $self->_get_form_hash($login_url);
   my $double_regex= qr/<input type="hidden" name="hash" value="(.*?)"/;
   my $double_hash= $self->_get_form_hash($login_url, $double_regex);
   my $qaa_info  = $self->_get_secqaa;
   $self->set_bbs_id($user_info->{bbs_id});
   my $code_info = $self->_get_code;
   $self->log->info( 'submit data in login web'  );
    my $header    = {'Content-Type' => 'multipart/form-data; boundary=----WebKitFormBoundary4ABamqy21AJoLmjp'};
    my $test_data = {
        'regsubmit'     => 'yes',  formhash=> $form_hash,
        'referer'       => 'http://www.cssanyu.org/bbs2/forum.php?mod=viewthread&tid=248816&page=1',
        'activationauth'=> undef,
        'hash'          => $double_hash,
        'nameuser_cssa' => $user_info->{bbs_id},
        'wordpass_cssa' => $user_info->{bbs_pw},
        'word2pass_cssa'=> $user_info->{bbs_pw},
        'maile_cssa'    => $user_info->{mail},
        'handlekey'     => 'sendregister',
        'secqaahash'    => $qaa_info->{qaa_hash},
        'secanswer'     => $qaa_info->{qaa_answer},
        'seccodehash'   => $code_info->{secode_hash},
        'seccodemodid'  => 'member::register',
        'seccodeverify' => $code_info->{code}
                    };

    my $submit_tx = $self->ua->post(
        $login_url => $header => form => $test_data
                                  );
    my $submit_res = $submit_tx->result->body;
    $submit_res    =  decode('gbk',$submit_res);
    my $err_info   =  decode('utf-8', '验证码填写错误');
    my $suc_info   =  decode('utf-8','感谢您注册 纽约大学中国学生会BBS');
    $self->log->debug( $submit_res);
    if ($submit_res=~ /$err_info/) {
       $self->log->error( 'secode error in create user' );
       my $error_info= $self->api_info;
       $error_info->{captchaId} =$code_info->{captcha_id};
       $error_info->{code} =$code_info->{code};
       $self->error_secode($error_info);
       $self->_create_bbs_user($user_info);
    }
    if ( $submit_res=~ /$suc_info/ ) {
        $self->log->info( 'user - '.$user_info->{mail}.':create user success '  );
        return 0;
    }



}

sub _get_login_url {
    my $self      = shift;
    my $user_info = shift;
    my $login_url =
    my $domain    = (split '@', $user_info->{mail})[-1];
    my $imap = Mail::IMAPClient->new(
        Server    =>   'mail.'.$domain,
        User      =>   $user_info->{mail},
        Password  =>   $user_info->{mail_pw},
        Ssl       =>   1,
                                    );
    $imap or die "new failed: $@\n";
    my @data      = $imap->select('INBOX')
      ->search('ALL');
    $self->log->info('waitting login mail 10 s');
     sleep(5);
    until ( @data) {
        $self->log->info('waitting login mail( not maill  ) 5s');
        sleep(5);
        @data = $imap->search('ALL');
    };
    my @sort_list = sort { $b <=> $a }  @data;
    for my $quene ( @sort_list ) {
        my $body  = decode('gbk',decode_base64($imap->body_string($quene)));
        my ($login_url) = $body =~
          /target=\"_blank\">(http:\/\/www.c.*)<\/a>/;
        $login_url =~ s/amp;//g;
        if ( $login_url ) {
            $self->log->debug($body);
            $self->log->debug( 'login url : '.$login_url );
            return $login_url;
        }
    }
}

sub _request_mail {
    my $self      = shift;
    my $user_info = shift;
#    my $logger  = get_logger();
#    my $logger    = get_logger();
    my $req_url   = $self->url->{create_form};
    my $form_hash = $self->_get_form_hash($self->url->{form_hash});
    my $qaa_info  = $self->_get_secqaa;
    $self->set_bbs_id($user_info->{bbs_id});
    my $code_info = $self->_get_code;
    $self->log->info( 'submit data for request mail' );
    my $header    = {'Content-Type' => 'multipart/form-data; boundary=----WebKitFormBoundary4ABamqy21AJoLmjp'};
    my $test_data = {
        'regsubmit'     => 'yes',  formhash=> $form_hash,
        'referer'       => 'http://www.cssanyu.org/bbs2/forum.php?mod=viewthread&tid=248816&page=1',
        'activationauth'=> undef,
        'hash'          => undef,
        'maile_cssa'    => $user_info->{mail},
        'handlekey'     => 'sendregister',
        'secqaahash'    => $qaa_info->{qaa_hash},
        'secanswer'     => $qaa_info->{qaa_answer},
        'seccodehash'   => $code_info->{secode_hash},
        'seccodemodid'  => 'member::register',
        'seccodeverify' => $code_info->{code}
                    };
                    #say Dumper $test_data;
    my $submit_tx = $self->ua->post(
        $self->url->{submit_req} => $header => form => $test_data
                                  );
    my $submit_res = $submit_tx->result->body;
    $submit_res    =  decode('gbk',$submit_res);
    my $err_info    =  decode('utf-8', '验证码填写错误');
    $self->log->debug( $submit_res);
    if ($submit_res=~ /$err_info/) {
       $self->log->error( 'secode error in request mail' );
       $self->log->error('submit request error');
       my $error_info= $self->api_info;
       $error_info->{captchaId} =$code_info->{captcha_id};
       $error_info->{code} =$code_info->{code};
       $self->error_secode($error_info);
       $self->_request_mail($user_info);
    }
    if ( $submit_res=~ /succeedhandle_sendregister/ ) {
        $self->log->info( 'user - '.$user_info->{mail}.':request send success '  );
        return 0;
    }
}

sub _get_secqaa   {
    my $self      = shift;
    my %header    = (
        Accept=> '*/*',
        'Accept-Encoding'=> 'gzip, deflate',
        'Accept-Language'=> 'zh-CN,zh;q=0.9',
        Connection=> 'keep-alive',
        Host=> 'www.cssanyu.org',
        Referer=> 'http://www.cssanyu.org/bbs2/member.php?mod=register',
        'User-Agent'=> 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36w',
        );
    my $qaa_tx    = $self->ua->build_tx(GET => $self->url->{secqaa_url});
    $qaa_tx->req->headers->from_hash({})
      ->from_hash( \%header  );
    my $qaa_reply=  $self->ua->start($qaa_tx)->result->body;
    my ($cal )   =  $qaa_reply  =~ /sectplcode\[2\] \+ \'(.*)=.*/;
    my $cal_result= eval( $cal );
    my ($qaa_hash) =  $qaa_reply  =~ /secqaa_(.*)'/;
=p
    say $qaa_reply;
    say $cal;
    say $cal_result;
    say $qaa_hash;
=cut
    return {
        'qaa_hash' => $qaa_hash,
         qaa_answer=> $cal_result
           }
}

sub _update_map {
    my $self      =  shift;
    my $sort_list =  shift;
    my $header    =  shift;
    my $data      =  shift;
    my $path      =  shift;
    ##my $logger    =  shift;
    $self->log->info('bakup ', $path,' file');
    my $cmd       = "cp ".$path.' '.$path."_bak";
    $self->log->debug( 'sys cmd '.$cmd );
    system ( $cmd );
    my $output    =  join ',', @$header;
    $output      .=  "\n";
    for my $id ( @$sort_list ) {
        $output  .=  join ',',
        (map { $data->{$id}->{$_}  } @$header);
        $output  .= "\n";
    }
    $output > io($path);
    $self->log->info( 'update ',$path,' is finished' );
}

sub _update_bbs_image {
    my $self      = shift;
#    my $logger  = get_logger();
    $self->log->debug('call update_bbs_image');
    my $d_io      = io($self->{bbs_image});
    my @lines     = $d_io->getlines;
    my %data      = map {
                    chomp;
                    split /:/, $_;
                        } @lines;
    my $hash      = $self->_get_form_hash( $self->url->{subit_imag} ,
                       qr/http:\/\/cssanyu.org\/bbs2\/uc_server\/images\/camera.swf\?(.*?)'/ );
    print $hash,"\n";
    my %relation  =  split /&|=/, $hash;
    $relation{m}  = 'user',
    $relation{a}  = 'rectavatar',
    my @need_keys = qw/ inajax appid input agent avatartype m a /;
    my $para      = join '&', (map { $_.'='.$relation{$_} } @need_keys);
    my $url       = $self->url->{post_imag}.'?'.$para;
    my $header    = {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'X-Requested-With' => 'ShockwaveFlash/29.0.0.113',
        'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36'
                     };
    my $tx        = $self->ua->post( $url =>$header=>form=>\%data );
    my $req       = $tx->result->body;
    if ( $req =~ /success="1"/ ) {
        $self->log->info( 'update image : Success' );
        return 0;
    }else{
        $self->log->error( 'update image : Fail'.$req );
        die 'update image : Fail';
    }

}

sub _update_proxy_ip {
  my $self = shift;
  my $ip = shift;
  my $loc= shift;
  $self->log->info("Input ip address : ", $ip);
  my @parts = split /\./, $ip;
  $loc ||= $#parts;
  if ( ++$parts[$loc] > 254 ) {
    $parts[$loc] = 1;
    $loc--;
    die "need update ip" if ( $loc == 0 );
    $self->_update_proxy_ip( join( '.', @parts ), $loc );
  }else{
    $self->log->info("Update up result is ", join( '.', @parts  ));
    return join( '.', @parts );
  }
}

sub _update_proxy_file {
    my $self = shift;
    my $ip    = io($self->proxy_server)->chomp->getline;
    my $update= $self->_update_proxy_ip( $ip );
    $update > io($self->proxy_server);
    $self->log->info( "update proxy file" );
    $self;
}

1;
