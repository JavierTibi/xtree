<?php

namespace AppBundle\Repository;

/**
 * TreeRepository
 *
 * This class was generated by the Doctrine ORM. Add your own custom
 * repository methods below.
 */
class TreeRepository extends ApiRepository
{

    public function getRoot() {
        $RAW_QUERY = 'SELECT * FROM openspec.usp_GetTree()';
        
        $statement = $this->getEm()->getConnection()->prepare($RAW_QUERY);
        $statement->execute();

        return $statement->fetchAll();
    }

    public function getTree() {
        $RAW_QUERY = 'SELECT * FROM openspec.usp_GetTree();';
        
        $statement = $this->getEm()->getConnection()->prepare($RAW_QUERY);
        $statement->execute();

        return $statement->fetchAll();        
    }

    public function getTreeByNodeId($id) {
        $RAW_QUERY = 'SELECT * FROM openspec.usp_gettreefromnode('.$id.');';
        
        $statement = $this->getEm()->getConnection()->prepare($RAW_QUERY);
        $statement->execute();

        return $statement->fetchAll();        
    }

    public function getNodeId($id, $idParent = null) {        
        $RAW_QUERY = 'SELECT * FROM openspec.usp_GetTree() WHERE "ID" = '.$id.' AND "parent" = '.$idParent.';';
        
        $statement = $this->getEm()->getConnection()->prepare($RAW_QUERY);
        $statement->execute();

        return $statement->fetchAll();        
    }

        
}
