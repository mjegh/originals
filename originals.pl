#
# Find photographs in the subdir originals (from the cwd) which are not in the cwd.
# I take photos with a Nikon D7100 and I tend to take jpeg and raw (nef).
# Once I copy the files into a dir on my pc I create a subdir "originals" and copy the nef files
# into the "originals" dir. I then edit in the cwd but sometimes delete files which I don't think worth
# keeping but that leaves my "originals" dir out of date. This scans originals to see what files exist
# which are no in the cwd. I cannot JUST use an md5sum as once I've edited the nef in the cwd it is
# no longer the same as the one in originals so I fall back to the date taken.
#
use 5.016;
use strict;
use warnings;
use Cwd;                        #  which dir are we in
use Getopt::Long;
use Data::Dumper;
use Digest::MD5::File qw(file_md5_hex);
use File::Spec;
use Image::ExifTool qw(:Public);
my %opt = (rename => 0, verbose => 1);

GetOptions(
    'delete' => \$opt{delete},
    'verbose!' => \$opt{verbose}
) or die "Error in command line arguments";

my $cwd = getcwd;
say "Working on dir $cwd" if $opt{verbose};

my ($nefs, $md5s, $dates) = get_nefs();

my $dir = File::Spec->catdir($cwd, 'originals');
opendir (my $dh, $dir) or die qq/cannot open $dir: $!/;
my @files = sort readdir($dh);
foreach my $file (@files)  {
    my $full_file = File::Spec->catfile($dir, $file);
    say $file if $opt{verbose};
    if ($file =~ /\.nef\z/i) {
        if (exists($nefs->{$file})) {
            say "File $file is in both dirs" if $opt{verbose};
        } else {
            say "File $file is only in originals";
        }
        my $md5 = file_md5_hex($full_file);
        if (exists($nefs->{$md5})) {
            say "Looks like $file is the same as $nefs->{$md5}";
        }
        my $info = ImageInfo($full_file);
        if (exists($dates->{$info->{DateTimeOriginal}})) {
            say "$file and " . $dates->{$info->{DateTimeOriginal}} . " look to be the same file datetime-wise" if $opt{verbose};
        } else {
            say "Cannot find file $file with datetime " . $info->{DateTimeOriginal};
        }
    }
}
closedir $dh;

sub get_nefs {
    my %nefs_md5;
    my %nefs;
    my %date;
    opendir (my $dh, $cwd) or die qq/cannot opendir $cwd: $!/;
    while (my $file = readdir $dh) {
        if ($file =~ /\.nef\z/i) {
            say "$file" if $opt{verbose};
            $nefs_md5{file_md5_hex($file)} = $file;
            $nefs{$file}++;
            my $info = ImageInfo($file);
            $date{$info->{DateTimeOriginal}} = $file;
        }
    }
    closedir $dh;
    return (\%nefs, \%nefs_md5, \%date);
}

