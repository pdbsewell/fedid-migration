/**
 * @author J Mapanao
 * @description This class will serve as JSON request from Salesforce to zkipster for Create Guest List scenario
 */
public class ZkipCreateUpdateGuestListRequest {
    public CGLRequest data;

    public class CGLRequest {
        public String type;
        public String id;
        public CGLAttributes attributes;
        public CGLRelationships relationships;
    }
    public class CGLAttributes {
        public String name;
    }
    public class CGLRelationships {
        public CGLEvent event;
    }
    public class CGLEvent {
        public CGLData data;
    }
    public class CGLData {
        public String type;
        public String id;
    }

    public static String createGuestListPayload(Campaign guestList, Boolean isCreate) {
        CGLAttributes clsAttributes = new CGLAttributes();
            clsAttributes.name = guestList.Name;

        CGLData clsData = new CGLData();
            clsData.type = 'events';
            clsData.id = guestList.Parent_ERDA_Event__r.Zkipster_Event_Id__c;

        CGLEvent clsEvent = new CGLEvent();
            clsEvent.data = clsData;

        CGLRequest clrCGLRequest = new CGLRequest();
            clrCGLRequest.type = 'guest-lists';
            clrCGLRequest.attributes = clsAttributes;

            if (isCreate) {
                CGLRelationships clsRelationships = new CGLRelationships();
                    clsRelationships.event = clsEvent;
                clrCGLRequest.relationships = clsRelationships;
            }
            else {
                clrCGLRequest.id = guestList.Zkipster_Guest_List_Id__c;
            }

        ZkipCreateUpdateGuestListRequest payLoad = new ZkipCreateUpdateGuestListRequest();
            payLoad.data = clrCGLRequest;

        System.debug('### result:' + JSON.serializePretty(payLoad));
        return JSON.serializePretty(payLoad);
    }
}
/*
NOTE: This is the sample json REQUEST for creating new Guest List in zkipster
{
    "data": {
        "type": "guest-lists",
        "attributes": {
            "name": "A new Guest List"
        },
        "relationships": {
            "event": {
                "data": {
                    "type": "events",
                    "id": "3"
                }
            }
        }
    }
}

NOTE: This is the sample json REQUEST for updating Guest List in zkipster
{
    "data": {
        "type": "guest-lists",
        "id": "22",
        "attributes": {
            "name": "A new Guest List - Updated!"
        }
    }
}
*/