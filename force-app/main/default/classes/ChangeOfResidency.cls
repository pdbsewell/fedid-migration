/**
 * @description       : Class containing the logic for Student Admin Process Automation - Change of Residency
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @last modified on  : 2021-03-10
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-03-10 - Angelo Rivera - Initial Creation
**/

public with sharing class ChangeOfResidency {

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 2021-03-10
    * @description  Retrieves Case details and related Unit Attempts
    * @revision 2021-03-10 - Created
    * @return Case
    *******************************************************************************/
    @AuraEnabled
    public static ThisWrapper doInit(){
        ThisWrapper thisWrapper = new ThisWrapper();
        thisWrapper.mapVisaSubclass = new Map<String, String>();
        thisWrapper.managingFaculty = new List<String>();
        thisWrapper.managingFacultyNames = new Map<String, List<String>>();
        thisWrapper.mapVisaSubclass = retrieveVisaSubclass();
        retrieveFaculty(thisWrapper.managingFaculty, thisWrapper.managingFacultyNames);
        return thisWrapper;
    }

    public static Map<String, String> retrieveVisaSubclass(){
        Map<String, String> mapVisaSubclass = new Map<String, String>();
        for(List_of_Values__c listOfVal :  [SELECT Id, Value__c, Type__c, Description__c FROM List_of_Values__c
                                        WHERE Type__c = 'Change Of Residency Visa Subclass' ORDER BY Value__c ASC ]){
            mapVisaSubclass.put(listOfVal.Value__c + ' - ' + listOfVal.Description__c, 'Subclass ' + listOfVal.Value__c);
        }
        return mapVisaSubclass;
    }

    public static void retrieveFaculty(List<String> listFaculty, Map<String, List<String>> mapFacultyName){
        Set<String> setFaculty = new Set<String>();
        for(List_of_Values__c listOfVal :  [SELECT Id, Value__c, Type__c, Description__c FROM List_of_Values__c
                                        WHERE Type__c = 'Change Of Residency Faculty Name' ORDER BY Description__c, Value__c ASC ]){
            if(!setFaculty.contains(listOfVal.Description__c)){
                setFaculty.add(listOfVal.Description__c);
                listFaculty.add(listOfVal.Description__c);
            }

            if(!mapFacultyName.containsKey(listOfVal.Description__c))
                mapFacultyName.put(listOfVal.Description__c, new List<String>());
            mapFacultyName.get(listOfVal.Description__c).add(listOfVal.Value__c);
        }
    }

    public class ThisWrapper{
        @AuraEnabled public Map<String, String> mapVisaSubclass {get; set;}
        @AuraEnabled public List<String> managingFaculty {get; set;}
        @AuraEnabled public Map<String, List<String>> managingFacultyNames {get; set;}
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date2021-03-10
    * @description  As part of Automation Process - Change of Residency,
                    This will pass the required information to change student residency to Calista via an RPA bot.
    * @revision 2021-03-10 - Created
    * @param caseId - String
    * @param sDate - Start Date
    * @param eDate - End Date
    * @param rDate - Residency Date
    * @param visa - Subclass of the visa
    * @param status - Student Status
    * @param faculty - Faculty Approver
    * @return String - strResp - that will be displayed as a message in lightning component
    *******************************************************************************/
    @AuraEnabled
    public static String changeOfResidency(String caseId, String sDate, String eDate, String rDate, String visa, String status, String faculty){
        String strResp;

        Case c = retrieveCaseDetails(caseId);
        if(c.Contact_Person_ID__c != null && c.Course_Attempt__r.Location__c != null && c.Course_Code__c != null){
            ChangeOfResidencyWrapper itemData = buildCRMData(c, sDate, eDate, rDate, visa, status, faculty);
            //send callouts
            strResp = sendCallout(itemData);

            if(strResp.contains('success')){
                CaseComment caseComment = new CaseComment();
                caseComment.ParentId = c.Id;
                caseComment.CommentBody = Label.ChangeOfResidency_CaseComment+'\n'
                        + 'Application Received Date: ' + sDate + '\n'
                        + 'System End Date: ' + eDate + '\n'
                        + 'Visa Grant Date: ' + rDate + '\n'
                        + 'Subclass Of The Visa: ' + visa + '\n'
                        + 'Student Status: ' + status + '\n'
                        + 'Faculty Manager Name: ' + faculty + '\n'
                        + 'Officer Name: ' + UserInfo.getName();
                Database.insert(caseComment);
            }
        }else{
            String strMissingInfo;
            if(c.Course_Attempt__r.Location__c == null) strMissingInfo = 'Course Attempt';
            if(c.Course_Code__c == null) strMissingInfo = 'Course Attempt';
            if(c.Contact_Person_ID__c == null) strMissingInfo = 'Person Id';
            strResp = Label.ChangeOfResidency_Missing_Info + ' (' + strMissingInfo + ')';
        }

        return strResp;
    }


    /*******************************************************************************
    * @author Angelo Rivera
    * @date 2021-03-10
    * @description  builds the payload
    * @revision 2021-03-10 - Created
    * @param c - Case record
    * @param sDate - Start Date
    * @param eDate - End Date
    * @param rDate - Residency Date
    * @param visa - Subclass of the visa
    * @param status - Student Status
    * @param faculty - Faculty Approver
    * @return changeOfResidencyWrapper
    *******************************************************************************/
    public static ChangeOfResidencyWrapper buildCRMData(Case c, String sDate, String eDate, String rDate, String visa, String status, String faculty){
        ChangeOfResidencyWrapper changeOfResidencyWrapper = new ChangeOfResidencyWrapper();
        ChangeOfResidencyWrapper.SpecificContent contentWrapper = new  ChangeOfResidencyWrapper.SpecificContent(
                c.Contact_Person_ID__c,
                c.Course_Code__c,
                c.Course_Attempt__r.Location__c,
                sDate,
                eDate,
                c.Contact.MailingPostalCode,
                rDate,
                c.Id,
                visa,
                status,
                faculty,
                UserInfo.getName()
        );

        ChangeOfResidencyWrapper.ItemData itemData = new ChangeOfResidencyWrapper.ItemData();
        itemData.Name = Label.ChangeOfResidency_Name;
        itemData.SpecificContent = contentWrapper;
        itemData.Reference = c.Contact_Person_ID__c + '-' + c.Course_Code__c;

        changeOfResidencyWrapper.itemData = itemData;
        return changeOfResidencyWrapper;
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 2021-03-10
    * @description  Retrieves Case details and related Unit Attempts
    * @revision 2021-03-10 - Created
    * @param caseId - String
    * @return Case
    *******************************************************************************/
    public static Case retrieveCaseDetails(String caseId){
        Case c = new Case();
        c = [SELECT Id, Contact_Person_ID__c, Course_Code__c, Course_Attempt__r.Location__c, Contact.MailingPostalCode
                FROM Case WHERE Id =: caseId];
        return c;
    }


    /*******************************************************************************
    * @author Angelo Rivera
    * @date 01/21/21
    * @description  Send the data to MIX-RPA bot via HTTP callout method
    * @revision 01/21/21 - Created
                25/02/25 - Updated Callout Headers (EPCP-4204)
    * @param itemData - ChangeOfResidencyWrapper
    * @return strRet
    *******************************************************************************/
    public static String sendCallout(ChangeOfResidencyWrapper itemData){
        String strRet = '';

        MIX_RPA_Settings__c mixConfig = GetMixConfiguration();
        if (mixConfig != null) {
            //Create Request
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:MIX_RPA_Integration/v1/uipath/queue-items');
            req.setMethod('POST');
            //Set headers
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-UIPATH-OrganizationUnitId', mixConfig.Change_of_Residency_Org_Unit_Id__c);

            // transform json body
            String body = JSON.serialize(itemData);
            req.setBody(body);

            HttpResponse res = null;

            if(!Test.isRunningTest()){
                res = h.send(req);
            }else {
                res = new HttpResponse();
                res.setBody('{\n' +
                        '    "itemData": {\n' +
                        '        "Name" : "ChangeOfResidencyProcessQ",\n' +
                        '        "SpecificContent" : {\n' +
                        '            "Person ID" : "32437110",\n' +
                        '            "Course Code" : "A2000",\n' +
                        '            "Location Code" : "CLAYTON",\n' +
                        '            "Start Date" : "16/12/2020",\n' +
                        '            "End Date" : "15/12/2020"\n' +
                        '            "Postcode" : "2120",\n' +
                        '            "Date of Residency" : "01/12/2020", \n' +
                        '            "UniCRM_CaseID" : "5005O000001Rg9oQAC",\n' +
                        '            "Subclass of the Visa" : "Subclass 189",\n' +
                        '            "Student Status" : "302",\n' +
                        '            "Faculty Manager Name" : "Jane Doe",\n' +
                        '            "Monash Connect Officer Name" : "James Citizen",\n' +
                        '        },\n' +
                        '        "Reference" : "32437100-A2000"\n' +
                        '    }\n' +
                        '}');
            }
            JSONParser parser = JSON.createParser(res.getBody());
            if (res.getBody().contains('errorDetails')) {
                ChangeOfResError err = (ChangeOfResError) parser.readValueAs(ChangeOfResError.class);
                ExLog.add('ChangeOfResidency', 'ChangeOfResidency', 'sendCallout', err.errorDetails.message);
                strRet = err.errorDetails.message;
            }else{
                strRet = Label.ChangeOfResidency_Success_Message;
            }
        }

        return strRet;
    }

    /*******************************************************************************
    * @author       : Angelo Rivera
    * @date         : 01/21/21
    * @description  : Retrieves MIX-RPA credentials needed for integration
    * @revision     : 21/01/21 - Created
    *               : 25/02/25 - Matthew Maramot - Deprecated Tenant Name (EPCP-4204) 
    * @return       : cfgList - List<MIX_RPA_Settings__c>
    *******************************************************************************/
    public static MIX_RPA_Settings__c GetMixConfiguration() {
        MIX_RPA_Settings__c[] settings = [
            SELECT Id, Change_of_Residency_Org_Unit_Id__c FROM MIX_RPA_Settings__c LIMIT 1
        ];
        return settings.size() > 0 ? settings[0] : null;
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 01/21/21
    * @description  Wrapper class for Error message
    * @revision 01/21/21 - Created
    *******************************************************************************/
    public class ChangeOfResError
    {
        public String message{get;set;}
        public ErrorDetails errorDetails{get;set;}
    }
    public class ErrorDetails
    {
        public String message{get;set;}
    }
}