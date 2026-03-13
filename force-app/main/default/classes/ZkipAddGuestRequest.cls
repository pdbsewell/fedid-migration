/**
 * @author J Mapanao
 * @description This method will be used for rest api callout for adding guest record(s) in zkipster
 *              NOTE: Some of the accepted variables from zkipster api have "-" (e.g. first-name, last-name)
 *              Hence, as workaround, "-" has been replaced by "0_0" for salesforce to accmodate it.
 *              Once payload has been deserialized to String (using JSON.deserialized), "0_0" has being replaced to "-"
 *              before sending the request.
 * @revision
 */
public class ZkipAddGuestRequest {

    public Cls_Ddata data;

    public class Cls_Ddata {
        public String id;
        public String type;
        public Cls_Attributes attributes;
        public Cls_Relationships relationships;
    }

    public class Cls_Attributes {
        public String first0_0name;
        public String last0_0name;
        public Cls_Contact_Details contact0_0details;
        public String note;
        public Integer total0_0guests;
        public Cls_Seating_Map_Details seating0_0map0_0details;
        public Cls_Custom_Field_Values[] custom0_0field0_0values;
    }

    public class Cls_Contact_Details {
        public String organization;
        public String country0_0code;
        public String phone0_0number;
        public String email;
    }

    public class Cls_Seating_Map_Details {
        public String seating0_0color;
    }

    public class Cls_Custom_Field_Values {
        public String field0_0name;
        public String value;
        public Cls_Selected_Values[] selected0_0values;
    }

    public class Cls_Relationships {
        public Cls_Guest_List guest0_0list;
    }

    public class Cls_Guest_List {
        public Cls_Ddata data;
    }

    public class Cls_Selected_Values {
        public String value;
    }

    public static ZkipAddGuestRequest parse(String json){
        return (ZkipAddGuestRequest) System.JSON.deserialize(json, ZkipAddGuestRequest.class);
    }

    /**
     * @description  Method for generating payload stub for Add Guest to Zkipster
     * @param CampaignMember campMember
     * @return (String) JSON.serializePretty()
     */
    public static String addGuestPayload(CampaignMember campMember) {
        Cls_Ddata guestListData = new Cls_Ddata(); // data
        guestListData.type = ZkipConstants.GUEST_LIST_TYPE; //'guest-lists'; // Do not change. This is indicator that this guest is related to this guest list
        guestListData.id = campMember.Campaign.Zkipster_Guest_List_Id__c;

        Cls_Guest_List relGuestList = new Cls_Guest_List();
        relGuestList.data = guestListData;

        Cls_Relationships dataRel = new Cls_Relationships(); // relationships
        dataRel.guest0_0list = relGuestList;

        List<Cls_Custom_Field_Values> attCustFieldValues = new List<Cls_Custom_Field_Values>(); // custom-field-values
        Cls_Custom_Field_Values custFieldVal_1 = new Cls_Custom_Field_Values();
        custFieldVal_1.field0_0name = ZkipConstants.CUSTOM_FIELD_VALUES_UNICRM_CAMPMEMBID; // 'UniCRM Campaign Member Id';
        custFieldVal_1.value = campMember.Id;
        attCustFieldValues.add(custFieldVal_1);
        Cls_Custom_Field_Values custFieldVal_2 = new Cls_Custom_Field_Values();
        custFieldVal_2.field0_0name = ZkipConstants.CUSTOM_FIELD_VALUES_TITLE; // 'Title';
        custFieldVal_2.value = (String.isNotBlank(campMember.Invitee_Salutation__c)) ? campMember.Invitee_Salutation__c : '';
        attCustFieldValues.add(custFieldVal_2);
        Cls_Custom_Field_Values custFieldVal_3 = new Cls_Custom_Field_Values();
        custFieldVal_3.field0_0name = ZkipConstants.CUSTOM_FIELD_VALUES_INVITEE; // 'Invitee';
        custFieldVal_3.value = campMember.Invitee_First_Name__c +' '+ campMember.Invitee_Last_Name__c;
        attCustFieldValues.add(custFieldVal_3);
        Cls_Custom_Field_Values custFieldVal_4 = new Cls_Custom_Field_Values();
        custFieldVal_4.field0_0name = ZkipConstants.CUSTOM_FIELD_VALUES_SUFFIX1; //'Suffix 1';
        custFieldVal_4.value = (String.isNotBlank(campMember.Invitee_Suffix__c)) ? campMember.Invitee_Suffix__c : '';
        attCustFieldValues.add(custFieldVal_4);
        Cls_Custom_Field_Values custFieldVal_5 = new Cls_Custom_Field_Values();
        custFieldVal_5.field0_0name = ZkipConstants.CUSTOM_FIELD_VALUES_GUESTPARTNER; // 'Guest';
        custFieldVal_5.value = (String.isNotBlank(campMember.Invitee_Guest__c)) ? campMember.Invitee_Guest__c : '';
        attCustFieldValues.add(custFieldVal_5);
        Cls_Custom_Field_Values custFieldVal_6 = new Cls_Custom_Field_Values();
        custFieldVal_6.field0_0name = ZkipConstants.CUSTOM_FIELD_VALUES_POSITIONS; // 'Position';
        custFieldVal_6.value = (String.isNotBlank(campMember.Invitee_Position__c)) ? campMember.Invitee_Position__c : '';
        attCustFieldValues.add(custFieldVal_6);
        Cls_Custom_Field_Values custFieldVal_7 = new Cls_Custom_Field_Values();
        custFieldVal_7.field0_0name = ZkipConstants.CUSTOM_FIELD_VALUES_DIETREQ; // 'Dietary Requirements';
        custFieldVal_7.value = (String.isNotBlank(campMember.Dietary_Requirements__c)) ? campMember.Dietary_Requirements__c : '';
        attCustFieldValues.add(custFieldVal_7);
        Cls_Custom_Field_Values custFieldVal_8 = new Cls_Custom_Field_Values();
        custFieldVal_8.field0_0name = ZkipConstants.CUSTOM_FIELD_VALUES_ACCESSIBILITYREQ; // 'Accessibility Requirements';
        custFieldVal_8.value = (String.isNotBlank(campMember.Invitee_Accessibility_Requirements__c)) ? campMember.Invitee_Accessibility_Requirements__c : '';
        attCustFieldValues.add(custFieldVal_8);

        Cls_Contact_Details attContDet = new Cls_Contact_Details();
        attContDet.organization = campMember.Invitee_Organization__c;
        attContDet.country0_0code = 'AU'; // Default to AU unless needed to be dynamically
        attContDet.phone0_0number = campMember.Invitee_Phone__c;
        attContDet.email = campMember.Invitee_Email__c;

        Cls_Attributes dataAtt = new Cls_Attributes();
        dataAtt.first0_0name = campMember.Invitee_First_Name__c;
        dataAtt.last0_0name = campMember.Invitee_Last_Name__c;
        dataAtt.contact0_0details = attContDet;
        dataAtt.note = null;
        dataAtt.total0_0guests = 1;
        dataAtt.seating0_0map0_0details = null; //attSeatMapDet;
        dataAtt.custom0_0field0_0values = attCustFieldValues;

        Cls_Ddata mainData = new Cls_Ddata();
        mainData.type = ZkipConstants.GUEST_TYPE; //'guests'; // Do not change. Identifier that this is creating guest record in zkipster
        mainData.attributes = dataAtt;
        mainData.relationships = dataRel;

        ZkipAddGuestRequest payload = new ZkipAddGuestRequest();
        payload.data = mainData;

        System.debug('### ZkipAddGuestRequest.cls - addGuestPayload method ==>' + JSON.serializePretty(payLoad));
        String tokenizedPayload = JSON.serializePretty(payLoad);
        return fixVariables(tokenizedPayload);
    }

    /**
     * @description Method for correcting the variables in json string. Replacing '0_0' to '-'
     * @param String payload
     * @return String
     */
    public static String fixVariables(String payload) {
        String target = '0_0';
        String replacement = '-';
        return payload.replace(target, replacement);
    }

    /*
    static testMethod void testParse() {
        String json=        '{'+
        '  "maindata": {'+
        '    "type": "guests",'+
        '    "attributes": {'+
        '      "first-name": "John",'+
        '      "last-name": "Malkovich",'+
        '      "contact-details": {'+
        '        "organization": "Holywood",'+
        '        "country-code": "US",'+
        '        "phone-number": "458941124",'+
        '        "email": "johh@testers.gh"'+
        '      },'+
        '      "note": "A big movie star!",'+
        '      "total-guests": 1,'+
        '      "seating-map-details": {'+
        '        "seating-color": "BLUE"'+
        '      },'+
        '      "custom-field-values": ['+
        '        {'+
        '          "field-name": "Years in the Company",'+
        '          "value": "23"'+
        '        },'+
        '        {'+
        '          "field-name": "Sex",'+
        '          "selected-values": ['+
        '            {'+
        '              "value": "Male"'+
        '            }'+
        '          ]'+
        '        }'+
        '      ]'+
        '    },'+
        '    "relationships": {'+
        '      "guest-list": {'+
        '        "data": {'+
        '          "type": "guest-lists",'+
        '          "id": "1"'+
        '        }'+
        '      }'+
        '    }'+
        '  }'+
        '}';
        ZkipAddGuestRequest obj = parse(json);
        System.assert(obj != null);
    }
    */

    /*
    {
      "data": {
        "type": "guests",
        "attributes": {
          "first-name": "John",
          "last-name": "Malkovich",
          "contact-details": {
            "organization": "Holywood",
            "country-code": "US",
            "phone-number": "458941124",
            "email": "johh@testers.gh"
          },
          "note": "A big movie star!",
          "total-guests": 1,
          "seating-map-details": {
            "seating-color": "BLUE"
          },
          "custom-field-values": [
            {
              "field-name": "Years in the Company",
              "value": "23"
            },
            {
              "field-name": "Sex",
              "selected-values": [
                {
                  "value": "Male"
                }
              ]
            }
          ]
        },
        "relationships": {
          "guest-list": {
            "data": {
              "type": "guest-lists",
              "id": "1"
            }
          }
        }
      }
    }
    */

}