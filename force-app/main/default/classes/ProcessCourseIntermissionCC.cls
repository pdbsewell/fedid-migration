/**
 * @description       : Class containing the logic for Student Admin Process Automation - Process Course Intermission
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @last modified on  : 2021-05-05
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-05-05 - Angelo Rivera - Initial Creation
 * 1.1   2021-06-24 - Inderpal Dhanoa - Add Risk Category, caseNumber to payload
 * 1.2   2021-06-24 - Inderpal Dhanoa - Add secondaryReasonFreeText to payload MCT-54
 * 1.3   2023-06-14 - Inderpal Dhanoa - Add extra validation and map End date with values MCT-88
 * 1.4   2023-07-19 - Inderpal Dhanoa - Change Date format MCT-154
**/

public with sharing class ProcessCourseIntermissionCC {

    public static String sCaseNumber = '';

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 2021-05-05
    * @description Contains main logic
    * @revision 2021-05-05 - Created
    * @return ThisWrapper
    *******************************************************************************/
    @AuraEnabled 
    public static ThisWrapper doInit(String caseId){
        ThisWrapper thisWrapper = new ThisWrapper();
        thisWrapper.mapCourseCodes = new Map<String, String>();
        thisWrapper.secondaryReason = new List<String>();
        thisWrapper.m_calendarOptions = new Map<String, String>();
        String s_calendarTypes = String.ValueOf(Label.MC_Process_Course_Intermission_Calendar_Type);
        Date d_startDate; 
		String s_formattedDay, s_formattedMonth;
        List<String> l_calTypes = s_calendarTypes.split( ',' ); 
        try{
            // retrieve contact information
            Contact contact = retrieveContactDetails(caseId);
            thisWrapper.bIsESOS = contact.ESOS__c;
            thisWrapper.bValidContactEmail = String.isBlank(contact.Email) ? false : CommonUtilities.validateEmail(contact.Email) ? true: false;
            thisWrapper.personId = contact.Person_ID_unique__c;

            if(!contact.Course_Attempts__r.isEmpty()){ 
                Set<String> setCourseCode = new Set<String>();
                for(Course_Attempt__c ca : contact.Course_Attempts__r){
                    if(!setCourseCode.contains(ca.Course_Code__c)){
                        setCourseCode.add(ca.Course_Code__c);
                        thisWrapper.mapCourseCodes.put(ca.Course_Code__c + ' - ' + ca.Course__r.Course_Description__c,ca.Course_Code__c);
                    }
                }
            }
            Date d_yearAgo = Date.today();
            d_yearAgo = d_yearAgo.addDays(-365);
            for(Calendar__c linkedCalendar : [SELECT Description__c,Start_Date__c 
                                              FROM Calendar__c 
                                              WHERE Type__c IN :l_calTypes 
											  AND Start_Date__c > :d_yearAgo
											  ORDER BY Start_Date__c ASC]){
				d_startDate = linkedCalendar.Start_Date__c;
				s_formattedDay = d_startDate.day() < 10 ? '0' + String.valueOf(d_startDate.day()) : String.valueOf(d_startDate.day());
				s_formattedMonth = d_startDate.month() < 10 ? '0' + String.valueOf(d_startDate.month()) : String.valueOf(d_startDate.month());
                thisWrapper.m_calendarOptions.put(linkedCalendar.Description__c + ' - ' + s_formattedDay + '-' + s_formattedMonth + '-' + d_startDate.year(), String.valueOf(linkedCalendar.Start_Date__c));
            }

            String s_unusedValues = String.ValueOf(Label.UnUsedProcessIntermission);
            List<String> s_unusedVal = s_unusedValues.split(',');
            for(List_of_Values__c secondaryReason : [SELECT Id, Description__c FROM List_of_Values__c WHERE Type__c = 'Intermission Reason' AND Name NOT IN :s_unusedVal ORDER BY Name]){
                thisWrapper.secondaryReason.add(secondaryReason.Description__c);            
            } 
            return thisWrapper;
        }Catch(Exception ex){
            LogUtilityException.logExceptionMSG('Wrapper ', thisWrapper, 'The doInit could not be provided for ProcessCourseIntermissionCC');
            throw(ex);  
        }       
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 2021-05-05
    * @description  retrieves contact information.
    * @revision 2021-05-05 - Created
    * @param caseId - String
    * @return contact - Contact record
    *******************************************************************************/
    public static Contact retrieveContactDetails(String caseId){
        Contact contact = new Contact();
        Case caseRecord = new Case();

        caseRecord = [SELECT Id, Contact_Person_ID__c,Risk_Category_V2__c, CaseNumber FROM Case WHERE Id =: caseId];
        sCaseNumber = caseRecord.CaseNumber;
        if(caseRecord.Contact_Person_ID__c != null){
            contact = [SELECT Id, ESOS__c, Person_ID_unique__c, email,
            (SELECT Id, Course_Code__c, Course__r.Course_Description__c FROM Course_Attempts__r)
            FROM Contact WHERE Person_ID_unique__c =: caseRecord.Contact_Person_ID__c];
        }       
        return contact;     
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date2021-03-10
    * @description  As part of Automation Process - Process Course Intermission,
                    This will pass the required information to process course intermission to Calista via an RPA bot.
    * @revision 2021-05-05 - Created
    * @param caseId - Case Id
    * @param courseCode - Selected course code from the form
    * @param startDate - Start Date
    * @param endDate - End Date
    * @param enrolmentExceptions - enrolment exceptions
    * @return strResp - that will be displayed as a message in lightning component
    *******************************************************************************/
    @AuraEnabled
    public static String processCourseInformation(String  caseId, String courseCode, String startDate, String endDate, String enrolmentExceptions, String secondaryReason, String secondaryReasonFreeText, String courseCodeKey){
        try{
            String strResp;
            UserRecordAccess ura = [SELECT RecordId, HasEditAccess
            FROM UserRecordAccess
            WHERE UserId =: UserInfo.getUserId() AND RecordId =:caseId];

            if(ura.HasEditAccess){
                Contact c = retrieveContactDetails(caseId);
                ProcessCourseIntermissionWrapper itemData = buildCRMData(caseId, c.Person_ID_unique__c, courseCode, startDate, endDate, c.ESOS__c,  enrolmentExceptions, secondaryReason, secondaryReasonFreeText);

                //send callouts
                strResp = sendCallout(itemData);

                if(strResp.contains('processing')){
                    CaseComment caseComment = new CaseComment();
                    caseComment.ParentId = caseId;
                    caseComment.CommentBody = Label.Process_Intermission_Success_Message+'\n' 
                        + 'Person Id: ' + c.Person_ID_unique__c + '\n'
                        + 'Course Code: ' + courseCode + '\n'
                        + 'Start Date: ' + startDate + '\n'
                        + 'End Date: ' + endDate + '\n'
                        + 'Is ESOS Student?: ' + c.ESOS__c + '\n'
                        + 'Enrolment Exceptions: ' + (enrolmentExceptions==''?'n/a':enrolmentExceptions) + '\n'
                        + 'Officer Name: ' + UserInfo.getName() + '\n'
                        + 'Reason: ' + secondaryReason + '\n'
                        + 'SecondaryReasonFreeText: ' + (String.isBlank(secondaryReasonFreeText) ? 'n/a' : secondaryReasonFreeText) + '\n'
                        + 'Case Number: ' + sCaseNumber;
                    Database.insert(caseComment);

                    // Save Start Date & End Date on the Field 

                    List<String> l_splitStartDate = startDate.split('/');
                    List<String> l_splitEndDate = endDate.split('/');
                    Map<Integer,String> m_monthNumberMonthLongName = CommonUtilities.getLongMonthNameWithMonthNumber();
                    String s_endDate = Integer.ValueOf(l_splitEndDate[0]) + ' ' + m_monthNumberMonthLongName.get(Integer.ValueOf(l_splitEndDate[1])) + ' ' + Integer.ValueOf(l_splitEndDate[2]);
                    String s_startDate = Integer.ValueOf(l_splitStartDate[0]) + ' ' + m_monthNumberMonthLongName.get(Integer.ValueOf(l_splitStartDate[1])) + ' ' + Integer.ValueOf(l_splitStartDate[2]);
                    Case updateProcessingDetails = new Case(Id = Id.valueOf(caseId), Faculty_Portfolio__c = s_startDate, Grant_Reason__c = s_endDate, JSON_Payload__c = courseCodeKey);
                    Database.update(updateProcessingDetails);
                }
            } else{
            strResp = 'Error: User has no access.';
            }
            return strResp;
        }Catch(Exception ex){
            LogUtilityException.logException('Case',ex.getMessage(),ex,'The processCourseInformation could not be provided for ProcessCourseIntermissionCC.','Error');
            throw(ex);  
        }
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 2021-05-05
    * @description  builds the payload
    * @revision 2021-05-05 - Created
    * @param personID - Case record
    * @param crsCode - selected course code from the form
    * @param sDate - Start Date
    * @param eDate - End Date
    * @param bEsos - ESOS
    * @param caseId - case Id
    * @param strExceptions - Enrolment exceptions
    * @return changeOfResidencyWrapper
    *******************************************************************************/
    public static ProcessCourseIntermissionWrapper buildCRMData(String caseId, String personID, String crsCode,  String sDate, String eDate, 
            Boolean bEsos,  String strExceptions, String secondaryReason, String secondaryReasonFreeText) {
        ProcessCourseIntermissionWrapper processCourseIntermissionWrapper = new ProcessCourseIntermissionWrapper();
        String s_revisedReason = secondaryReason == 'Other' ? secondaryReasonFreeText : secondaryReason;
        ProcessCourseIntermissionWrapper.SpecificContent contentWrapper = new ProcessCourseIntermissionWrapper.SpecificContent(personID,crsCode,sDate,eDate,bEsos,caseId,strExceptions,UserInfo.getName(),s_revisedReason,sCaseNumber);
    
        ProcessCourseIntermissionWrapper.ItemData itemData = new ProcessCourseIntermissionWrapper.ItemData();
        itemData.Name = Label.Process_Intermission_Name;
        itemData.SpecificContent = contentWrapper;
        itemData.Reference = personID + '-' + crsCode;

        processCourseIntermissionWrapper.itemData = itemData;
        return processCourseIntermissionWrapper;
    }

    /*******************************************************************************
    * @author       : Angelo Rivera
    * @date         : 05/05/21
    * @description  : Send the data to MIX-RPA bot via HTTP callout method
    * @revision     : 05/05/21 - Created
    *               : 25/02/25 - Matthew Maramot - Updated Callout Headers (EPCP-4204) 
    * @param itemData - ProcessCourseIntermissionWrapper
    * @return strRet
    *******************************************************************************/
    public static String sendCallout(ProcessCourseIntermissionWrapper itemData) {
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
            req.setHeader('X-UIPATH-OrganizationUnitId', mixConfig.Course_Intermissions_Org_Unit_Id__c);

            // transform json body
            String body = JSON.serialize(itemData);
            req.setBody(body);

            HttpResponse res = null;
            res = h.send(req);
            String resp = JSON.serializePretty(res.getBody());

            if(resp.contains('error') || resp.contains('fail')){
                strRet = 'Error sending callout: ' + resp;
            }else{
                strRet = Label.Process_Intermission_Success_Message;
            }
        }
        return strRet;
    }

    /*******************************************************************************
    * @author Angelo Rivera
    * @date 2021-05-05
    * @description  Inner Class. Contains data retrieved to for aura
    * @revision 2021-05-05 - Created
    *******************************************************************************/
    public class ThisWrapper{
        @AuraEnabled public Boolean bValidContactEmail {get; set;}
        @AuraEnabled public Boolean bIsESOS {get; set;}
        @AuraEnabled public Map<String, String> mapCourseCodes {get; set;}
        @AuraEnabled public String personId {get; set;}
        @AuraEnabled public List<String> secondaryReason {get; set;}
        @AuraEnabled public Map<String, String> m_calendarOptions {get; set;}
    }

    /*******************************************************************************
    * @author       : Angelo Rivera
    * @date         : 2021-05-05
    * @description  : Retrieves MIX-RPA credentials needed for integration
    * @revision     : 05/05/21 - Created
    *               : 25/02/25 - Matthew Maramot - Deprecated Tenant Name (EPCP-4204) 
    * @return       : cfgList - List<MIX_RPA_Settings__c>
    *******************************************************************************/
    public static MIX_RPA_Settings__c GetMixConfiguration() {
        MIX_RPA_Settings__c[] settings = [
            SELECT Id, Course_Intermissions_Org_Unit_Id__c FROM MIX_RPA_Settings__c LIMIT 1
        ];
        return settings.size() > 0 ? settings[0] : null;
    }
}