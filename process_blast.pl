# DESCRIPTION
# ===========
#   This program is used to progress blast automatically
# The program will decide to do the blast by checking the
# fasta file type ( if the seq is ATGCN, It will be blastn;
# if the seq is not only ATGCN, It will be other blast)
# 
#   The result will be output into STDOUT or file that depend
# on you decide.
#
# EDIT
# ====
#   2019-05-03
# 
# AUTHOR
# ======
#   eternal-bug


use File::Basename;
use IPC::Run qw/run/;
use File::Spec;
use Getopt::Long;


my @amino_acid = qw/A R D C Q E H I G N L K M F P S T W Y V */;  # 20种氨基酸
my @basic = qw/A G T C/;  # 4种核苷酸

# blastn是将给定的核酸序列与核酸数据库中的序列进行比较
# blastp是使用蛋白质序列与蛋白质数据库中的序列进行比较，可以寻找较远的关系
# blastx将给定的核酸序列按照六种阅读框架将其翻译成蛋白质与蛋白质数据库中的序列进行比对，对分析新序列和EST很有用
# tblastn将给定的氨基酸序列与核酸数据库中的序列（双链）按不同的阅读框进行比对，对于寻找数据库中序列没有标注的新编码区很有用

my %blast_type_argument = (
	blastn   => "F",
	blastp   => "T",
	tblastn  => "F",
	blastx   => "T",
);

my %query_sbjct = (
n=>{n=>blastn,p=>blastx},
p=>{n=>tblastn,p=>blastp},
);

my $argument = GetOptions(
    "i|input:s"    => \(my $input_path),
    "d|database:s" => \(my $database_path),
    "o|out:s"      => \(my $out = "blast_result"),
    "stdout"       => \(my $stdout),
    "h|help"       => \(my $help),
);

usage() if defined $help;
usage() if not defined $input_path;
usage() if not defined $database_path;

for my $sbjct_file (@{&judge_dic_file($database_path)}){
    for my $query_file (@{&judge_dic_file($input_path)}){
        getfile($query_file, $sbjct_file, $out);
    }
}

sub usage {
    my $message = <<EOF;

  DESCRIPTION
  
      This program is used to progress blast automatically
    The program will decide to do the blast by checking the
    fasta file type ( if the seq is ATGCN, It will be blastn;
    if the seq is not only ATGCN, It will be other blast)
    
      The result will be output into STDOUT or file that depend
    on you decide.

  USAGE
     
     perl $0 -i query_file -d database_file -o output_dir
     
  OPTION
  
     -i   the query file or query file directory
     -d   the sbjct(database) file or sbjct directory
     -o   the output directory
     
  AUTHOR
  
    eternal-bug
EOF
    print(STDERR $message) && exit(1);

}

sub judge_dic_file{
	my $input = shift;
	my @file_list;
	if(-f $input){
		push @file_list,$input;
	}elsif(-d $input){
		@file_list = &get_dic_file($input,"fas|fa|fasta");
	}else{die "You enter the fasta file path is ERROR!Please check!"}
	unless(scalar(@file_list) > 0){
		die "There isn't fasta file in <$input> dictionary!";
	}else{
		return (\@file_list);
	}
}

#获取文件夹中相应格式的文件,"路径"，"文件格式"
sub get_dic_file{
	my @list = ();
	my @return_list = ();
	my ($dic_name,$file_type) = @_;
	$file_type =qr/$file_type/i;
	if (!$file_type){$file_type = '\w+'};
	my $temp;
	opendir my $dic_fh,"$dic_name" or die "Can't open the dictionary($dic_name) : $!";
	@list = readdir ($dic_fh);
	for (@list){
		if(-d $_ ){next};
		if(m/^\.+$/){next};
		if(m/\.${file_type}$/){
			$temp = $dic_name ."/". $_;
			push @return_list, $temp;
		}
	}
	closedir $dic_fh;
	return @return_list;
}


sub getfile{
	my ($input_fasta,$input_database,$out) = @_;
	my ($input_type,$database_type);
	open $INPUT_fh,"<","$input_fasta" or die "Can't open file : $!\b";
	$input_type = &judge_file_type($INPUT_fh);
	close $INPUT_fh;
	open my $DATABASE_fh,"<","$input_database" or die "Can't open file : $!\b";
	$database_type = &judge_file_type($DATABASE_fh);
	close $DATABASE_fh;
	&processing_blast($input_fasta,$input_database,$input_type,$database_type,$out);
}

sub judge_file_type{    # 传入文件句柄的引用，判断输入文件是蛋白质序列还是氨基酸序列
	my $file_handle = shift;
	my $input_type;
	while(my $read = <$file_handle>){
		if(index($read,">")==0){
			$read = <$file_handle>;
			while($read =~ m/^\s*$/){$read = <$file_handle>};
			my @match = grep {index(uc(substr($read,0,20)),$_) != -1} @amino_acid;	
			if(scalar(grep {!m/[AGTCN]/} @match) > 0){
				$input_type = 'p';  # p is protein
				last;
			}else{$input_type = 'n';last;}  # n is nucleic acid
		}
	}
	return $input_type;
}

sub processing_blast{  
	my ($input_fasta,$input_database,$input_type,$database_type,$out) = @_;
	&allblast($input_fasta,$input_database,$query_sbjct{$input_type}{$database_type},$out);
}

sub format{   # 对作为数据库的fasta文件进行格式化
	my ($input_fasta,$input_database,$format_type,$blast_path) = @_;
	my ($data_name,$data_path) = File::Basename::fileparse($input_database);
	# 先对数据库进行建立索引
	opendir my $dic_fh,"$data_path" or die "Can't open the dictionary($input_database) : $!";
	my @file_list = readdir ($dic_fh);
	my $format_file_suffix = qr(nhr|nin|nsd|nsi|nsq); # 用来判断数据库文件是否被格式化了
	if(scalar (grep {m/$data_name\.$format_file_suffix/} @file_list) < 5){
		my $error = qr/\[NULL_Caption\]/o;
		print "===> Start to format database file!\n";
##!!!!!!!!不知道此处的将formatdb的错误信息输出到标准输出中时候可以
		open my $formatdb_out , "formatdb -i $input_database -p $format_type -a F -o T |";
		local $/ = undef;
		my $capture_error = <$formatdb_out>;
		if( $test =~ m/$error/){
			print "===> format database fail!Please check the input database file path!\n";
			print "ERROR information is $test \n";
			system 'echo 按下任意键继续 & pause';
			exit;
		}
		print "===> Database <$data_name> had been formated\n";
	}else{print "===> Database <$data_name> had been formated\n"}	
}


sub allblast{  
	my ($input_fasta,$input_database,$blast_type,$out) = @_;
	&format($input_fasta,$input_database,$blast_type_argument{$blast_type},$blast_path);
	# 进行BLAST
    my $tee_out_filename = $out;
	# my $tee_out_filename = File::Spec->catdir($out,File::Basename::basename($input_fasta) . File::Basename::basename($input_database) . ".txt");
	printf "===> Start to %s\n",$blast_type;
	# mkdir ($out) unless (-e $out);   # 新建结果文件夹
	my $fruit = `blastall -p $blast_type -i $input_fasta -d $input_database -m 8 | tee $tee_out_filename`;
	return ($fruit,$blast_type);
}

sub run_check{
	my $task = shift;
	my @task_argument = @_;
	IPC::Run::run([$task,@task_argument],\my($in,$out,$err));
	return ($out,$err);
}
