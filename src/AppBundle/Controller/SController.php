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

}
