<?php

namespace AppBundle\Controller;

use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use FOS\RestBundle\Controller\Annotations as Rest;
use FOS\RestBundle\Controller\FOSRestController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use FOS\RestBundle\View\View;
use AppBundle\Entity\S;
use AppBundle\Entity\Tree;

class TreeController extends FOSRestController
{   

    /**
     * @Rest\Get("/getTreeChildren")         
     */
    public function getTreeChildren() 
    {
        $em = $this->getDoctrine()->getManager();       
        $arr = $em->getRepository('AppBundle:Tree')->getTree();  

        return $this->getTreeOrder($arr);
    }

    /**
     * @Rest\Get("/getTree")         
     */
    public function getTreeAction()
    {
        $em = $this->getDoctrine()->getManager();       
        return $em->getRepository('AppBundle:Tree')->getTree();                                               
    }

    /**
     * @Rest\Get("/getChild/{idNode}")
     */
    public function getChildAction($idNode)
    {
        $em = $this->getDoctrine()->getManager();       
        $arr = $em->getRepository('AppBundle:Tree')->getTreeByNodeId($idNode);         
        return $this->getTreeOrder($arr);       
    }

    /**
     * @Rest\Get("/getRoot")         
     */
    public function getRootAction()
    {
        $em = $this->getDoctrine()->getManager();       
        return $em->getRepository('AppBundle:Tree')->getRoot();                                               
    }

    /**
     * @Rest\Put("/edit/{id}/parent/{idParent}/order")
     */    
    public function editOrderAction(Request $request, $id, $idParent)
    {
        $order = $request->get('order');  

        $node = $this->getDoctrine()->getRepository('AppBundle:Tree')->findOneBy(['Child' => $id, 'parent' => $idParent]);            
        if ($node === null) {
            return new View("there are no node exist", Response::HTTP_NOT_FOUND);
        }
        $node->setOrder($order);

        $em = $this->getDoctrine()->getManager();
        $em->flush();
      
        return $node;
    }

    /**
     * @Rest\Post("/new")
     */
    public function createAction(Request $request)
    {
        $params = $request->request->all();
        $em = $this->getDoctrine()->getManager();        
        $em->getConnection()->beginTransaction(); // suspend auto-commit
        
        try {        
            $s = new S($params['name']);            
            $em->persist($s);
            $em->flush();
            
            if (isset($params['parent']) && !is_null($params['parent']) ) {
                $treeNode = new Tree($s->getId(), $params['order'], $params['parent']);
                $em->persist($treeNode);
                $em->flush();                           
                $nodePersisted = $em->getRepository('AppBundle:Tree')->getNodeId($treeNode->getChild(), $treeNode->getParent());             
            } 

            $em->getConnection()->commit();

            $result = [
                "ID" => $s->getId(),
                "Name" => $s->getName(),
                "Order" => (isset($treeNode)) ? $treeNode->getOrder() : 0,
                "parent" => (isset($treeNode)) ? $treeNode->getParent() : null,
                "ParentsCount" => (isset($nodePersisted[0]->ParentsCount)) ? $nodePersisted[0]->ParentsCount : 0,
                "ChildrenCount" => 0
            ];

            return $result;          
                                                
        } catch (Exception $e) {
            $em->getConnection()->rollBack();
            throw $e;
        }        
    }

    /**
     * @Rest\Delete("/delete/{id}/parent/{idparent}")
     */
    public function deleteAction($id, $idparent)
    {    
        $em = $this->getDoctrine()->getManager();                
        $em->getConnection()->beginTransaction(); // suspend auto-commit
        try {    
            $treeNode = $this->getDoctrine()->getRepository('AppBundle:Tree')->findOneBy(['Child' => $id, 'parent' => $idparent]);                    
            $s = $this->getDoctrine()->getRepository('AppBundle:S')->find($id);
            $em->remove($treeNode);            
            $em->remove($s);                        
            $em->flush();                
            $em->getConnection()->commit();            
        } catch (Exception $e) {
            $em->getConnection()->rollBack();
            throw $e;
        }   
    }

    private function getTreeOrder($arr) {
        $new = array();
        foreach ($arr as $a){
            $new[$a['parent']][] = $a;
        }
                
        $tree = $this->createTree($new, array($arr[0]));
        return $tree;                    
    }

    private function createTree(&$list, $parent){                
        $tree = array();
        foreach ($parent as $k=>$l){            
            if(isset($list[$l['ID']])){
                $l['children'] = $this->createTree($list, $list[$l['ID']]);
            }
            $tree[] = $l;
        } 
        return $tree;
    }

}
