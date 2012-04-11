package Youtube;
use strict;
use warnings;
use HTML::Parser();
use WWW;



my $baseurl = "http://www.youtube.com";
my $youtubecmd = "/home/perweij/sound/youtube/youtube-dl";
my $MAX_PAGES = 30;


my $p = HTML::Parser->new(api_version => 3,
			  start_h => [ \&collectLinks, "attr"]);
$p->utf8_mode(1);
my @globalResult = ();




sub get_links {
    my $terms = shift;
    my %opts = @_;

    $MAX_PAGES = defined($opts{pages}) ? $opts{pages} : $MAX_PAGES;

    my $count = 0;
    my $query  = &build_query($terms);
    my @links = ();

    while( $query 
	   && $count++ < $MAX_PAGES) {
#	print STDERR "**** [$count/$MAX_PAGES] $query\n";
	my $page   = &WWW::get_page($query);
	my $result = &parse_result_list($page);

	push(@links, @{$result});
	
	$query = &extract_next_link($page);
	$query = $baseurl.$query if($query);
	sleep(1);
    }

    return \@links;
}




#######################################################################################



sub get_info {
    my %args = @_;
    chomp(my ($title, $format) = `$youtubecmd --get-title  --get-format "$baseurl/watch?v=$args{code}" 2>&1`);
    return { title => $title, format => $format };
}



sub extract_audio {
    my %args = @_;
    my $cmd = "$youtubecmd  --no-mtime --title --extract-audio --audio-format wav --audio-quality 224k '$baseurl/watch?v=$args{code}'";
    system($cmd);

    chomp(my $fname = `$youtubecmd --title --get-filename '$baseurl/watch?v=$args{code}'`);
    $fname =~ s/\..{2,5}$/.wav/;
    return $fname;
}



sub build_query {
    my $query = shift;
    $query =~ s/([^\x30-\x39\x41-\x5a\x61-\x7a])/'%'.sprintf("%X",ord($1))/ge;
    return 'http://www.youtube.com/results?search_query='.$query.'&search_type=&aq=f';
}



sub parse_result_list {
    my $cont = shift;

    $cont =~ s/(^.+<!-- start search results -->|<!-- end search results -->.+$)//gs;
    my @r = map { /^.*href="(\/watch\?v=[^"]+)".*$/; $baseurl.$1 } grep { /href="\/watch\?v=/ } split(/\s+/, $cont);
    my @fr = ();
    for(my $i = 0; $i < @r - 1; $i++) {
	next if($r[$i] eq $r[$i + 1]);
	push(@fr, $r[$i]);
    }
    push(@fr, $r[-1]) if(@r > 1 && $r[-1] ne $r[-2]);

    return \@fr;
}



sub extract_next_link {
    my $page = shift;


    if($page =~ /<a href=["'](\/results.search_query=[^'"]*page=[0-9]+?)["'][^>]+?><span[^>]+?>N.{1,2}sta/s) {
	return $1;
    }

    return undef;
}




sub getRelatedLinks {
    my $code = shift;
    my $url = "$baseurl/watch?v=$code";
    my $get = 'wget --quiet -O - --referer="http://www.google.com" --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.11 (KHTML, like Gecko) Ubuntu/12.04 Chromium/17.0.963.83 Chrome/17.0.963.83 Safari/535.11" --header="Accept:text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5" --header="Accept-Language: en-us,en;q=0.5" --header="Accept-Encoding: gzip,deflate" --header="Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7" --header="Keep-Alive: 300" "'.$url.'" | gunzip -';

    @globalResult = ();
    open(my $fh, $get.' |');
    $p->parse_file($fh);
    close($fh);

    my @result = @globalResult;

    my %count = ();
    return [ grep { ++$count{$_} < 2 } sort @result ];
}



sub collectLinks { 
    my $link = shift;

    if($link->{href}
       && $link->{href} =~ /^(\/watch\?v=[^\&]+)/) {
	push(@globalResult, $1);
    }
}

1;
