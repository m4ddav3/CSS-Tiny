require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'CSS::Tiny',
	'VERSION_FROM' => 'lib/CSS/Tiny.pm',
	'PREREQ_PM'    => {
		Test::Simple => 0,
		FindBin      => 0,
		Fcntl        => 0,
	},	
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (adam@ali.as)',
		'ABSTRACT' => 'Read/Write .css stylesheets with as little code as possible',
	) : (),
);
