/*
 * Copyright (c) 2019, UC Innovation, Inc.  All Rights Reserved.
 *                     http://www.ucinnovation.com
 *
 * This source code is licensed, not sold, and is subject to a written
 * license agreement.  Among other things, no portion of this source
 * code may be copied, transmitted, disclosed, displayed, distributed,
 * translated, used as the basis for a derivative work, or used, in
 * whole or in part, for any program or purpose other than its intended
 * use in compliance with the license agreement as part of UC Innovation's
 * software.  This source code and certain of the algorithms contained
 * within it are confidential trade secrets of UC Innovation, Inc.
 * and may not be used as the basis for any other
 * software, hardware, product or service.
 */
 
 @isTest
global class PORTAL_NewsMockTest implements HttpCalloutMock {
	// Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        String endPoint = req.getEndpoint();
        
        if(endPoint.contains('country=us') && req.getMethod() == 'GET') {
            res.setBody('{'
                            + '"status": "ok",'
                            + '"totalResults": 1,'
                            + '"articles": ['
                            + '    {'
                            + '        "source": {'
                            + '            "id": null,'
                            + '            "name": "Anandtech.com"'
                            + '        },'
                            + '        "author": "Anton Shilov",'
                            + '        "title": "Samsung",'
                            + '        "description": "Samsung has announced its second-generation 49-inch curved display supporting AMD&rsquo;s FreeSync 2 technology. The new CRG9 monitor features a considerably higher resolution and brightness...",'
                            + '        "url": "https://www.anandtech.com/show/13758/samsung-announces-crg9",'
                            + '        "urlToImage": "https://images.anandtech.com/doci/13758/samsung-49-curved-678_678x452.jpg",'
                            + '        "publishedAt": "2019-01-04T00:30:00Z",'
                            + '        "content": "Samsung has announced its second-generation 49-inch curved display supporting AMD’s FreeSync 2 technology. The new CRG9 monitor features a considerably higher resolution and brightness than the first-gen C49HG90 LCD introduced in mid-2017. Samsung was the fir… [+2933 chars]"'
                            + '    }'
                            + ']'
                        + '}');
        } else {
            res.setBody('{'
                            + '"status": "ok",'
                            + '"totalResults": 1,'
                            + '"articles": ['
                            + '    {'
                            + '        "source": {'
                            + '            "id": null,'
                            + '            "name": "Youtube.com"'
                            + '        },'
                            + '        "author": null,'
                            + '        "title": "North Korea",'
                            + '        "description":"North Korea\'s top diplomat in Italy, Jo Song Gil, has been missing for weeks, a South Korean lawmaker said, raising suspicions that he may have defected. #CN...",'
                            + '        "url": "https://www.youtube.com/watch?v=jl7D0vSka9s",'
                            + '        "urlToImage": "https://images.youtube.com/114458/North-Korea-Diplomat.jpg",'
                            + '        "publishedAt": "2019-01-04T00:54:09Z",'
                            + '        "content":"North Korea\'s top diplomat in Italy, Jo Song Gil, has been missing for weeks, a South Korean lawmaker said, raising suspicions that he may have defected. #CNN #News"'
                            + '    }'
                            + ']'
                        + '}');
        }
        res.setStatusCode(200);
        return res;
    }
}