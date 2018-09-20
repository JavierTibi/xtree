<?php
namespace AppBundle\Repository;

use Doctrine\ORM\EntityManager;
use Doctrine\ORM\EntityRepository;
use Doctrine\ORM\Mapping;

/**
 * Class ApiRepository
 * @package AppBundle\Repository
 */

class ApiRepository extends EntityRepository
{
    /** @var entity manager */
    protected $em;

    /**
     * ApiRepository constructor.
     *
     * @param EntityManager $em
     * @param Mapping\ClassMetadata $class
     */

    public function __construct(EntityManager $em, Mapping\ClassMetadata $class)
    {
        parent::__construct($em, $class);
        $this->setEm($em);
    }

    /**
     * Retorna un entity manager para área
     *
     * @return EntityManager
     */
    protected function getEm()
    {
        return $this->em;
    }

    /**
     * Setea un handler para un entity manager
     *
     * @param EntityManager $em
     */
    protected function setEm(EntityManager $em)
    {
        $this->em = $em;
    }

    /**
     * Persiste los datos y espera el flush
     *
     * @param $entity
     * @return Object
     */
    public function add($entity)
    {
        $this->persist($entity);

        return $entity;
    }

    /**
     * Persiste los datos y luego hace flush
     *
     * @param $entity
     * @return Object
     */
    public function save($entity)
    {
        $this->persist($entity);
        $this->flush();

        return $entity;
    }

    /**
     * Agrega la entidad para luego persistir los datos
     *
     * @param $entity
     */
    public function persist($entity)
    {
        $this->getEm()->persist($entity);
    }

    /**
     * Remueve una entidad
     *
     * @param $entity
     */
    public function remove($entity)
    {
        $this->delete($entity);
        $this->flush();
    }

    /**
     * Marcamos una entidad para ser eliminada
     * @param $entity
     */
    public function delete($entity)
    {
        $this->getEm()->remove($entity);
    }

    /**
     * Ejecuta un flush
     */
    public function flush()
    {
        $this->getEm()->flush();
    }

    /**
     * Begin Transaction
     */
    public function beginTransaction()
    {
        $this->getEm()->getConnection()->beginTransaction();
    }

    /**
     * Commit
     */
    public function commit()
    {
        $this->getEm()->getConnection()->commit();
    }

    /**
     * Rollback
     */
    public function rollback()
    {
        $this->getEm()->getConnection()->rollBack();
    }
}
