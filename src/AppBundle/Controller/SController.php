<?php

namespace AppBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use FOS\RestBundle\Controller\Annotations as Rest;
use FOS\RestBundle\Controller\FOSRestController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use FOS\RestBundle\View\View;
use AppBundle\Entity\S;
use AppBundle\Entity\Tree;

class SController extends FOSRestController
{
    /**
     * @Rest\Put("/edit/{id}/name")
     */    
    public function editNameAction(Request $request, $id)
    {
        $name = $request->get('name');  

        $s = $this->getDoctrine()->getRepository('AppBundle:S')->find($id);
        if ($s === null) {
            return new View("there are no node exist", Response::HTTP_NOT_FOUND);
        }
        $s->setName($name);

        $em = $this->getDoctrine()->getManager();
        $em->flush();
      
        return $s;
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
            $s = new S($params['type'], $params['name']);            
            $em->persist($s);
            $em->flush();
            $treeNode = new Tree($s->getId(), $params['order'], $params['parent']);
            $em->persist($treeNode);
            $em->flush();                
            $em->getConnection()->commit();
            return $treeNode;
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

}
