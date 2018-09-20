<?php

namespace AppBundle\Controller;

use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use FOS\RestBundle\Controller\Annotations as Rest;
use FOS\RestBundle\Controller\FOSRestController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use FOS\RestBundle\View\View;
use AppBundle\Entity\User;

class TreeController extends FOSRestController
{    
    /**
     * @Rest\Get("/getTree")
     */    
    public function getAction()
    {
      $restresult = $this->getDoctrine()->getRepository('AppBundle:Tree')->findAll();
        if ($restresult === null) {
          return new View("there are no tree exist", Response::HTTP_NOT_FOUND);
        }
        return $restresult;
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
}
