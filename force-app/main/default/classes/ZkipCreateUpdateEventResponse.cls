/**
 * @author J Mapanao
 * @description This class will serve as JSON response from Salesforce to zkipster for Create or Update Event scenario
 */
public class ZkipCreateUpdateEventResponse {
    
    public Links links {get;set;} 
    public Data data {get;set;} 

    public ZkipCreateUpdateEventResponse(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'links') {
                        links = new Links(parser);
                    } else if (text == 'data') {
                        data = new Data(parser);
                    } else {
                        System.debug(LoggingLevel.WARN, 'ZkipCreateUpdateEventResponse consuming unrecognized property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    
    public static ZkipCreateUpdateEventResponse parse(String json) {
        System.JSONParser parser = System.JSON.createParser(json);
        return new ZkipCreateUpdateEventResponse(parser);
    }
    
    public class Links {
        public String self {get;set;} 
        public String related {get;set;} 

        public Links(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'self') {
                            self = parser.getText();
                        } else if (text == 'related') {
                            related = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Links consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class Data {
        public String type {get;set;} // in json: type
        public String id {get;set;} 
        public Attributes attributes {get;set;} 
        public Relationships relationships {get;set;} 

        public Data(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'type') {
                            type = parser.getText();
                        } else if (text == 'id') {
                            id = parser.getText();
                        } else if (text == 'attributes') {
                            attributes = new Attributes(parser);
                        } else if (text == 'relationships') {
                            relationships = new Relationships(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class Attributes {
        public String name {get;set;} 
        public String event_type {get;set;} 
        public String start_date {get;set;} 
        public String date_utc {get;set;} 
        public String end_date {get;set;} 
        public String end_date_utc {get;set;} 
        public String timezone {get;set;} 
        public String timezone_universal_id {get;set;} 
        public String location {get;set;} 
        public LocationAddress location_address {get;set;} 
        public Addons add_ons {get;set;} 

        public Attributes(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'name') {
                            name = parser.getText();
                        } else if (text == 'event-type') {
                            event_type = parser.getText();
                        } else if (text == 'date') {
                            start_date = parser.getText();
                        } else if (text == 'date-utc') {
                            date_utc = parser.getText();
                        } else if (text == 'end-date') {
                            end_date = parser.getText();
                        } else if (text == 'end-date-utc') {
                            end_date_utc = parser.getText();
                        } else if (text == 'timezone') {
                            timezone = parser.getText();
                        } else if (text == 'timezone-universal-id') {
                            timezone_universal_id = parser.getText();
                        } else if (text == 'location') {
                            location = parser.getText();
                        } else if (text == 'location-address') {
                            location_address = new LocationAddress(parser);
                        } else if (text == 'add-ons') {
                            add_ons = new Addons(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'Attributes consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class LocationAddress {
        public String address_line {get;set;} 
        public String city {get;set;} 
        public String state {get;set;} 
        public String zip {get;set;} 
        public String country {get;set;} 
        public Double latitude {get;set;} 
        public Double longitude {get;set;} 

        public LocationAddress(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'address-line') {
                            address_line = parser.getText();
                        } else if (text == 'city') {
                            city = parser.getText();
                        } else if (text == 'state') {
                            //state = parser.readValueAs(Object.class);
                            state = parser.getText();
                        } else if (text == 'zip') {
                            //zip = parser.readValueAs(Object.class);
                            zip = parser.getText();
                        } else if (text == 'country') {
                            country = parser.getText();
                        } else if (text == 'latitude') {
                            latitude = parser.getDoubleValue();
                        } else if (text == 'longitude') {
                            longitude = parser.getDoubleValue();
                        } else {
                            System.debug(LoggingLevel.WARN, 'LocationAddress consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class Addons {
        public Boolean seating_charts_enabled {get;set;} 
        public Boolean picture_source_enabled {get;set;} 
        public Boolean badge_print_enabled {get;set;} 
        public Boolean rsvp_enabled {get;set;} 

        public Addons(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'seating-charts-enabled') {
                            seating_charts_enabled = parser.getBooleanValue();
                        } else if (text == 'picture-source-enabled') {
                            picture_source_enabled = parser.getBooleanValue();
                        } else if (text == 'badge-print-enabled') {
                            badge_print_enabled = parser.getBooleanValue();
                        } else if (text == 'rsvp-enabled') {
                            rsvp_enabled = parser.getBooleanValue();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Addons consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class Relationships {
        public GuestLists guest_lists {get;set;} 
        public CustomFields custom_fields {get;set;} 

        public Relationships(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'guest-lists') {
                            guest_lists = new GuestLists(parser);
                        } else if (text == 'custom-fields') {
                            custom_fields = new CustomFields(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'Relationships consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class GuestLists {
        public Links links {get;set;} 

        public GuestLists(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'links') {
                            links = new Links(parser);
                        } else if (text == 'data') {
                            //data = arrayOfData(parser);
                            // Do nothing. This is always blank list
                        } else {
                            System.debug(LoggingLevel.WARN, 'GuestLists consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class CustomFields {
        public Links links {get;set;} 
        public List<Data> data {get;set;} 

        public CustomFields(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'links') {
                            links = new Links(parser);
                        } else if (text == 'data') {
                            data = arrayOfData(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'CustomFields consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    private static List<Data> arrayOfData(System.JSONParser p) {
        List<Data> res = new List<Data>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Data(p));
        }
        return res;
    }
    
    public static void consumeObject(System.JSONParser parser) {
        Integer depth = 0;
        do {
            System.JSONToken curr = parser.getCurrentToken();
            if (curr == System.JSONToken.START_OBJECT || 
                curr == System.JSONToken.START_ARRAY) {
                depth++;
            } else if (curr == System.JSONToken.END_OBJECT ||
                curr == System.JSONToken.END_ARRAY) {
                depth--;
            }
        } while (depth > 0 && parser.nextToken() != null);
    }
}

/*
NOTE: This is success (201) json response from creating event from Salesforce to Zkipster
{
  "links": {
    "self": "/v1/events/22942"
  },
  "data": {
    "type": "events",
    "id": "22942",
    "attributes": {
      "name": "ACME Fundraising Event 2018",
      "event-type": "Gala",
      "date": "2018-10-25T20:30:00+01:00",
      "date-utc": "2018-10-25T19:30:00Z",
      "end-date": "2018-10-26T00:30:00+01:00",
      "end-date-utc": "2018-10-25T23:30:00Z",
      "timezone": "(UTC+00:00) Dublin, Edimburgh, Lisbon, London",
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
    },
    "relationships": {
      "guest-lists": {
        "links": {
          "self": "/v1/events/22942/relationships/guest-lists",
          "related": "/v1/events/22942/guest-lists"
        },
        "data": []
      },
      "custom-fields": {
        "links": {
          "self": "/v1/events/22942/relationships/custom-fields",
          "related": "/v1/events/22942/custom-fields"
        },
        "data": [
          {
            "type": "custom-fields",
            "id": "1144"
          },
          {
            "type": "custom-fields",
            "id": "1145"
          },
          {
            "type": "custom-fields",
            "id": "1146"
          },
          {
            "type": "custom-fields",
            "id": "1147"
          },
          {
            "type": "custom-fields",
            "id": "1148"
          }
        ]
      }
    }
  }
}


NOTE: This is success (200) json response from creating event from Salesforce to Zkipster
{
  "links": {
    "self": "/v1/events/22942"
  },
  "data": {
    "type": "events",
    "id": "22942",
    "attributes": {
      "name": "Universal Movies Gala 2018",
      "event-type": "Gala",
      "date": "2018-10-25T20:30:00+01:00",
      "date-utc": "2018-10-25T19:30:00Z",
      "end-date": "2018-10-26T00:30:00+01:00",
      "end-date-utc": "2018-10-25T23:30:00Z",
      "timezone": "(UTC+00:00) Dublin, Edimburgh, Lisbon, London",
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
        "picture-source-enabled": true,
        "badge-print-enabled": true,
        "rsvp-enabled": true
      }
    },
    "relationships": {
      "guest-lists": {
        "links": {
          "self": "/v1/events/22942/relationships/guest-lists",
          "related": "/v1/events/22942/guest-lists"
        },
        "data": []
      },
      "custom-fields": {
        "links": {
          "self": "/v1/events/22942/relationships/custom-fields",
          "related": "/v1/events/22942/custom-fields"
        },
        "data": [
          {
            "type": "custom-fields",
            "id": "1144"
          },
          {
            "type": "custom-fields",
            "id": "1145"
          },
          {
            "type": "custom-fields",
            "id": "1146"
          },
          {
            "type": "custom-fields",
            "id": "1147"
          },
          {
            "type": "custom-fields",
            "id": "1148"
          }
        ]
      }
    }
  }
}
*/