<?php
declare(strict_types = 1);

namespace Mireiawen\Lumme;

use InfluxDB\Client;
use InfluxDB\Database;
use InfluxDB\Database\Exception;
use InfluxDB\Point;
use Mireiawen\Input\Env;

/**
 * The main application
 *
 * @package Mireiawen\Lumme
 */
class Application
{
	/**
	 * The InfluxDB measurement value
	 *
	 * @var string
	 */
	protected const INFLUX_MEASUREMENT = 'electricity';
	
	/**
	 * The CSV file encoding
	 *
	 * @var string
	 */
	protected const CSV_ENCODING = 'UCS-2';
	
	/**
	 * The delimiter char in the CSV file
	 *
	 * @var string
	 */
	protected const CSV_DELIMITER = ';';
	
	/**
	 * The amount of lines to skip from the beginning of the CSV file
	 *
	 * @var int
	 */
	protected const CSV_SKIP_LINES = 5;
	
	/**
	 * The current timezone
	 *
	 * @var \DateTimeZone
	 */
	protected $timezone;
	
	/**
	 * The input file handle
	 *
	 * @var resource $input
	 */
	protected $input;
	
	/**
	 * The InfluxDB connection
	 *
	 * @var Database
	 */
	protected $influxdb;
	
	/**
	 * Parse the data into the database
	 *
	 * @param string $input
	 *    The input filename
	 *
	 * @return int
	 *    Number of rows read
	 *
	 * @throws Exception
	 *    In case if InfluxDB errors
	 *
	 * @throws \InfluxDB\Exception
	 *    In case if InfluxDB errors
	 */
	public static function Run(string $input) : int
	{
		// Create the application
		$application = new self($input);
		
		// Seek over the information lines
		$application->Seek();
		
		// Go through all lines
		$points = [];
		while (TRUE)
		{
			try
			{
				$row = $application->ReadRow();
			}
				/** @noinspection BadExceptionsProcessingInspection */
			catch (\OutOfBoundsException $eof)
			{
				break;
			}
			
			$points[] = $application->CreatePoint($row);
		}
		
		$application->influxdb->writePoints($points, $application->influxdb::PRECISION_SECONDS);
		return count($points);
	}
	
	/**
	 * The main application constructor
	 *
	 * @param string $input_filename
	 */
	public function __construct(string $input_filename)
	{
		$env = new Env();
		$host = $env->GetAsString('INFLUXDB_HOSTNAME');
		$port = $env->GetAsInt('INFLUXDB_PORT', 8086);
		$database = $env->GetAsString('INFLUXDB_DATABASE');
		$username = $env->GetAsString('INFLUXDB_USERNAME', '');
		$password = $env->GetAsString('INFLUXDB_PASSWORD', '');
		$ssl = $env->GetAsBool('INFLUXDB_SSL', FALSE);
		
		// Open the input file
		$this->input = fopen($input_filename, 'rb');
		if ($this->input === FALSE)
		{
			throw new \InvalidArgumentException(sprintf('Unable to open %s for input', $input_filename));
		}
		
		// Connect to the database
		$influxdb = new Client($host, $port, $username, $password, $ssl);
		$this->influxdb = $influxdb->selectDB($database);
		
		// Initialize the timezone
		$this->timezone = new \DateTimeZone('Europe/Helsinki');
	}
	
	/**
	 * Clean up
	 */
	public function __destruct()
	{
		fclose($this->input);
	}
	
	/**
	 * Seek over the info lines in the file
	 */
	public function Seek() : void
	{
		for ($i = 0; $i < self::CSV_SKIP_LINES; $i++)
		{
			if (fgets($this->input) === FALSE)
			{
				throw new \InvalidArgumentException('Invalid input file');
			}
		}
	}
	
	/**
	 * Read a row from the provided input
	 *
	 * @return UsageRow
	 *
	 * @throws \InvalidArgumentException
	 *    In case the file timestamp is invalid
	 *
	 * @throws \OutOfBoundsException
	 *    In case the end of file is found
	 */
	public function ReadRow() : UsageRow
	{
		// Read the line
		$raw = fgets($this->input);
		if ($raw === FALSE)
		{
			if (feof($this->input))
			{
				throw new \InvalidArgumentException('Invalid input file');
			}
			
			throw new \OutOfBoundsException('End of file');
		}
		
		// Convert the input to UTF-8
		$utf8 = mb_convert_encoding($raw, 'UTF-8', self::CSV_ENCODING);
		if (empty($utf8))
		{
			throw new \OutOfBoundsException('End of file');
		}
		
		// Parse the CSV
		$row = str_getcsv($utf8, self::CSV_DELIMITER);
		
		// Parse the dates
		try
		{
			$begin = new \DateTime($row[0], $this->timezone);
			$end = new \DateTime($row[1], $this->timezone);
		}
		catch (\Exception $exception)
		{
			throw new \InvalidArgumentException($exception);
		}
		
		// Create the actual usage row
		return new UsageRow(
			$begin,
			$end,
			(float)str_replace(',', '.', $row[2]),
			(float)str_replace(',', '.', $row[4])
		);
	}
	
	/**
	 * Create a InfluxDB data point
	 *
	 * @param UsageRow $row
	 *    The input row to use
	 *
	 * @return Point
	 *    The data point created
	 *
	 * @throws Exception
	 *    In case if InfluxDB errors
	 */
	public function CreatePoint(UsageRow $row) : Point
	{
		return new Point(
			self::INFLUX_MEASUREMENT,
			NULL,
			[],
			['usage' => $row->GetUsage(), 'spot' => $row->GetSPOT(),],
			$row->GetBegin()->getTimestamp()
		);
	}
}
