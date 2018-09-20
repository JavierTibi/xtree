<?php

namespace AppBundle\Tests\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class TreeControllerTest extends WebTestCase
{
    public function testGettree()
    {
        $client = static::createClient();

        $crawler = $client->request('GET', '/getTree');
    }

    public function testGetchild()
    {
        $client = static::createClient();

        $crawler = $client->request('GET', '/getChild');
    }

}
