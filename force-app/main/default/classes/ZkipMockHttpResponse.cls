@isTest
global class ZkipMockHttpResponse implements HttpCalloutMock {
    
    Boolean isSuccess;
    String method;
    String response;
    
    public ZkipMockHttpResponse(Boolean pIsSuccess, String pMethod, String pResponse) {
        isSuccess = pIsSuccess;
        method = pMethod;
        response = pResponse;
    }
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        
        res.setHeader('Content-Type', 'application/json');
        
        if (!isSuccess) {
            
            res.setBody('{"errors": [{"title": "BadRequest","detail": "The request was not accepted because it has malformed syntax.","status": "400"}]}');
            res.setStatusCode(400);
            
        } else {
            
            res.setBody(''+response);
            if (method == ZkipConstants.METHOD_POST) {
                res.setStatusCode(201);
            } else if (method == ZkipConstants.METHOD_GET || method == ZkipConstants.METHOD_PATCH) {
                res.setStatusCode(200);
            }
            
        }
        
        return res;
    }

    public static String createEventResponse = '{'
            +   '"links": {'
            +       '"self": "/v1/events/22942"'
            +   '},'
            +   '"data": {'
            +       '"type": "events",'
            +       '"id": "22942"'
            +   '}'
            +'}';

    public static String updateEventResponse = '{'
            +   '"links": {'
            +       '"self": "/v1/events/12345"'
            +   '},'
            +   '"data": {'
            +       '"type": "events",'
            +       '"id": "12345"'
            +   '}'
            +'}';
    
    public static String createGuestListResponse = '{'+
            '  "links": {'+
            '    "self": "/guest-lists/25"'+
            '  },'+
            '  "data": {'+
            '    "type": "guest-lists",'+
            '    "id": "121212",'+
            '    "attributes": {'+
            '      "name": "A new Guest List"'+
            '    }'+
            '  }'+
            '}';
    
    public static String addGuestResponse = '{'+
            '  "links": {'+
            '    "self": "/guests/11"'+
            '  },'+
            '  "data": {'+
            '    "type": "guests",'+
            '    "id": "11"'+
            '  }'+
            '}';
    
    /*public static String getGuestsFromGuestListResponse = '{'+
            '  "data": ['+
            '    {'+
            '      "type": "guests",'+
            '      "id": "0000001"'+
            '    },'+
            '    {'+
            '      "type": "guests",'+
            '      "id": "0000002"'+
            '    }'+
            '  ]'+
            '}';*/

    public static String getGuestsFromGuestListResponse = '{'+
            '  "data": ['+
            '    {'+
            '      "type": "guests",'+
            '      "id": "300001",'+
            '      "attributes": {'+
            '        "first-name": "Maria",'+
            '        "last-name": "Reinard",'+
            '        "contact-details": {'+
            '          "organization": "Facebook",'+
            '          "country-code": "US",'+
            '          "phone-number": "846562354",'+
            '          "email": "maria@sasdasd.pt"'+
            '        },'+
            '        "notification-emails": null,'+
            '        "notification-phone-numbers": null,'+
            '        "note": "Google Blogger",'+
            '        "total-guests": 0,'+
            '        "plus-ones-checked": 0,'+
            '        "main-guest-checked": false,'+
            '        "checkin-date": null,'+
            '        "status": "",'+
            '        "custom-field-values": ['+
            '          {'+
            '            "custom-field-id": 7,'+
            '            "field-name": "UniCRM Campaign Member Id",'+
            '            "value": "98765"'+
            '          }'+
            '        ]'+
            '      },'+
            '      "relationships": {'+
            '        "guest-list": {'+
            '          "data": {'+
            '            "type": "guest-lists",'+
            '            "id": "200001"'+
            '          }'+
            '        }'+
            '      }'+
            '    },'+
            '    {'+
            '      "type": "guests",'+
            '      "id": "300002",'+
            '      "attributes": {'+
            '        "first-name": "Maria",'+
            '        "last-name": "Reinard",'+
            '        "contact-details": {'+
            '          "organization": "Facebook",'+
            '          "country-code": "US",'+
            '          "phone-number": "846562354",'+
            '          "email": "maria@sasdasd.pt"'+
            '        },'+
            '        "notification-emails": null,'+
            '        "notification-phone-numbers": null,'+
            '        "note": "Google Blogger",'+
            '        "total-guests": 0,'+
            '        "plus-ones-checked": 0,'+
            '        "main-guest-checked": false,'+
            '        "checkin-date": null,'+
            '        "status": "",'+
            '        "custom-field-values": ['+
            '          {'+
            '            "custom-field-id": 7,'+
            '            "field-name": "UniCRM Campaign Member Id",'+
            '            "value": null'+
            '          }'+
            '        ]'+
            '      },'+
            '      "relationships": {'+
            '        "guest-list": {'+
            '          "data": {'+
            '            "type": "guest-lists",'+
            '            "id": "200001"'+
            '          }'+
            '        }'+
            '      }'+
            '    }'+
            '  ]'+
            '}';
}