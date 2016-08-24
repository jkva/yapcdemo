package app;
use Dancer2;

use Git::Wrapper ();
use Text::Diff::Parser ();
use Encode;

$Git::Wrapper::DEBUG = 1;
use Data::Dump qw(dump dd);

my $git = Git::Wrapper->new('/home/job/projects/presentation/todomvc_current');

our $VERSION = '0.1';

sub extract_diff {
    my @lines = @_;

    my @diff = ();

    while (@lines) {
        my $line = shift @lines;

        $line =~ s/</&lt;/g;
        $line =~ s/>/&gt;/g;

        if ($line =~ /^(?:diff --git|index |(?:---|\+\+\+) (?:a|b))/) {
            # start of the next diff
            if (scalar @diff && $line =~ /^diff --git/) {
                unshift @lines, $line;
                last;
            }
            push @diff, { type => 'INFO', content => $line };
        } elsif ($line =~ /^@@/) {
            my ($marker, $content) = $line =~ /^(@@.*?@@) (.*)$/;
            push @diff, { type => 'MARKER', marker => $marker, content => $content };
        } elsif ($line =~ /^-/) {
            push @diff, { type => 'REMOVE', content => $line };
        } elsif ($line =~ /^\+/ ) {
            push @diff, { type => 'ADD', content => $line };
        } else {
            push @diff, { type => 'NEUTRAL', content => $line };
        }
    }

    return (\@diff, @lines);
}

sub parse_diff {
    my @lines = @_;

    shift @lines;
    my ($diff, @diffs);

    while (@lines) {
        ($diff, @lines) = extract_diff(@lines);
        unshift @diffs, $diff;
    }

    return \@diffs;
}

my %REVISIONS = (
    'ee398f6' => { unified => 8, index => 1 },
    '454332a' => { index => 2 },
    '20a8296' => { index => 3 },
    'c75ccfe' => { index => 4 },
    'e97b087' => { index => 5 },
    'ae28075' => { index => 6 },
    'f836bed' => { index => 7 },
    '919baef' => { unified => 10, index => 8 },
    '309f4c0' => { index => 9 },
    '4940af8' => { index => 10 },
    '5b89f6f' => { index => 11 },
    'd78d630' => { index => 12 },
    'c49bd2f' => { index => 13 },
    '1fe6f07' => { index => 14 },
    '8e1f419' => { index => 15 },
    'cb62dc1' => { index => 16 },
    '8c32a01' => { index => 17 },
    'd54ee58' => { index => 18 },
    '821d55c' => { index => 19 },
    '0701276' => { index => 20 },
    '151da4b' => { index => 21 },
    'eb3e6fe' => { index => 22 }
);

foreach my $key ( keys %REVISIONS ) {
    $REVISIONS { $REVISIONS{$key}{index} } = $key;
}

sub get_revision {
    my $revision = shift;
    my $format = q(%H%n%s);

    my $settings = $REVISIONS{ $revision };

    my @rev_data = $git->show({ pretty => $format, unified => $settings->{unified} || 3 }, $revision);

    $git->checkout($revision);

    my $hash = shift @rev_data;
    my $msg = shift @rev_data;
    my $diff = parse_diff(@rev_data);

    return {
        hash           => $hash,
        commit_message => $msg,
        diff           => $diff,
        previous       => $REVISIONS{ $settings->{index} -1 },
        next           => $REVISIONS{ $settings->{index} +1 },
    };
}

get '/' => sub {
    my $revision = $REVISIONS{1};
    redirect '/revision/' . $revision;
};

get '/revision/:revision' => sub {
    my $revision = get_revision(params->{revision});

    template 'index' => {
        revision => $revision
    };
};

true;
