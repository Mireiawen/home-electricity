<?php
declare(strict_types = 1);

namespace Mireiawen\Lumme;


/**
 * Single usage row
 *
 * @package Mireiawen\Lumme
 */
class UsageRow
{
	/**
	 * The begin time of the entry
	 *
	 * @var \DateTime
	 */
	protected $begin;
	
	/**
	 * The end time of the entry
	 *
	 * @var \DateTime
	 */
	protected $end;
	
	/**
	 * The measured usage
	 *
	 * @var float
	 */
	protected $usage;
	
	/**
	 * The SPOT price
	 *
	 * @var float
	 */
	protected $spot;
	
	/**
	 * UsageRow constructor.
	 *
	 * @param \DateTime $begin
	 * @param \DateTime $end
	 * @param float $usage
	 * @param float $spot
	 */
	public function __construct(\DateTime $begin, \DateTime $end, float $usage, float $spot)
	{
		$this->begin = $begin;
		$this->end = $end;
		$this->usage = $usage;
		$this->spot = $spot;
	}
	
	public function GetUsage() : float
	{
		return $this->usage;
	}
	
	public function GetSPOT() : float
	{
		return $this->spot;
	}
	
	public function GetBegin() : \DateTime
	{
		return $this->begin;
	}
	
	public function GetEnd() : \DateTime
	{
		return $this->end;
	}
}
