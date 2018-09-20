<?php

namespace AppBundle\Entity;

use Doctrine\ORM\Mapping as ORM;

/**
 * S
 *
 * @ORM\Table(name="""openspec"".""S""")
 * @ORM\Entity(repositoryClass="AppBundle\Repository\SRepository")
 */
class S
{
    /**
     * @var int
     *
     * @ORM\Column(name="id", type="integer")
     * @ORM\Id     
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


    public function __construct($type, $name = null)
    {
        $this->id = rand();
        $this->type = $type;
        $this->name = $name;
        $this->share = 7;
        $this->status = 10;
        $this->createUser  = 415;
        $this->createDate = new \DateTime();
        $this->lastUpdateUser = 415;
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

