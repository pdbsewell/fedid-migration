/*
 @Author: Victor Cheng
 @Description: Class to display Offers on Home page
 @revision  Shalini Mendu - Update with class comments
 @revision  Shalini Mendu - Updated for Conditional Offer requirements - 14/02/2019
 @revision  20/01/2020 - Shalini Mendu - SFTN-673 - Do not show VTAC applications / offers on my.app until an offer response is received from the applicant
 @revision  08/07/2020 - Martin Cadman - Removed source system filter from the acp looking up
*/
public with sharing class appHomeOffersCC {

    public static String FIELD_USER = 'user';
    public static String FIELD_ACPS = 'acps';
    public static String FIELD_APPLICATION_ID = 'applicationId';
    public static String FIELD_APPLICATION_NAME = 'applicationName';
    public static String FIELD_APPLICATION_DATE = 'applicationDate';
    public static String FIELD_SUBMITTED_APPLICATIONS = 'submittedApplications';

    public static String TYPE_OFFER_RESPONSE = 'ADM_OFFER_RESP_STATUS';
    public static String VALUE_REJECTED = 'REJECTED';
    public static String VALUE_ACCEPTED = 'ACCEPTED';
    public static String VALUE_ACCEPT_CND = 'ACCEPT-CND';
    public static String VALUE_ACCEPT_PRV = 'ACCEPT-PRV';
    public static String FIELD_LOV_RESPONSE = 'lovResponse';
    public static String STATUS_SUBMITTED = 'Submitted';
    public static String STATUS_SENT_FOR_SUBMITTED = 'Sent for Submission';
    public static String STATUS_REVIEW = 'Review';
    public static String STATUS_MERGE = MyApplicationUtilities.APP_PENDING_MERGE_STATUS;
    public static String DOMESTIC_PG_FEE = 'PG-FEE';

    /**
     * Get the current logged in user
     *
     * @return user record
     */
    private static User getCurrentUser() {
        List<User> listUsers = [
                SELECT
                        ProfileId,
                        ContactId,
                        App_Previously_Studied_at_Monash__c,
                        App_Residency_Status__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ];
        return listUsers[0];
    }
  
    /**
     * get the submitted ACPs for this applicant
     *
     * @param applicantId - Contact Id of the applicant to search with
     *
     * @return a list of submitted ACPs, the filtering will be done at the JS level
     */
    private static List<Application_Course_Preference__c> getACPSForApplicant(Id applicantId)
    {
        List<Application_Course_Preference__c> acps = [SELECT Id
                , Preference_Number__c
                , Application__c
                , Application__r.Name
                , Application__r.Credit_Intention__c
                , Application__r.Submitted_Date__c
                , Unit_Set_Description__c
                , Course_Title__c
                , Course_Code__c
                , Course_Offering__r.Attendance_Mode_Description__c
                , Course_Offering__r.Location_Description__c
                , Course_Offering__r.Admission_Calendar_Description__c
                , Course_Offering__r.Type_of_Place_Description__c
                , Outcome_Status_LOV__r.Applicant_Value__c
                , Outcome_Status_LOV__r.Value__c
                , Offer_Response_Status_LOV__r.Applicant_Value__c
                , Offer_Response_Status_LOV__r.Value__c
                , Offer_Response_Date__c
                , Documentation_Status_LOV__r.Value__c
                , Conditional_Offer_Status_LOV__r.Value__c
                , Conditional_Offer_Status_LOV__r.Applicant_Value__c
                , Offer_Condition__c, Conditional_Offer_Satisfied_Date__c
                , Actual_Offer_Response_Date__c
                , Admission_Category__c
                , Application__r.Source_System__c
                , Application__r.Status__c
        FROM Application_Course_Preference__c
        WHERE Applicant__c =: applicantId
        AND Application__r.Status__c in (:STATUS_SUBMITTED,:STATUS_SENT_FOR_SUBMITTED,:STATUS_REVIEW,:STATUS_MERGE)
        AND (
                (Admission_Category__c LIKE '%VTAC%' AND Offer_Response_Status_LOV__r.Value__c NOT IN (null, 'NOT-APPLIC','PENDING'))
                OR
                (not Admission_Category__c LIKE '%VTAC%')
            )
        ORDER BY Application__r.Submitted_Date__c DESC, //sorted applications by most recent to oldest - SFTD-257
                 Application__r.Name DESC, //sorted applications by most recent to oldest - SFTD-257
                 Preference_Number__c ASC
        ];
        
        return acps;
    }

    /**
     * supporting function to group all ACPS by application, this is so that the JS can display them accordingly
     *
     * @param allACPS
     *
     * @return a list of maps in the following format:
     *
     * {
     * applicationId: id of application
     * applicationName: the user legible Name of the application, eg 'A-123456', used for enquiries, etc
     * applicationDate: the submitted date of the application
     * acps: [acps for this application]
     * }
     */
    private static List<Map<String, Object>> groupACPSByApplicationId(List<Application_Course_Preference__c> allACPS)
    {
        List<Map<String, Object>> groupedAcps = new List<Map<String, Object>>();

        List<Application_Course_Preference__c> listACP;
        Id currAppId;
        for(Application_Course_Preference__c acp:allACPS)
        {
            if(null == currAppId || acp.Application__c != currAppId)
            {
                // new application group
                listACP = new List<Application_Course_Preference__c>();
                currAppId = acp.Application__c;

                Map<String, Object> mapApplication = new Map<String, Object>();
                mapApplication.put(FIELD_APPLICATION_ID, currAppId);
                mapApplication.put(FIELD_APPLICATION_NAME, acp.Application__r.Name);
                mapApplication.put(FIELD_APPLICATION_DATE, acp.Application__r.Submitted_Date__c);
                mapApplication.put(FIELD_ACPS, listACP);

                groupedAcps.add(mapApplication);
            }
            listACP.add(acp);
        }


        return groupedAcps;
    }

    /**
     * supporting function to get a list of maps for all submitted applications for this contact
     *
     * @param applicantId
     *
     * @return a list of maps, see description in groupACPSByApplicationId
     */
    private static List<Map<String, Object>> getGroupedACPsForApplicant(Id applicantId)
    {
        List<Application_Course_Preference__c> allACPS = getACPSForApplicant(applicantId);

        // group by Application Id
        List<Map<String, Object>> groupedByApplication = groupACPSByApplicationId(allACPS);
        return groupedByApplication;
    }


    /**
     * Initial loading function for the LEX component appHomeOffers
     *
     * @return JSON with the following:
     *
     * user: current logged in user
     * submittedApplications: a list of maps, see comments for groupACPSByApplicationId
     */
    @AuraEnabled
    public static Map<String, Object> getInitLoadOffers()
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        // get the user
        User currUser = getCurrentUser();
        mapResults.put(FIELD_USER, currUser);

        // get the acps on offer
        if(currUser != null)
        {
            // group by Application Id
            List<Map<String, Object>> groupedByApplication = getGroupedACPsForApplicant(currUser.ContactId);

            //Retrieve checklist and comments results
            Map<String, Object> checklistAndCommentsMap = retrievePendingChecklistAndUnreadComments(currUser.ContactId);

            //Include checklist and comments results to acp results
            for(Map<String, Object> loopApplicationMap : groupedByApplication){
                Id applicationId = (Id)loopApplicationMap.get(FIELD_APPLICATION_ID);

                //Add outstanding checklist items
                if(((Map<Id, Integer>)checklistAndCommentsMap.get('OUTSTANDING_CHECKLIST')).containsKey(applicationId)){
                    loopApplicationMap.put('OUTSTANDING_CHECKLIST', ((Map<Id, Integer>)checklistAndCommentsMap.get('OUTSTANDING_CHECKLIST')).get(applicationId));
                }
                else { // SFTD-428 DC20191205: set default to 0 when there is no application 
                    loopApplicationMap.put('OUTSTANDING_CHECKLIST', 0);
                }                

                //Add comment count
                if(((Map<Id, Integer>)checklistAndCommentsMap.get('APPLICATION_COMMENT_COUNT')).containsKey(applicationId)){
                    loopApplicationMap.put('APPLICATION_COMMENT_COUNT', ((Map<Id, Integer>)checklistAndCommentsMap.get('APPLICATION_COMMENT_COUNT')).get(applicationId));
                }
                else { // SFTD-428 DC20191205: set default to 0 when there is no application
                    loopApplicationMap.put('APPLICATION_COMMENT_COUNT', 0);
                }  

                //Add unread comment count
                if(((Map<Id, Integer>)checklistAndCommentsMap.get('APPLICATION_UNREAD_COMMENT_COUNT')).containsKey(applicationId)){
                    loopApplicationMap.put('APPLICATION_UNREAD_COMMENT_COUNT', ((Map<Id, Integer>)checklistAndCommentsMap.get('APPLICATION_UNREAD_COMMENT_COUNT')).get(applicationId));
                }
                else { // SFTD-428 DC20191205: set default to 0 when there is no application
                    loopApplicationMap.put('APPLICATION_UNREAD_COMMENT_COUNT', 0);
                }                
            }

            //Prepare result for client to consume
            mapResults.put(FIELD_SUBMITTED_APPLICATIONS, groupedByApplication);
        }

        return mapResults;
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves pending checklist items and unread comments grouped by application
     * @revision    12/08/2019 - Kristian Vegerano - Created
     */
    public static Map<String, Object> retrievePendingChecklistAndUnreadComments(Id applicantId) {
        //Initialize Variables
        Set<String> pendingChecklistStatus = new Set<String> {'Requested', 'Insufficient'};
        Map<String, Object> resultMap = new Map<String, Object>();
        Map<Id, Integer> applicationCommentsMap = new Map<Id, Integer>();
        Map<Id, Integer> applicationUnreadCommentsMap = new Map<Id, Integer>();
        Map<Id, Integer> applicationOutstandingChecklistItems = new Map<Id, Integer>();

        //Query all outstanding checklists related to the applicant
        for(Document_Checklist__c loopChecklist : [SELECT Id, Application__c, Status__c,
                                                             (SELECT Id, NotesSeen__c 
                                                              FROM Document_Checklist_Comments__r)
                                                      FROM Document_Checklist__c
                                                      WHERE Contact__c = :applicantId]){
            //Initialize checklist comment count
            if(!applicationCommentsMap.containsKey(loopChecklist.Application__c)){
                applicationCommentsMap.put(loopChecklist.Application__c, 0);
            }
            //Initialize checklist unread comment count
            if(!applicationUnreadCommentsMap.containsKey(loopChecklist.Application__c)){
                applicationUnreadCommentsMap.put(loopChecklist.Application__c, 0);
            }
            //Initialize outstanding checklist count
            if(!applicationOutstandingChecklistItems.containsKey(loopChecklist.Application__c)){
                applicationOutstandingChecklistItems.put(loopChecklist.Application__c, 0);
            }

            //Increment outstanding checklists
            if(pendingChecklistStatus.contains(loopChecklist.Status__c)){                
                applicationOutstandingChecklistItems.put(loopChecklist.Application__c, applicationOutstandingChecklistItems.get(loopChecklist.Application__c) + 1);
            }

            //Run through each content notes
            if(loopChecklist.Document_Checklist_Comments__r != null){
                for(Document_Checklist_Comment__c loopComment : loopChecklist.Document_Checklist_Comments__r){
                    //Increment comment count
                    applicationCommentsMap.put(loopChecklist.Application__c, applicationCommentsMap.get(loopChecklist.Application__c) + 1);
                    
                    //Increment unread comment count
                    if(loopComment.NotesSeen__c == false){
                        applicationUnreadCommentsMap.put(loopChecklist.Application__c, applicationUnreadCommentsMap.get(loopChecklist.Application__c) + 1);
                    }
                }
            }
        }

        //Store results to map
        resultMap.put('OUTSTANDING_CHECKLIST', applicationOutstandingChecklistItems);
        resultMap.put('APPLICATION_COMMENT_COUNT', applicationCommentsMap);
        resultMap.put('APPLICATION_UNREAD_COMMENT_COUNT', applicationUnreadCommentsMap);

        return resultMap;
    }

    /**
     * Update an ACP to a status and updates the actual offer response date to today.
     * acp.Offer_Response_Status_LOV__c is a lookup field and data dependent.
     *
     * @param acp - the acp record to update
     * @param sValue - the Value__c of the LOV record to search for, assumes that such a record exists
     *
     * @return the LOV record which it was updated to
     */
    private static List_of_Values__c updateACPToValue(Application_Course_Preference__c acp, String sValue)
    {
        // find the LOV
        List<List_of_Values__c> lovs = [SELECT Id
                , Applicant_Value__c
                , Type__c
                , Value__c
        FROM List_of_Values__c
        WHERE Value__c =: sValue
        AND Type__c =: TYPE_OFFER_RESPONSE
        ];

        if(lovs.size() == 1)
        {
            List_of_Values__c lovResponse = lovs[0];
            acp.Offer_Response_Status_LOV__c = lovResponse.Id;
            //Converting to Australia/Sydney as the my.app user is defaulted to 'GMT'
            DateTime currenttime = DateTime.now();
            String strConvertedDate = currenttime.format('dd/MM/yyyy', 'Australia/Sydney');
            List<String> sp = strConvertedDate.split('/');
            Date dt = Date.newInstance(Integer.valueOf(sp[2]), Integer.valueOf(sp[1]), Integer.valueOf(sp[0]));

            // Do not set the Offer response date for 'ACCEPT-CND'
            if(sValue!='ACCEPT-CND')
                acp.Actual_Offer_Response_Date__c = dt;


            update acp;

            return lovResponse;
        }

        return null;
    }


    /**
     * reloads the ACP list for the current user after an update
     *
     * @return a list of maps see comments for getGroupedACPsForApplicant
     */
    private static List<Map<String, Object>> reloadACPList()
    {
        // get the user
        User currUser = getCurrentUser();

        // get the acps on offer
        List<Map<String, Object>> groupedByApplication;
        if(currUser != null)
        {
            // group by Application Id
            groupedByApplication = getGroupedACPsForApplicant(currUser.ContactId);
        }
        return groupedByApplication;
    }


    /**
     * When an applicant accepts an offer in the UI, updates the acp status to the correct LOV
     *
     * @param acp - the acp record to update
     *
     * @return JSON with updated ACP lists (and values)
     */
    @AuraEnabled
    public static Map<String, Object> doAcceptACP(Application_Course_Preference__c acp)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        String acceptType = VALUE_ACCEPTED;
        //Mock Full offer - For Conditional offer matching some criteria. - SMen
        if(acp.Outcome_Status_LOV__r.Value__c == 'OFFER-COND' )
        {
            System.debug('acp.Conditional_Offer_Status_LOV__r=='+acp.Conditional_Offer_Status_LOV__r.Value__c);
            if(acp.Conditional_Offer_Status_LOV__r.Value__c=='WAIVED' &&
                     (acp.Documentation_Status_LOV__r.Value__c =='DOC-UNCERT'|| acp.Documentation_Status_LOV__r.Value__c =='DOC-ENROL') )
                    acceptType = VALUE_ACCEPTED;
                else
                acceptType = VALUE_ACCEPT_CND;
        }else if(acp.Outcome_Status_LOV__r.Value__c == 'OFFER-PROV')
            acceptType = VALUE_ACCEPT_PRV;

        List_of_Values__c lovResponse = updateACPToValue(acp, acceptType);
        mapResults.put(FIELD_LOV_RESPONSE, lovResponse);

        // reload ACP list
        mapResults.put(FIELD_SUBMITTED_APPLICATIONS, reloadACPList());

        return mapResults;
    }


    /**
     * When an applicant rejects an offer in the UI, updates the acp status to the correct LOV
     *
     * @param acp - the acp record to update
     *
     * return JSON with the update ACP lists (and values)
     */
    @AuraEnabled
    public static Map<String, Object> doRejectACP(Application_Course_Preference__c acp)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        List_of_Values__c lovResponse = updateACPToValue(acp, VALUE_REJECTED);
        mapResults.put(FIELD_LOV_RESPONSE, lovResponse);

        // reload ACP list
        mapResults.put(FIELD_SUBMITTED_APPLICATIONS, reloadACPList());

        return mapResults;
    }


}