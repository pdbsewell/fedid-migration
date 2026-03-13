/**
 * @author J Mapanao
 * @description This class is used for HttpResponse for Create Guest List API Callout
 *
 */
public class ZkipCreateUpdateGuestListResponse {
    public Cls_Links links;
    public Cls_Data data;
    
    public class Cls_Links {
        public String self;
        public String related;
    }
    
    public class Cls_Data {
        public String type;
        public String id;
        public Cls_Attributes attributes;
        public Cls_Relationships relationships;
    }
    
    public class Cls_Attributes {
        public String name;
    }
    
    public class Cls_Relationships {
        public Cls_Guests guests;
        public Cls_Event event;
    }
    
    public class Cls_Guests {
        public Cls_Links links;
    }
    
    public class Cls_Event {
        public Cls_Links links;
    }
    
    public static ZkipCreateUpdateGuestListResponse parse(String json){
        return (ZkipCreateUpdateGuestListResponse) System.JSON.deserialize(json, ZkipCreateUpdateGuestListResponse.class);
    }
    
    /*
    static testMethod void testParse() {
        String json = '{'+
        '  "links": {'+
        '    "self": "/guest-lists/25"'+
        '  },'+
        '  "data": {'+
        '    "type": "guest-lists",'+
        '    "id": "25",'+
        '    "attributes": {'+
        '      "name": "A new Guest List"'+
        '    },'+
        '    "relationships": {'+
        '      "guests": {'+
        '        "links": {'+
        '          "self": "/guest-lists/25/relationships/guests",'+
        '          "related": "/guest-lists/25/guests"'+
        '        }'+
        '      },'+
        '      "event": {'+
        '        "links": {'+
        '          "self": "/guest-lists/25/relationships/event",'+
        '          "related": "/guest-lists/25/event"'+
        '        }'+
        '      }'+
        '    }'+
        '  }'+
        '}';
        ZkipCreateUpdateGuestListResponse obj = parse(json);
        System.assert(obj != null);
    }
    */
}

/*
NOTE: This is the sample json RESPONSE for creating new Guest List in zkipster
{
  "links": {
    "self": "/guest-lists/25"
  },
  "data": {
    "type": "guest-lists",
    "id": "25",
    "attributes": {
      "name": "A new Guest List"
    },
    "relationships": {
      "guests": {
        "links": {
          "self": "/guest-lists/25/relationships/guests",
          "related": "/guest-lists/25/guests"
        },
        "data": []
      },
      "event": {
        "links": {
          "self": "/guest-lists/25/relationships/event",
          "related": "/guest-lists/25/event"
        }
      }
    }
  }
}

NOTE: This is the sample json RESPONSE for updating Guest List in zkipster
{
  "links": {
    "self": "/v1/guest-lists/22"
  },
  "data": {
    "type": "guest-lists",
    "id": "22",
    "attributes": {
      "name": "Unit Test Guest List - Updated!"
    },
    "relationships": {
      "guests": {
        "links": {
          "self": "/v1/guest-lists/22/relationships/guests",
          "related": "/v1/guest-lists/22/guests"
        },
        "data": []
      },
      "event": {
        "links": {
          "self": "/v1/guest-lists/22/relationships/event",
          "related": "/v1/guest-lists/22/event"
        }
      }
    }
  }
}
*/