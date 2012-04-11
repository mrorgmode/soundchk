package WWW;
use strict;
use warnings;
use HTTP::Response;
use LWP::UserAgent;


my $useragent = undef;



sub get_page {
    my $query = shift;
    my $response = undef;

    &init_agent() unless($useragent);

    eval { $response = $useragent->get($query); };

    if (! defined($response) || not $response->is_success) {
	die("query failed, ".$response->error_as_HTML);
    }

    return $response->content;
}




sub post_page {
    my $action = shift;
    my $args = shift;

    my $response = undef;

    &init_agent() unless($useragent);

    eval { $response = $useragent->post($action, $args); };

    if (! defined($response) || not $response->is_success) {
	die("query failed, ".$response->error_as_HTML);
    }

    return $response->content;
}



sub send_req {
    my $req = shift;
    my $response = undef;

    &init_agent() unless($useragent);

    eval { $response = $useragent->request($req); };

    if (! defined($response) || not $response->is_success) {
	die("query failed, ".$response->error_as_HTML);
    }

    return $response->content;
}




sub init_agent {
    $useragent = LWP::UserAgent->new(env_proxy  => 1,
				     keep_alive => 1,
				     timeout    => 2,
				     agent      => 'mozilla/5.0 (windows; u; windows nt 5.1; en-us; rv:1.5) gecko/20031007',
	);


}



1;
