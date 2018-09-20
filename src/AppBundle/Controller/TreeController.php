<?php

namespace AppBundle\Controller;

use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use FOS\RestBundle\Controller\Annotations as Rest;
use FOS\RestBundle\Controller\FOSRestController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use FOS\RestBundle\View\View;

class TreeController extends FOSRestController
{    
    /**
     * @Route("/getTree")         
     */
    public function getTreeAction()
    {
        $em = $this->getDoctrine()->getManager();       
        return $em->getRepository('AppBundle:Tree')->getTree();
  

        /*$data = array(
            array("id" => 1, "name" => "file 1", "order" => 5647, "countParents" => 1, "countChild" => 8),
            array("id" => 2, "name" => "file 2", "order" => 4547, "countParents" => 1, "countChild" => 6),
            array("id" => 3, "name" => "file 3", "order" => 4757, "countParents" => 2, "countChild" => 15),
            array("id" => 4, "name" => "file 4", "order" => 4875, "countParents" => 2, "countChild" => 3)                       
        );*/                                             
    }

        /**
     * @Rest\Put("/edit/{id}/order")
     */    
    public function editOrderAction($id)
    {
        $order = $request->get('order');  

        $node = $this->getDoctrine()->getRepository('AppBundle:Tree')->find($id);
        if ($node === null) {
            return new View("there are no node exist", Response::HTTP_NOT_FOUND);
        }
        $node->setOrder($order);

        $em = $this->getDoctrine()->getManager();
        $em->flush();
      
        return $node;
    }

    /**
     * @Route("/getChild/{idNode}")
     */
    public function getChildAction($idNode)
    {
        $em = $this->getDoctrine()->getManager();       
        return $em->getRepository('AppBundle:Tree')->getTreeByNodeId($idNode);
        
        /* $data = array(
            array("title" => "file.txt", "key" => 1),
            
            array(
                "title" => "Resources", 
                "key" => 2, 
                "folder" => true, 
                "children" => array(
                    array("title" => "Resources child 1", "key" => 3 ),
                    array("title" => "Resources child 2", "key" => 4 )
                )
            )
        );
                                 
        return $data; */
    }
}
