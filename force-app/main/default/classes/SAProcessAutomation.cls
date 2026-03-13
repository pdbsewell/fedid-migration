/**
 * @description       : Class containing the logic for Student Admin Process Automations
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @last modified on  : 2021-01-21
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-01-21 - Angelo Rivera - Initial Creation
 * 1.1   2021-01-28 - Angelo Rivera - Added course code on item data
 * 1.2   2021-02-02 - Angelo Rivera - Updated Payload data type of Teaching Period
**/

public with sharing class SAProcessAutomation {

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 01/21/21
    * @description  As part of Special Circumstances: WI Process,
                    This will pass the required information (Case Unit Attempts) for withdrawal to Calista via an RPA bot.
    * @revision 01/21/21 - Created
    * @param caseId - String
    * @return String - strResp - that will be displayed as a message in lightning component
    *******************************************************************************/
    @AuraEnabled
    public static String wiProcessAutomation(String caseId){
        String strResp;

        //get Case Unit Attempts
        Case c = retrieveCaseDetails(caseId);
        List<CaseComment> lstCaseComments = new List<CaseComment>();
        //iterate over valid CUA for RPA update
        for(Case_Unit_Attempt__c cua : c.Case_Unit_Attempt__r){
            WIProcessWrapper wiItemData = buildCRMData(c, cua);
            //send callouts
            strResp = sendCallout(wiItemData);

            if(strResp.contains('success')){
                CaseComment caseComment = new CaseComment();
                caseComment.ParentId = c.Id;
                CaseComment.CommentBody = Label.WIProcessAutomationCaseComment+'\n'
                        + 'Unit Code: ' + cua.Unit_Attempt__r.Unit_Code__c + '\n'
                        + 'Unit Title: ' + cua.Unit_Attempt__r.Title__c + '\n'
                        + 'Grade: ' + cua.Unit_Attempt__r.Grade__c + '\n'
                        + 'Course Code: ' + cua.Unit_Attempt__r.Course_Code__c + '\n'
                        + 'Academic Period: ' + cua.Unit_Attempt__r.Academic_Year__c + '\n'
                        + 'Teaching Period: ' + cua.Unit_Attempt__r.Teaching_Period__c;
                lstCaseComments.add(caseComment);
            }

        }

        if(!lstCaseComments.isEmpty()){
            Database.insert(lstCaseComments);
        }

        return strResp;
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 01/21/21
    * @description  Retrieves Case details and related Unit Attempts
    * @revision 01/21/21 - Created
    * @param caseId - String
    * @return Case
    *******************************************************************************/
    @AuraEnabled
    public static Case retrieveCaseDetails(String caseId){
        Case c = new Case();
        c = [SELECT Id, Contact_Person_ID__c,
        (SELECT Id, Unit_Attempt__r.Grade__c, Unit_Attempt__r.Title__c, Unit_Attempt__r.Unit_Code__c,
                Unit_Attempt__r.Academic_Year__c, Unit_Attempt__r.Teaching_Period__c, Unit_Attempt__r.Course_Code__c
        FROM Case_Unit_Attempt__r WHERE WI_Status__c = 'Approved' AND Unit_Attempt__r.Grade__c != 'WI' AND Unit_Attempt__c != NULL)
        FROM Case WHERE Id =: caseId];
        return c;
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 01/21/21
    * @description  Retrieves Case details and related Unit Attempts
    * @revision 01/21/21 - Created
    * @param cua - Case_Unit_Attempt__c
    * @param c - Case
    * @return WIProcessWrapper
    *******************************************************************************/
    public static WIProcessWrapper buildCRMData(Case c, Case_Unit_Attempt__c cua){
        WIProcessWrapper wiProcessWrapper = new WIProcessWrapper();
        WIProcessWrapper.SpecificContent contentWrapper = new  WIProcessWrapper.SpecificContent(
                c.Contact_Person_ID__c,
                cua.Unit_Attempt__r.Academic_Year__c,
                cua.Unit_Attempt__r.Teaching_Period__c,
                cua.Unit_Attempt__r.Unit_Code__c,
                cua.Unit_Attempt__r.Course_Code__c,
                c.Id);

        WIProcessWrapper.ItemData itemData = new WIProcessWrapper.ItemData();
        itemData.Name = Label.WIProcessAutomation;
        itemData.SpecificContent = contentWrapper;
        itemData.Reference = c.Contact_Person_ID__c + '-' + cua.Unit_Attempt__r.Unit_Code__c;

        wiProcessWrapper.itemData = itemData;
        return wiProcessWrapper;
    }

    /*******************************************************************************
    * @author       : Angelo Rivera
    * @date         : 21/01/21
    * @description  : Send the data to MIX-RPA bot via HTTP callout method
    * @revision     : 21/01/21 - Created
    *               : 25/02/25 - Matthew Maramot - Updated Callout Headers (EPCP-4204)
    * @param itemData - WIProcessWrapper
    * @return strRet
    *******************************************************************************/
    public static String sendCallout(WIProcessWrapper itemData){
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
            req.setHeader('X-UIPATH-OrganizationUnitId', mixConfig.Grade_to_WI_Org_Unit_Id__c);

            // transform json body
            String body = JSON.serialize(itemData);
            req.setBody(body);

            HttpResponse res = null;

            if(!Test.isRunningTest()){
                res = h.send(req);
            }else {
                res = new HttpResponse();
                res.setBody('{\n' +
                        '    "queueDefinitionId": 586,\n' +
                        '    "referenceKey": "d0b17b8c-1d15-4262-b990-afad34e6c35b",\n' +
                        '    "referenceId": "26262320-MTH1030",\n' +
                        '    "message": "Request submitted."\n' +
                        '}');
            }
            JSONParser parser = JSON.createParser(res.getBody());
            if (res.getBody().contains('errorDetails')) {
                WIProcessError err = (WIProcessError) parser.readValueAs(WIProcessError.class);
                ExLog.add('SAProcessAutomation', 'Case Unit Attempt', 'sendCallout', err.errorDetails.message);
                strRet = err.errorDetails.message;
            }else{
                strRet = Label.WIProcessAutomationSuccess;
            }
        }
        return strRet;
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 01/21/21
    * @description  Wrapper class for Error message
    * @revision 01/21/21 - Created
    *******************************************************************************/
    public class WIProcessError
    {
        public String message{get;set;}
        public ErrorDetails errorDetails{get;set;}
    }
    public class ErrorDetails
    {
        public String message{get;set;}
    }


    /*******************************************************************************
    * @author       : Angelo Rivera
    * @date         : 01/21/21
    * @description  : Retrieves MIX-RPA credentials needed for integration
    * @revision     : 21/01/21 - Created
    *               : 25/02/25 - Matthew Maramot - Deprecated Tenant Name (EPCP-4204) 
    * @return       : cfgList - MIX_RPA_Settings__c
    *******************************************************************************/
    public static MIX_RPA_Settings__c GetMixConfiguration() {
        MIX_RPA_Settings__c[] settings = [
            SELECT Id, Grade_to_WI_Org_Unit_Id__c FROM MIX_RPA_Settings__c LIMIT 1
        ];
        return settings.size() > 0 ? settings[0] : null;
    }

}