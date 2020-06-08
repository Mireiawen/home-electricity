<?php
declare(strict_types = 1);

use GetOpt\ArgumentException\Invalid;
use GetOpt\ArgumentException\Missing;
use GetOpt\GetOpt;
use GetOpt\Option;
use Mireiawen\Nordpool\Application;

require_once('vendor/autoload.php');

if (!function_exists('_'))
{
	function _(string $message) : string
	{
		return $message;
	}
}

// Read the command line
$options = new GetOpt();

$input_file = Option::create('i', 'input', GetOpt::REQUIRED_ARGUMENT);
$input_file->setArgumentName('input Excel file');
$input_file->setDescription('The report file to read');

$options->addOptions([$input_file]);
/** @noinspection BadExceptionsProcessingInspection */
try
{
	$options->process();
	$input = $options->getOption('input');
	
	if ($input === NULL)
	{
		throw new Missing('The input filename is missing');
	}
	
	if (!is_readable($input))
	{
		throw new Invalid('The input filename does not exist or is not readable');
	}
	
	// Run the application
	$rows = Application::Run($input);
	printf("Read %d rows\n", $rows);
}
catch (Exception $exception)
{
	// Catch errors
	printf("Error: %s\n\n%s", $exception->getMessage(), $options->getHelpText());
	exit(1);
}
