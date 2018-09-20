<?php

namespace AppBundle\Entity;

use Doctrine\ORM\Mapping as ORM;

/**
 * Tree
 *
 * @ORM\Table(name="""openspec"".""Tree""")
 * @ORM\Entity(repositoryClass="AppBundle\Repository\TreeRepository")
 */
class Tree
{

    /**
     * @var int
     * @ORM\Id
     * @ORM\Column(name="child", type="bigint", unique=true)
     */
    private $Child;

    /**
     * @var int
     *
     * @ORM\Column(name="n_order", type="bigint")
     */
    private $Order;

    /**
     * @var int     
     * @ORM\Id
     * @ORM\Column(name="parent", type="bigint", unique=true)
     */
    private $parent;

    public function __construct($id, $order, $parent)
    {
        $this->Child = $id;
        $this->Order = $order;
        $this->parent = $parent;
    }


    /**
     * Set child
     *
     * @param integer $child
     *
     * @return Tree
     */
    public function setChild($child)
    {
        $this->child = $child;

        return $this;
    }

    /**
     * Get child
     *
     * @return int
     */
    public function getChild()
    {
        return $this->child;
    }

    /**
     * Set order
     *
     * @param integer $order
     *
     * @return Tree
     */
    public function setOrder($order)
    {
        $this->order = $order;

        return $this;
    }

    /**
     * Get order
     *
     * @return int
     */
    public function getOrder()
    {
        return $this->order;
    }

    /**
     * Set parent
     *
     * @param integer $parent
     *
     * @return Tree
     */
    public function setParent($parent)
    {
        $this->parent = $parent;

        return $this;
    }

    /**
     * Get parent
     *
     * @return int
     */
    public function getParent()
    {
        return $this->parent;
    }
}

