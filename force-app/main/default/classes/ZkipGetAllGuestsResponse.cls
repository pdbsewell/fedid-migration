/**
 * @author J Mapanao
 * @description This class is used for HttpResponse for Get Guests from Guest List
 *
 */
public class ZkipGetAllGuestsResponse {
    
    public List<ClsMainData> data {get;set;}
    
    public static ZkipGetAllGuestsResponse parse(String json) {
        System.JSONParser parser = System.JSON.createParser(json);
        return new ZkipGetAllGuestsResponse(parser);
    }
    
    public ZkipGetAllGuestsResponse(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'data') {
                        data = arrayOfClsMainData(parser);
                    } else {
                        System.debug(LoggingLevel.WARN, 'ZkipGetAllGuestsResponse consuming unrecognized property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    
    public class ClsMainData {
        public String typeGuests {get;set;}
        public String id {get;set;} 
        public ClsAttributes attributes {get;set;} 
        public ClsRelationships relationships {get;set;} 
        public ClsMainLinks mainLinks {get;set;} 

        public ClsMainData(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'type') {
                            typeGuests = parser.getText();
                        } else if (text == 'id') {
                            id = parser.getText();
                        } else if (text == 'attributes') {
                            attributes = new ClsAttributes(parser);
                        } else if (text == 'relationships') {
                            relationships = new ClsRelationships(parser);
                        } else if (text == 'links') {
                            mainLinks = new ClsMainLinks(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'ClsMainData consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class ClsAttributes {
        public String firstName {get;set;} 
        public String lastName {get;set;} 
        public ClsContactDetails contactDetails {get;set;} 
        public List<String> notificationEmails {get;set;} 
        public Object notificationPhoneNumbers {get;set;} 
        public String note {get;set;} 
        public Integer totalGuests {get;set;} 
        public Integer plusOnesChecked {get;set;} 
        public Boolean mainGuestChecked {get;set;} 
        public DateTime checkinDate {get;set;} 
        public String status {get;set;} 
        public Object seatingMapDetails {get;set;} 
        public List<ClsCustomFieldValues> customFieldValues {get;set;} 

        public ClsAttributes(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'first-name') {
                            firstName = parser.getText();
                        } else if (text == 'last-name') {
                            lastName = parser.getText();
                        } else if (text == 'contact-details') {
                            contactDetails = new ClsContactDetails(parser);
                        } else if (text == 'notification-emails') {
                            notificationEmails = arrayOfString(parser);
                        } /*else if (text == 'notification-phone-numbers') {
                            notificationPhoneNumbers = parser.readValueAs(Object.class);
                        } */else if (text == 'note') {
                            note = parser.getText();
                        } else if (text == 'total-guests') {
                            totalGuests = parser.getIntegerValue();
                        } else if (text == 'plus-ones-checked') {
                            plusOnesChecked = parser.getIntegerValue();
                        } else if (text == 'main-guest-checked') {
                            mainGuestChecked = parser.getBooleanValue();
                        } else if (text == 'checkin-date') {
                            checkinDate = parser.getDateTimeValue();
                        } else if (text == 'status') {
                            status = parser.getText();
                        } /*else if (text == 'seating-map-details') {
                            seatingMapDetails = parser.readValueAs(Object.class);
                        } */else if (text == 'custom-field-values') {
                            customFieldValues = arrayOfCustomFieldValues(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'Attributes consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class ClsContactDetails {
        public String organization {get;set;} 
        public String countryCode {get;set;} 
        public String phoneNumber {get;set;} 
        public String email {get;set;} 

        public ClsContactDetails(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'organization') {
                            organization = parser.getText();
                        } else if (text == 'country-code') {
                            countryCode = parser.getText();
                        } else if (text == 'phone-number') {
                            phoneNumber = parser.getText();
                        } else if (text == 'email') {
                            email = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'ClsContactDetails consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class ClsCustomFieldValues {
        public Integer customFieldId {get;set;} 
        public String fieldName {get;set;} 
        public String value {get;set;} 
        public Object selectedValues {get;set;} 

        public ClsCustomFieldValues(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'custom-field-id') {
                            customFieldId = parser.getIntegerValue();
                        } else if (text == 'field-name') {
                            fieldName = parser.getText();
                        } else if (text == 'value') {
                            value = parser.getText();
                        } /*else if (text == 'selected-values') {
                            selectedValues = parser.readValueAs(Object.class);
                        } */else {
                            System.debug(LoggingLevel.WARN, 'ClsCustomFieldValues consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }

    public class ClsRelationships {
        public ClsGuestList guestList {get;set;} 
        public ClsCustomFields customFields {get;set;} 

        public ClsRelationships(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'guest-list') {
                            guestList = new ClsGuestList(parser);
                        } else if (text == 'custom-fields') {
                            customFields = new ClsCustomFields(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'ClsRelationships consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class ClsGuestList {
        public Links guestListLinks {get;set;} 
        public Data guestListData {get;set;} 

        public ClsGuestList(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'links') {
                            guestListLinks = new Links(parser);
                        } else if (text == 'data') {
                            guestListData = new Data(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'ClsGuestList consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class ClsCustomFields {
        public Links customFieldslinks {get;set;} 

        public ClsCustomFields(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'links') {
                            customFieldslinks = new Links(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'ClsCustomFields consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
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
        public String typeGuestList {get;set;}
        public String id {get;set;} 

        public Data(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'type') {
                            typeGuestList = parser.getText();
                        } else if (text == 'id') {
                            id = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class ClsMainLinks {
        public String self {get;set;} 

        public ClsMainLinks(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'self') {
                            self = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'ClsMainLinks consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
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
    
    private static List<ClsCustomFieldValues> arrayOfCustomFieldValues(System.JSONParser p) {
        List<ClsCustomFieldValues> res = new List<ClsCustomFieldValues>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new ClsCustomFieldValues(p));
        }
        return res;
    }
    
    private static List<String> arrayOfString(System.JSONParser p) {
        List<String> res = new List<String>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(p.getText());
        }
        return res;
    }

    private static List<ClsMainData> arrayOfClsMainData(System.JSONParser p) {
        List<ClsMainData> res = new List<ClsMainData>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new ClsMainData(p));
        }
        return res;
    }
}