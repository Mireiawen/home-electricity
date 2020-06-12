<?php
declare(strict_types = 1);

namespace Mireiawen\Nordpool;

use InfluxDB\Client;
use InfluxDB\Database;
use InfluxDB\Database\Exception;
use InfluxDB\Point;
use Mireiawen\Input\Env;

/**
 * The main application
 *
 * @package Mireiawen\Nordpool
 */
class Application
{
	/**
	 * The InfluxDB measurement value
	 *
	 * @var string
	 */
	protected const INFLUX_MEASUREMENT = 'spot';
	
	/**
	 * Quick hack to fix the time zone difference between source data and our timezone
	 *
	 * @var string
	 */
	protected const SOURCE_TIMEZONE_FIX = '+1 hour';
	
	/**
	 * The multiplier to use for turning the SPOT price to s/kWh
	 */
	protected const SPOT_MULTIPLIER = 0.1;
	
	/**
	 * The multiplier to use for turning the SPOT price to include the VAT tax rate
	 */
	protected const SPOT_TAX_MULTIPLIER = 1.24;
	
	/**
	 * The row where the date should be found from
	 *
	 * @var int
	 */
	protected const DATE_ROW = 1;
	
	/**
	 * The column where the time range should be found from
	 *
	 * @var int
	 */
	protected const TIME_COLUMN = 1;
	
	/**
	 * The first data row
	 *
	 * @var int
	 */
	protected const DATA_FIRST_ROW = 2;
	
	/**
	 * The last data row
	 *
	 * @var int
	 */
	protected const DATA_LAST_ROW = self::DATA_FIRST_ROW + 24;
	
	/**
	 * The first data column
	 *
	 * @var int
	 */
	protected const DATA_FIRST_COLUMN = 2;
	
	/**
	 * The current timezone
	 *
	 * @var \DateTimeZone
	 */
	protected $timezone;
	
	/**
	 * The input file handle
	 *
	 * @var array $input
	 */
	protected $input;
	
	/**
	 * The InfluxDB connection
	 *
	 * @var Database
	 */
	protected $influxdb;
	
	/**
	 * Current column
	 *
	 * @var int
	 */
	protected $column;
	
	/**
	 * Current row
	 *
	 * @var int
	 */
	protected $row;
	
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
		
		// Go through all lines
		$points = [];
		while (TRUE)
		{
			try
			{
				$row = $application->ReadRow();
			}
				/** @noinspection BadExceptionsProcessingInspection */
			catch (\OutOfBoundsException $oob)
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
		$document = new \DOMDocument();
		$document->loadHTMLFile($input_filename);
		$this->Parse($document);
		
		// Set the beginning for values
		$this->row = self::DATA_FIRST_ROW;
		$this->column = self::DATA_FIRST_COLUMN;
		
		// Connect to the database
		$influxdb = new Client($host, $port, $username, $password, $ssl);
		$this->influxdb = $influxdb->selectDB($database);
		
		// Initialize the timezone
		$this->timezone = new \DateTimeZone('Europe/Helsinki');
	}
	
	/**
	 * Read a row from the provided input
	 *
	 * @return SpotRow
	 *
	 * @throws \OutOfBoundsException
	 *    In case non-existing cell is read (likely end of table)
	 *
	 * @throws \InvalidArgumentException
	 *    In case the file timestamp is invalid
	 */
	public function ReadRow() : SpotRow
	{
		// Read the line
		$date = $this->GetCell(self::DATE_ROW, $this->column);
		$time = $this->GetCell($this->row, self::TIME_COLUMN);
		$spot = $this->GetCell($this->row, $this->column);
		[$begin, $end] = explode('-', $time, 2);
		$begin = trim($begin, " \t\n\r\0\x0B\xC2\xA0");
		$end = trim($end, " \t\n\r\0\x0B\xC2\xA0");
		$spot = trim($spot, " \t\n\r\0\x0B\xC2\xA0");
		$begin = sprintf('%s %02d:00', $date, (int)$begin);
		$end = sprintf('%s %02d:00', $date, (int)$end);
		
		// Parse the SPOT from EUR/MWh to s/kWh
		$spot = (float)str_replace(',', '.', $spot) * self::SPOT_MULTIPLIER * self::SPOT_TAX_MULTIPLIER;
		
		// Parse the dates
		/** @noinspection BadExceptionsProcessingInspection */
		try
		{
			$begin = new \DateTime($begin, $this->timezone);
			$end = new \DateTime($end, $this->timezone);
			$begin->modify(self::SOURCE_TIMEZONE_FIX);
			$end->modify(self::SOURCE_TIMEZONE_FIX);
		}
		catch (\Exception $exception)
		{
			throw new \InvalidArgumentException($exception);
		}
		
		// Move the pointer
		$this->row++;
		
		if ($this->row === self::DATA_LAST_ROW)
		{
			$this->row = self::DATA_FIRST_ROW;
			$this->column++;
		}
		
		// Create the actual SPOT row
		return new SpotRow(
			$begin,
			$end,
			$spot
		);
	}
	
	/**
	 * Create a InfluxDB data point
	 *
	 * @param SpotRow $row
	 *    The input row to use
	 *
	 * @return Point
	 *    The data point created
	 *
	 * @throws Exception
	 *    In case if InfluxDB errors
	 */
	public function CreatePoint(SpotRow $row) : Point
	{
		return new Point(
			self::INFLUX_MEASUREMENT,
			NULL,
			[],
			['spot' => $row->GetSPOT(),],
			$row->GetBegin()->getTimestamp()
		);
	}
	
	/**
	 * @param int $row
	 *    The row to read from
	 *
	 * @param int $column
	 *    The column to read from
	 *
	 * @return string
	 *    The cell contents
	 *
	 * @throws \OutOfBoundsException
	 *    In case end of file is likely reached, as in out of table bounds
	 */
	protected function GetCell(int $row, int $column) : string
	{
		if (!isset($this->input[$row - 1][$column - 1]))
		{
			throw new \OutOfBoundsException('Cell does not exist');
		}
		return $this->input[$row - 1][$column - 1];
	}
	
	/**
	 * Parse the table out of the DOM document
	 *
	 * @param \DOMDocument $input
	 */
	protected function Parse(\DOMDocument $input) : void
	{
		$data = [];
		$data_table = $input->getElementById('datatable');
		if ($data_table === NULL)
		{
			return;
		}
		
		$rows = $data_table->getElementsByTagName('tr');
		foreach ($rows as $row)
		{
			$columns = [];
			foreach ($row->childNodes as $column)
			{
				if ($column->tagName === 'td' || $column->tagName === 'th')
				{
					$columns[] = $column->nodeValue;
				}
			}
			$data[] = $columns;
		}
		
		$this->input = $data;
	}
}
