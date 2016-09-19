use strict;
use warnings;
use Test::More import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;


{
    package Test::Forward::HMV;
    use Dancer2;
    
    any '/' => sub {
        'home:' . join( ',', request->parameters->flatten );
    };

    get '/get' => sub {
        forward '/', { get => 'baz' };        
    };

    post '/post' => sub {
        forward '/', { post => 'baz' };
    };

    post '/change/:me' => sub {
        forward '/', { post => route_parameters->get('me') }, { method => 'GET' };
    };
}

my $test = Plack::Test->create( Test::Forward::HMV->to_app );

subtest 'query parameters (#1245)' => sub {
    my $res = $test->request( GET '/get?foo=bar' );
    is $res->code, 200, "success forward for /get";
    is $res->content, 'home:foo,bar,get,baz', "query parameters merged after forward";   
};

subtest 'body parameters (#1116)' => sub {
    my $res = $test->request( POST '/post', { foo => 'bar' } );
    is $res->code, 200, "success forward for /post";
    # The order is important: post,baz are QUERY params
    # foo,bar are the original body params
    like $res->content, qr/^home:post,baz/, "forward params become query params";   
    is $res->content, 'home:post,baz,foo,bar', "body parameters available after forward";   
};

subtest 'params when method changes' => sub {
    my $res = $test->request( POST '/change/1234', { foo => 'bar' } );
    is $res->code, 200, "success forward for /change/:me";
    is $res->content, 'home:post,1234,foo,bar', "body parameters available after forward";     
};

done_testing();
