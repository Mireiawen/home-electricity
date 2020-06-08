<?php
declare(strict_types = 1);

namespace Mireiawen\Nordpool;


/**
 * Single SPOT price row
 *
 * @package Mireiawen\Nordpool
 */
class SpotRow
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
	 * @param float $spot
	 */
	public function __construct(\DateTime $begin, \DateTime $end, float $spot)
	{
		$this->begin = $begin;
		$this->end = $end;
		$this->spot = $spot;
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