require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'CSS::Tiny',
	'VERSION_FROM' => 'lib/CSS/Tiny.pm',
	'PREREQ_PM'    => {
		Test::More => 0,
		FindBin    => 0,
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'Read/Write .css stylesheets with as little code as possible',
	) : (),
);
