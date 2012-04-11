#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename;
use File::Copy;
use File::Spec;
use File::stat;
use POSIX qw/ceil/;


my $USETRACKFX = 0.5;
my $SKIPPROB = 0.35;
my $NRPATTERNS = 3;
my $MAXSPLIT = 20;
my $MAXLINES = 0; #53
my $RANDOMSPLIT = 1;
my $notespace = 1;
my $nrtracks = 2; # == voices in polyphony
my $MINSIZE = 4096;
my $MAXSAMPPERINSTR = 120;
my $BPM = 125;
my $LINESPERBEAT = 4; ## not a parameter yet
my $SPLIT = "/home/perweij/sound/youtube/split_on_silence.sh";
my $FXTMPLPREF = "/home/perweij/sound/rns/Fx";
my $SONGTEMPL = "/home/perweij/sound/rns/Song.xml";
my $INSTRTMPL = "/home/perweij/sound/rns/Instrument.xml";
my $SAMPLETMPL = "/home/perweij/sound/rns/Sample.xml";
my $NOTEONTMPL = "/home/perweij/sound/rns/NoteOnMapping.xml";
my $INSTRPRELOADTMPL = "/home/perweij/sound/rns/InstrumentsPreloaded.xml";
my $PATTERNTMPL = "/home/perweij/sound/rns/Pattern.xml";
my $PATTERNTRACKTMPL = "/home/perweij/sound/rns/PatternTrack.xml";
my $SEQUENCERTRACKTMPL = "/home/perweij/sound/rns/SequencerTrack.xml";
my $LINETMPL = "/home/perweij/sound/rns/Line.xml";


### Init

my @sample = ();
my @instrument = ();
my %soundhash = ();		## for direct links to the samples


my @note2sym = generate_note2sym();


my %opts = ( 'name'   => 'songmk',
	     'split'  => 1,
	   );

GetOptions('name=s'  => \$opts{'name'},
	   'split=s'  => \$opts{'split'},
	  );

mkdir("$opts{name}") || die("1");
mkdir("$opts{name}/SampleData") || die("2");

system("touch "."$opts{name}/Song.xml");
xml_ins_template($SONGTEMPL, '', '__skip' => -1, BPM => $BPM);


### Save samples

if ($opts{split}) {
  map { save_split_sample($_) } @ARGV;
} else {
  map { save_sample($_) } @ARGV;
}


### Generate instruments
generate_instruments(\@sample);


### XML instruments
xml_save_instruments(\@instrument);


#### Renoise preloaded instruments
xml_ins_template($INSTRPRELOADTMPL, '<\/Instruments>');


### XML Patterns
xml_generate_patterns();



######################################
######################################
######################################
### functions



sub generate_instruments {
  my $samps = shift;

  foreach my $s (@{$samps}) {
    if (! scalar(@instrument)
	|| scalar(@{$instrument[$#instrument]->{samples}}) >= $MAXSAMPPERINSTR) {
      my $dir         = sprintf("Instrument%.2d (auto)", scalar(@instrument));
      mkdir("$opts{name}/SampleData/$dir") || die("3");
      push(@instrument, { dir => $dir, samples => [], name => "auto" });
    }

    my $file        = sprintf("$opts{name}/SampleData/$instrument[$#instrument]->{dir}/Sample%.2d (Sample%.2d ($s->{name}))$s->{suff}", 
			     scalar(@{$instrument[$#instrument]->{samples}}),
			     scalar(@{$instrument[$#instrument]->{samples}}));
    move($s->{file}, $file);
    $s->{file} = $file;

    push(@{$instrument[$#instrument]->{samples}}, $s);
  }    
}



sub save_split_sample {
  my $samp = shift;

  print STDERR "[save_split_sample] splitting...\n";
  my $pref = "/tmp/splitsamp".int(rand(100000));
  system("$SPLIT $samp $pref.flac");
  my $i = 0;
  my @files = glob("$pref*");
  my $sindex = 0;
  while (@files
	 && $i < $MAXSPLIT
	 && $i < @files) {

    ## optionally random order
    $sindex = ($RANDOMSPLIT ? int(rand(@files)) : $sindex);
    (my $s) = splice(@files, $sindex, 1);

    ## don't save too short samples
    my $st = stat($s);
    if ($st->size < $MINSIZE) {
      unlink($s);
      next;
    }

    my $part = "/tmp/part_".$i."_".basename($samp);
    move($s, $part);
    save_sample($part);
    $i++;
    $sindex++;
  }
}



sub save_sample {
  my $samp = shift;
  print STDERR "[save_sample] $samp\n";

  my $safename = basename($samp);
  $safename =~ s/[^\w\-\._0-9]//g;
  $safename =~ s/(\.[^\.]+)$//g;
  my $suff = $1;
  my $designation = $safename;
  my $file        = sprintf("$opts{name}/SampleData/Sample%.2d ($designation)$suff", 0);

  move($samp, $file);

  chomp(my $nrsamples = `sox --info '$file' | grep samples`);
  $nrsamples =~ s/^.* = (\d+) samples.*$/$1/g;
  my $rate = `sox --info '$file' | grep "^Sample Rate"`;
  $rate =~ s/Sample Rate    : (\d+)$/$1/;
  my $lines = ceil(((0.0 + $nrsamples) / $rate) * ($BPM / 60 * $LINESPERBEAT));

  push(@sample, { name => $safename, 
		  designation => $designation,
		  suff => $suff,
		  file => $file,
		  lines => $lines,
		  nrsamples => $nrsamples});
}



sub xml_save_instruments {
  my $instrs = shift;

  for my $ii (0..(@{$instrs}-1)) {
    my $instr = $instrs->[$ii];

    print STDERR "[xml_save_instrument] $instr->{name}\n";
	
    xml_ins_template($INSTRTMPL, '<\/Instruments>', 
		     DESIGNATION=>"auto");

    for my $si (0..(scalar(@{$instr->{samples}})-1)) {
      xml_ins_template($SAMPLETMPL, '<\/Samples>', 
		       DESIGNATION=>sprintf("Sample %.2d (%s)", $si, $instr->{samples}->[$si]->{designation}),
		       FILE=>$instr->{samples}->[$si]->{file},
		       NRSAMPLES => $instr->{samples}->[$si]->{nrsamples},
		       TRANSPOSE => 48 - (scalar(keys(%soundhash)) % $MAXSAMPPERINSTR) );
                       
      xml_ins_template($NOTEONTMPL, '<\/NoteOnMappings>', 
		       NOTEPOS => $si,
		       SAMPLEINDEX => $si);
      $soundhash{scalar(keys(%soundhash))} = { instr => $ii, note => $si, name => $instr->{samples}->[$si]->{name}, lines => $instr->{samples}->[$si]->{lines} };
    }
  }
}




sub xml_generate_patterns {
  print STDERR "[xml_generate_patterns]\n";

  my $song = generate_patterns_poly();

  my $lines = $MAXLINES > 0 ? $MAXLINES : $song->{lines};

  for my $patnr (0..$NRPATTERNS) {
    xml_ins_template($PATTERNTMPL, '<\/Patterns>', 
		     LINES=>$lines );	
	
    my $soundnr = 0;
    foreach my $i (0..$nrtracks-1) {
      xml_ins_template($SEQUENCERTRACKTMPL, '<SequencerMasterTrack ',
		       TRACKNR => $i,
		       RED => int(rand(256)), GREEN => int(rand(256)), BLUE => int(rand(256)));
      xml_ins_template($PATTERNTRACKTMPL, '<PatternMasterTrack');

      if($USETRACKFX > 0.0
	  && int($USETRACKFX * 100) > int(rand(100))) {
	  chomp(my @fxs = glob("$FXTMPLPREF"."*"));
	  xml_ins_template($fxs[int(rand(@fxs))], '<\/Devices>', '__skip' => 2);
      }

      foreach my $trackline (@{$song->{track}->[$i]}) {
	  xml_ins_template($LINETMPL, '<\/Lines>', 
			   INDEX=>$trackline->{index}, 
			   INSTRNR=> sprintf("%02x", $soundhash{$trackline->{soundnr}}->{instr}),
			   NOTE => $note2sym[$soundhash{$trackline->{soundnr}}->{note}],
			   PAN => $trackline->{pan},
			   VOL => $trackline->{vol});
	  
      }
    }
    
    last;
  }
}



sub generate_patterns_poly {
    my @track = ();
    my @track_curindex = ();

    foreach my $i (0..$nrtracks-1) {
	push(@track, []);
	push(@track_curindex, 0);
    }

    my $soundnr = 0;
    my $curtrack = 0;
    while(defined($soundhash{$soundnr})) {
	my $index = $track_curindex[$curtrack];

	if(int(rand(100)) > int($SKIPPROB*100)) {
print STDERR "NOTE track:$curtrack index:$index sound:$soundnr/".scalar(keys %soundhash)." length:".$soundhash{$soundnr}->{lines}."\n";
	    push(@{$track[$curtrack]}, { index => $index,
					 soundnr => $soundnr,
					 pan => 40 + int(rand(40)) - int(rand(40)),
					 vol => 40 + int(rand(40)) - int(rand(40)) });
	    $track_curindex[$curtrack] += $soundhash{$soundnr}->{lines};
            $soundnr++;
	} else {
	    $track_curindex[$curtrack] += $LINESPERBEAT - int($index % $LINESPERBEAT);
	}
	$curtrack = ($curtrack + 1) % $nrtracks;
    }
    my $maxline = 0;
    for my $i (0..$nrtracks-1) {
	$maxline = $track_curindex[$i] > $maxline ? $track_curindex[$i] : $maxline;
    }

    return { lines => $maxline, track => \@track };
}



sub generate_patterns_even {

  my $lines = $MAXLINES > 0 ? $MAXLINES : scalar(keys %soundhash)*$notespace;
  my @track = ();

  my $soundnr = 0;
  foreach my $i (0..$nrtracks-1) {
      push(@track, []);

      my $index = $i * $notespace;
      while ($index < $lines) {
	  if(int(rand(100)) > int($SKIPPROB*100)) {
	      push(@{$track[-1]}, { index => $index,
				    soundnr => $soundnr,
				    pan => 40 + int(rand(40)) - int(rand(40)),
				    vol => 40 + int(rand(40)) - int(rand(40)) });
	      $soundnr = ($soundnr + 1) % scalar(keys %soundhash);
	  }
	  $index += $nrtracks * $notespace;
      }
  }

  return { lines => $lines, track => \@track };
}




sub generate_note2sym {
  my @notes = ('C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-');
  my $note = 0;
  my @note2sym = ();

  while ($note < $MAXSAMPPERINSTR) {
    push(@note2sym, $notes[$note++ % @notes]."".int($note/12));
  }

  return @note2sym;
}



sub xml_ins_template {
  my $templ = shift;
  my $insbef = shift;
  my %repl = @_;
  my $skip = $repl{'__skip'} ? $repl{'__skip'} : 0;

  open(R, "$opts{name}/Song.xml");
  binmode(R, ":utf8");
  my @tmpl = <R>;
  close(R);

  open(RI, $templ);
  binmode(RI, ":utf8");
  open(W, ">$opts{name}/Song.xml.new");
  binmode(W, ":utf8");

  my $splitpoint = $#tmpl;
  while($skip >= 0
	&& $splitpoint >= 0) {
      while ($tmpl[$splitpoint] !~ /$insbef/
	     && $splitpoint >= 0) {
	  $splitpoint--;
      }
      $skip--;
      $splitpoint-- if($skip >= 0);
  }
  die("$insbef not found $tmpl[0]$tmpl[$#tmpl]") if($splitpoint < 0 && $repl{'__skip'} >= 0);

  my $tmplindex = 0;
  while ($tmplindex < $splitpoint) {
    print W $tmpl[$tmplindex];
    $tmplindex++;
  }
    
  while (<RI>) {
    my $il = $_;
    map { $il =~ s/%%$_%%/$repl{$_}/; } keys %repl;
    print W $il;
  }

  $tmplindex--;
  while ($tmplindex++ < $#tmpl) {
    print W $tmpl[$tmplindex];
  }
    
  close(RI);
  close(W);   

  move("$opts{name}/Song.xml.new", "$opts{name}/Song.xml");
}