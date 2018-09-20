<?php

namespace AppBundle\Entity;

use Doctrine\ORM\Mapping as ORM;

/**
 * Class S
 *
 * @ORM\Table(name="""openspec"".""S""")
 * @ORM\Entity(repositoryClass="AppBundle\Repository\SRepository")
 */
class S
{
    const USER = 415;
    const TYPE = 1;
    const STATUS = 10;
    const SHARE = 7;

    /**
     * @var int
     *
     * @ORM\Column(name="id", type="integer")
     * @ORM\Id
     * @ORM\GeneratedValue(strategy="SEQUENCE")
     * @ORM\SequenceGenerator(sequenceName="s_seq", allocationSize=1,initialValue=1) 
     */
    private $id;

    /**
     * @var int
     *
     * @ORM\Column(name="type", type="bigint")
     */
    private $type;

    /**
     * @var string
     *
     * @ORM\Column(name="name", type="string", length=255, nullable=true)
     */
    private $name;

    /**
     * @var int
     *
     * @ORM\Column(name="status", type="bigint")
     */
    private $status;

    
    /**
     * @var int
     *
     * @ORM\Column(name="share", type="bigint")
     */
    private $share;

    /**    
     *
     * @ORM\Column(name="create_user", type="bigint")
     */
    private $createUser;

    /**     
     *
     * @ORM\Column(name="create_date", type="datetime")
     */
    private $createDate;

    /**
     *      
     *
     * @ORM\Column(name="last_update_user", type="bigint")
     */
    private $lastUpdateUser;

    /**          
     *
     * @ORM\Column(name="last_update_date", type="datetime")
     */
    private $lastUpdateDate;


    public function __construct($name = null)
    {
        $this->id = rand();
        $this->type = $this::TYPE;
        $this->name = $name;
        $this->share = $this::SHARE;
        $this->status = $this::STATUS;
        $this->createUser  = $this::USER;
        $this->createDate = new \DateTime();
        $this->lastUpdateUser = $this::USER;
        $this->lastUpdateDate = new \DateTime();
    }


    /**
     * Get id
     *
     * @return int
     */
    public function getId()
    {
        return $this->id;
    }

    /**
     * Set type
     *
     * @param integer $type
     *
     * @return S
     */
    public function setType($type)
    {
        $this->type = $type;

        return $this;
    }

    /**
     * Get type
     *
     * @return int
     */
    public function getType()
    {
        return $this->type;
    }

    /**
     * Set name
     *
     * @param string $name
     *
     * @return S
     */
    public function setName($name)
    {
        $this->name = $name;

        return $this;
    }

    /**
     * Get name
     *
     * @return string
     */
    public function getName()
    {
        return $this->name;
    }
}

