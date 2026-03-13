/*
 * This class will serve as JSON request from Salesforce to zkipster for CREATE EVENT Scenario
 * NOTE: used '0_0' to replace '-' when creating the variable name due to variable issue. See original format in below comment
 */
public class ZkipCreateUpdateEventRequest {
    public CERequest data {get;set;}
    
    public class CERequest {
        public String type {get;set;}
        public String id {get;set;}
        public CEAttributes attributes {get;set;}
    }
    
    public class CEAttributes {
        public String name {get;set;}
        public String event0_0type {get;set;}
        public String date0_0utc {get;set;}
        public String end0_0date0_0utc {get;set;}
        public String timezone0_0universal0_0id {get;set;}
        public String location {get;set;}
        public CELocationAddress location0_0address {get;set;}
        public CEAddons add0_0ons {get;set;}
    }
    
    public class CELocationAddress {
        public String address0_0line {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String zip {get;set;}
        public String country {get;set;}
    }
    
    public class CEAddons {
        public Boolean seating0_0charts0_0enabled {get;set;}
        public Boolean picture0_0source0_0enabled {get;set;}
        public Boolean badge0_0print0_0enabled {get;set;}
        public Boolean rsvp0_0enabled {get;set;}
    }

    public static String createEventPayload(Campaign camp, Boolean isUpdate) {
        // Create location-address
        CELocationAddress locAdd = new CELocationAddress();
            locAdd.address0_0line = camp.Event_Street__c; // get value from campaign's address line custom field
            locAdd.city = camp.Event_City__c; // get value from campaign's city custom field
            locAdd.state = camp.Event_State__c; // get value from campaign's state custom field
            locAdd.zip = camp.Event_Zip__c; // get value from campaign's zip custom field
            locAdd.country = camp.Event_Country__c; // get value from campaign's country custom field

        // Create add-ons
        CEAddons addOns = new CEAddons();
            addOns.seating0_0charts0_0enabled = false; // default to false
            addOns.picture0_0source0_0enabled = false; // default to false
            addOns.badge0_0print0_0enabled = false; // default to false
            addOns.rsvp0_0enabled = true; // default to true
            
        // Create attributes
        CEAttributes attr = new CEAttributes();
        attr.name = camp.Name; // get value from campaign's name standard field
        attr.event0_0type = camp.Type; // where to get the value? picklist values from available from zkipster are Corporate/Social/Gala/Launch/Campaign/Other
        attr.date0_0utc = camp.Event_Start_DateTime__c.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); // get the value from campaign's Event_Start_Date__c (if not in utc format, needs to convert to utc)
        attr.end0_0date0_0utc = camp.Event_End_DateTime__c.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); //get value from campaign's Event_End_Date__c (if not in utc format, needs to convert to utc)
        attr.timezone0_0universal0_0id = 'Australia/Melbourne'; //get value from Event_Timezone__c. Default to 'Australia/Melbourne' or is it event can be set outside Australia?
        attr.location = (String.isNotBlank(camp.Event_Location__c)) ? camp.Event_Location__c : '';
        attr.location0_0address = locAdd;
        attr.add0_0ons = addOns;

        CERequest ceReq = new CERequest();
            ceReq.type = 'events';
            ceReq.attributes = attr;

        if (isUpdate) {
            ceReq.id = camp.Zkipster_Event_Id__c;
        }
        
        ZkipCreateUpdateEventRequest payLoad = new ZkipCreateUpdateEventRequest();
            payLoad.data = ceReq;

        String tokenizedPayload = JSON.serializePretty(payLoad);
        return fixVariables(tokenizedPayload);
    }
    
    public static String fixVariables(String payload) {
        String target = '0_0';
        String replacement = '-';
        return payload.replace(target, replacement);
    }
}

/*
This is the example request given from zkipster API Documentation for "Add New Event"
-------------------------------------------------------------------------------------
String json = '{'+
    '  "data": {'+
    '    "type": "events",'+
    '    "attributes": {'+
    '      "name": "ACME Fundraising Event 2018",'+
    '      "event-type": "Gala",'+
    '      "date-utc": "2018-10-25T19:30:00Z",'+
    '      "end-date-utc": "2018-10-25T23:30:00Z",'+
    '      "timezone-universal-id": "Europe/London",'+
    '      "location": "The O2 Arena",'+
    '      "location-address": {'+
    '        "address-line": "Peninsula Square, London SE10 0DX",'+
    '        "city": "London",'+
    '        "state": null,'+
    '        "zip": null,'+
    '        "country": "England",'+
    '        "latitude": 51.5023,'+
    '        "longitude": 0.00313'+
    '      },'+
    '      "add-ons": {'+
    '        "seating-charts-enabled": true,'+
    '        "picture-source-enabled": false,'+
    '        "badge-print-enabled": false,'+
    '        "rsvp-enabled": true'+
    '      }'+
    '    }'+
    '  }'+
    '}';
-------------------------------------------------------------------------------------
{
  "data": {
    "type": "events",
    "attributes": {
      "name": "ACME Fundraising Event 2018",
      "event-type": "Gala",
      "date-utc": "2018-10-25T19:30:00Z",
      "end-date-utc": "2018-10-25T23:30:00Z",
      "timezone-universal-id": "Europe/London",
      "location": "The O2 Arena",
      "location-address": {
        "address-line": "Peninsula Square, London SE10 0DX",
        "city": "London",
        "state": null,
        "zip": null,
        "country": "England",
        "latitude": 51.5023,
        "longitude": 0.00313
      },
      "add-ons": {
        "seating-charts-enabled": true,
        "picture-source-enabled": false,
        "badge-print-enabled": false,
        "rsvp-enabled": true
      }
    }
  }
}
*/