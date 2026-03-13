/**
 * Added by UC Innovation to override out of the box Review Transaction logic - 2019-09-19
 * Class ReviewTransactionHandler
 *
 * Trigger Handler for the Review Transaction SObject. This class implements the ITrigger
 * interface to help ensure the trigger code is bulkified and all in one place.
 */
global without sharing class ReviewTransactionHandler extends ucinn_ascendv2.ascend_TDTM_Runnable {

    private ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper dmlWrapper = new ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper();
 
    private Map<String, Id> mapOfDesignations;              //Stores all Designations for the Transactions at hand
    private Map<String, Id> mapOfAppealCodes;               //Stores all Designations for the Transactions at hand
    private Map<String, Id> mapOfRecordTypes;               //Stores all Record Types
    Map<String, Opportunity> mapOfOpps;                     //Map<External System ID, Opportunity> For After insert
    private Map<Id, Map<String, Id>> mapOfActivePledges;    //Stores all transactions associated with Active Pledges
    private ucinn_ascendv2__Session__c defaultSession;                      //The Default Session for Clean Transactions
    private Map<Id, ucinn_ascendv2__Session__c> sessionsToUpdateMap;
    private Set<Id> contactIds;                             //Spouses
    private Boolean isDefaultSessionCreated = false;        //Check if Session has created
    private ReviewTransactionUtils rtool;                   //ReviewTransaction Utils Container
    private List<Attachment> listOfAttachments;             //Attachment Container
    private Set<Id> attachmentRTIDs;
    private Boolean sendToGL = true;                        //Check if session is No to GL
    public Map<String, Opportunity> matchingPledgeMap;     //Map to store matching pledges when evaluating for Manual Review. Map<oneRT.ucinn_ascendv2__External_System_ID__c , Opportunity>
    public Set<Id> postedRTIdSet; //Store currently processing RTs that are about to be posted. Need this to determine whether we approve the session or not during update.
    //Map for Review Transaction Settings
    //public Map<String, Review_Transaction_Setting__mdt> mapOfRTSettings;


    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Executes as entry point into trigger handler.
    *******************************************************************************/
    global override ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList, ucinn_ascendv2.ascend_TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        //Cast SObject lists to be Review Transactions
        List<ucinn_ascendv2__Review_Transaction__c> trigger_new = (List<ucinn_ascendv2__Review_Transaction__c>) newList;
        List<ucinn_ascendv2__Review_Transaction__c> trigger_old = (List<ucinn_ascendv2__Review_Transaction__c>) oldList;

        Map<Id, ucinn_ascendv2__Review_Transaction__c> newMap = createMapOfIdsToReviewTransactions(trigger_new);
        Map<Id, ucinn_ascendv2__Review_Transaction__c> oldMap = createMapOfIdsToReviewTransactions(trigger_old);
        
        matchingPledgeMap = new Map<String, Opportunity>();
        postedRTIdSet = new Set<Id>();

        ////Initialize Custom Metadata Type Review Transaction Settings
        //mapOfRTSettings = new Map<String, Review_Transaction_Setting__mdt>();
        //for(Review_Transaction_Setting__mdt oneMDT : [Select Id, Label, DeveloperName, Text_Value__c, Boolean_Value__c From Review_Transaction_Setting__mdt]){
        //    mapOfRTSettings.put(oneMDT.DeveloperName, oneMDT);
        //}

        // Don't want to run this logic from the TDTM trigger if it is customer community user. Because some TDTM classes enforce with sharing, community users
        // are unable to see campaigns properly if run from TDTM. Created a separate trigger called 'PORTAL_UCIN_ReviewTransactionTrigger' that will only run
        // for community users. 
        if (UserInfo.getUserType() != 'CspLitePortal') {
            if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeInsert) {
                setupReviewTransaction(trigger_new, triggerAction);
                performOperationsBeforeInsert(trigger_new);
                updateSessionBeforeInsert();

            } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterInsert) {
                createMapOfOppsToUpdate(trigger_new);
                performOperationsAfterInsert(trigger_new);
                updateMapOfOpportunitiesAfterInsert();

            } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeUpdate) {
                setupReviewTransaction(trigger_new, triggerAction);
                performOperationsBeforeUpdate(trigger_new, oldMap);
                updateSessionBeforeUpdate();
                updateFromTransactionData(trigger_new);

            } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterUpdate) {

            } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeDelete) {

            } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterDelete) {

            }
        }
        
        return dmlWrapper;
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Generates newmap and oldmap
    *******************************************************************************/
    private Map<Id, ucinn_ascendv2__Review_Transaction__c> createMapOfIdsToReviewTransactions(List<ucinn_ascendv2__Review_Transaction__c> trigger_list) {
        //We try to replicate standard salesforce trigger functionality here. Maps return null, when the context is not right. For example,
        //If we try to access the oldMap for an object that is being inserted, it will be null.
        if (trigger_list != null && trigger_list[0].Id != null) {
            return new Map<Id, ucinn_ascendv2__Review_Transaction__c>(trigger_list);
        } else {
            return null;
        }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Sets up review transaction for processing.
    *******************************************************************************/
    public void setupReviewTransaction(List<ucinn_ascendv2__Review_Transaction__c> trigger_new, ucinn_ascendv2.ascend_TDTM_Runnable.Action triggerAction) {
        // // RYAN ADDED
        List<sObject> otherReviewTransList = new List<sObject>();

        for (ucinn_ascendv2__Review_Transaction__c record : trigger_new) {
            otherReviewTransList.add(record);
        }
        mapOfDesignations = ReviewTransactionUtils.getValidDesignations(otherReviewTransList);
        mapOfAppealCodes = ReviewTransactionUtils.getValidAppealCodes(otherReviewTransList);
        mapOfRecordTypes = ReviewTransactionUtils.getRecordTypes();
        
        rtool = new ReviewTransactionUtils();
        
        //09302016 - Removed Soft credits. In Hard and Soft Credit Trigger now
        rtool.getActivePledges(otherReviewTransList, mapOfDesignations);

        //UPDATE SPECIFIC
        if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeUpdate) {
            sessionsToUpdateMap = new Map<Id, ucinn_ascendv2__Session__c>();

            rtool.initializeTransactionObjects();

            //Check to see if there are any Attachments that need to be deleted
            attachmentRTIDs = new Set<Id>();
            Set<ID> RTsWithGiftReceipts = new Set<Id>();
            for (sObject so: otherReviewTransList) {
                ucinn_ascendv2__Review_Transaction__c oneRT = (ucinn_ascendv2__Review_Transaction__c) so;
                if (oneRT.ucinn_ascendv2__Delete_Attachment__c) {
                    attachmentRTIDs.add(oneRT.Id);
                    oneRT.ucinn_ascendv2__Delete_Attachment__c = false;
                }

                // If not posted, then bring over files to the converted opportunity upon posting. This is specifically for online donations with gift receipts.
                if (oneRT.ucinn_ascendv2__Status__c != 'Posted' && oneRT.ucinn_ascendv2__External_System_ID__c.startsWith('PRAX')) {
                    RTsWithGiftReceipts.add(oneRT.Id);
                }
            }

            //Query for the attachments IDs
            listOfAttachments = [Select Id From Attachment Where ParentId IN :attachmentRTIDs];
        }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Can be leveraged to split various Review transaction types into separate lists.
    *******************************************************************************/
    public void createMapOfOppsToUpdate(List<ucinn_ascendv2__Review_Transaction__c> trigger_new) {
        // // RYAN ADDED
        // RecordType communityRT = reviewTransCommDonorRT;

        // List<sObject> communityReviewTransList = new List<sObject>();
        List<sObject> otherReviewTransList = new List<sObject>();

        for (ucinn_ascendv2__Review_Transaction__c record : (List<ucinn_ascendv2__Review_Transaction__c>) Trigger.new) {
            // if (record.RecordTypeId == communityRT.Id) {
            //     communityReviewTransList.add(record);
            // }
            // else {
                otherReviewTransList.add(record);
            // }
        }


        //Populate Opportunity.Review_Transaction when record is created.
        Set<String> rtIDs = new Set<String>();


        for (sObject reviewTransRec : otherReviewTransList) {
            rtIDs.add(((ucinn_ascendv2__Review_Transaction__c)reviewTransRec).ucinn_ascendv2__External_System_ID__c);
        }



        List<Opportunity> listOfOpportunities = [Select Id, ucinn_ascendv2__Review_Transaction__c, ucinn_ascendv2__External_System_ID__c From Opportunity Where ucinn_ascendv2__External_System_ID__c IN :rtIDs];


        if(!listOfOpportunities.isEmpty()){
            mapOfOpps = new Map<String, Opportunity>();
            //Populate Map
            for(Opportunity oneOpp : listOfOpportunities){
                if(oneOpp.ucinn_ascendv2__External_System_ID__c != null && !mapOfOpps.containsKey(oneOpp.ucinn_ascendv2__External_System_ID__c)){
                    mapOfOpps.put(oneOpp.ucinn_ascendv2__External_System_ID__c, oneOpp);
                }
            }
        }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Operations that are necessary before inserting into database
    *******************************************************************************/
    public void performOperationsBeforeInsert(List<ucinn_ascendv2__Review_Transaction__c> trigger_new) {
        for (ucinn_ascendv2__Review_Transaction__c oneRT : trigger_new) {
            Opportunity matchedPledge;
            
            // if (oneRT.RecordTypeId != reviewTransCommDonorRT.Id) {

            //Assign Record Type - Get the first 4 characters of the External System ID
            oneRT.recordTypeId = mapOfRecordTypes.get(oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4));
            system.debug('designation1=' + oneRT.ucinn_ascendv2__Designation_1_Name__c + '    appeal code=' + oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c);
            system.debug('amounts:' + oneRT.ucinn_ascendv2__Amount_1__c + ' ' + oneRT.ucinn_ascendv2__Amount_2__c + ' '  + oneRT.ucinn_ascendv2__Amount_3__c + ' '  + oneRT.ucinn_ascendv2__Amount_4__c);
            //Check Designation
            if(oneRT.ucinn_ascendv2__Designation_1_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_1_Name__c)){
                oneRT.ucinn_ascendv2__Designation_1__c = mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_1_Name__c);
            }
            //Check Designation
            if(oneRT.ucinn_ascendv2__Designation_2_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_2_Name__c )){
                oneRT.ucinn_ascendv2__Is_Designation_2_Valid__c = true;
                oneRT.ucinn_ascendv2__Designation_2__c = mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_2_Name__c);
            }
            else if(oneRT.ucinn_ascendv2__Designation_2_Name__c == null){
                oneRT.ucinn_ascendv2__Is_Designation_2_Valid__c = true;
            }
            //Check Designation
            if(oneRT.ucinn_ascendv2__Designation_3_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_3_Name__c )){
                oneRT.ucinn_ascendv2__Is_Designation_3_Valid__c = true;
                oneRT.ucinn_ascendv2__Designation_3__c = mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_3_Name__c);
            }
            else if(oneRT.ucinn_ascendv2__Designation_3_Name__c == null){
                oneRT.ucinn_ascendv2__Is_Designation_3_Valid__c = true;
            }
            //Check Designation
            if(oneRT.ucinn_ascendv2__Designation_4_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_4_Name__c )){
                oneRT.ucinn_ascendv2__Is_Designation_4_Valid__c = true;
                oneRT.ucinn_ascendv2__Designation_4__c = mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_4_Name__c);
            }
            else if(oneRT.ucinn_ascendv2__Designation_4_Name__c == null){
                oneRT.ucinn_ascendv2__Is_Designation_4_Valid__c = true;
            }
            //Check Designation
            if(oneRT.ucinn_ascendv2__Designation_5_Name__c != null && mapOfDesignations.containsKey(oneRT.ucinn_ascendv2__Designation_5_Name__c)){
                oneRT.ucinn_ascendv2__Is_Designation_5_Valid__c = true;
                oneRT.ucinn_ascendv2__Designation_5__c = mapOfDesignations.get(oneRT.ucinn_ascendv2__Designation_5_Name__c);
            }
            else if(oneRT.ucinn_ascendv2__Designation_5_Name__c == null){
                oneRT.ucinn_ascendv2__Is_Designation_5_Valid__c = true;
            }
            //Check Appeal Code
            if(oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c != null && mapOfAppealCodes.containsKey(oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c)){
                oneRT.ucinn_ascendv2__Appeal_Code__c= mapOfAppealCodes.get(oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c );
            }
            //Mark Edit --- 10/6/2017 Check Soft Credit, looking for constituents with corresponding Donor_ID__c
            if (oneRT.ucinn_ascendv2__Soft_Credit__c != null) {
                
                List<Contact> softCredit = [select Id from Contact where ucinn_ascendv2__Donor_ID__c =: oneRT.ucinn_ascendv2__Soft_Credit__c];
                if(softCredit.size() < 1) {
                    oneRT.ucinn_ascendv2__Soft_Credit_Contact__c = null;
                } else {
                    oneRT.ucinn_ascendv2__Soft_Credit_Contact__c = softCredit.get(0).Id;
                }
            }
            //Initialize Fields
            oneRT.ucinn_ascendv2__Status__c = 'Unassigned';
            //Evaluate Manual Review         
            addEvaluateManualReview(oneRT);
    
            if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift Payment') {
                matchedPledge = rtool.getPledge(oneRT);
            }
            else if (matchingPledgeMap.containsKey(oneRT.ucinn_ascendv2__External_System_ID__c )) {
                matchedPledge = matchingPledgeMap.get(oneRT.ucinn_ascendv2__External_System_ID__c );
            }
            
            System.debug('#### matchedPledge: '+matchedPledge);

            //Boolean hasManualReviewReason = False;
            if (ReviewTransactionUtils.mapOfManualReviewReasons != null) {
                if (ReviewTransactionUtils.mapOfManualReviewReasons.containsKey(oneRT.ucinn_ascendv2__External_System_ID__c )) {
                    if (!ReviewTransactionUtils.mapOfManualReviewReasons.get(oneRT.ucinn_ascendv2__External_System_ID__c ).isEmpty()) {
                        //hasManualReviewReason = True;
                        oneRT.ucinn_ascendv2__Status__c = 'Manual Review';
                        if (oneRT.ucinn_ascendv2__Manual_Review_Reason__c != null) {
                            oneRT.ucinn_ascendv2__Manual_Review_Reason__c += '; ' + String.join(ReviewTransactionUtils.mapOfManualReviewReasons.get(oneRT.ucinn_ascendv2__External_System_ID__c ), '; ');
                        } else {
                            oneRT.ucinn_ascendv2__Manual_Review_Reason__c = String.join(ReviewTransactionUtils.mapOfManualReviewReasons.get(oneRT.ucinn_ascendv2__External_System_ID__c ), '; ');
                        }
                    }
                }
            }

            //Check to see if Transaction is clean and ready to Post
            if (((oneRT.ucinn_ascendv2__Designation_1__c != null &&
                    oneRT.ucinn_ascendv2__Is_Designation_2_Valid__c &&
                    oneRT.ucinn_ascendv2__Is_Designation_3_Valid__c &&
                    oneRT.ucinn_ascendv2__Is_Designation_4_Valid__c &&
                    oneRT.ucinn_ascendv2__Is_Designation_5_Valid__c) || matchedPledge != null)
                //Mark Edit --- 10/6/2017 ---- As of now, for all transactions, if any soft credit field is populated, the gift processor should process the transaction manually.
                //Otherwise, the transaction will be evaluated further for automatic processing.
                && (oneRT.ucinn_ascendv2__Soft_Credit_First_Name__c == null 
                    && oneRT.ucinn_ascendv2__Soft_Credit_Last_Name__c == null 
                    && oneRT.ucinn_ascendv2__Soft_Credit__c == null)
                //If BOFA transaction has any of the following, then do not post automatically
                //MICR Check Number not populated
                && ((oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4) == 'BOFA' && oneRT.ucinn_ascendv2__MICR_Check_Number__c != null) 
                    || oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4) != 'BOFA'
                )
                //If PRAX transaction has any of the following, then do not post automatically
                //Soft Credit First or Last Name populated
                //In Memory Honor Code populated
                //Notify This Person populated
                && ((oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4) == 'PRAX' 
                    && (oneRT.ucinn_ascendv2__Soft_Credit_First_Name__c == null 
                         && oneRT.ucinn_ascendv2__Soft_Credit_Last_Name__c == null 
                         && oneRT.ucinn_ascendv2__In_Memory_Honor_Code__c == null 
                         && oneRT.ucinn_ascendv2__Notify_Person__c == null)
                    ) 
                    || oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4) != 'PRAX') 
                && oneRT.ucinn_ascendv2__Transaction_Date__c != null 
                && (oneRT.ucinn_ascendv2__Appeal_Code__c != null || matchedPledge != null)
                && (oneRT.ucinn_ascendv2__Contact__c != null || oneRT.ucinn_ascendv2__Account__c != null)
                && !oneRT.ucinn_ascendv2__Is_Correspondence__c 
                && !oneRT.ucinn_ascendv2__Is_Handwriting_Present__c 
                && !oneRT.ucinn_ascendv2__Is_Payment_Match__c
                && oneRT.ucinn_ascendv2__Manual_Review_Reason__c == null
            ) {
                
                //Ephraim  --- 10/05/2019 --- Skip this transaction if Pledge Number is provided but did not find a Pledge and If RT Settings : Pledge Payment Review No Match is true
                if(oneRT.Pledge_No__c != null && matchedPledge == null 
                        && (ReviewTransactionUtils.mapOfRTSettings.containsKey('Pledge_Payment_Review_No_Match') 
                            && ReviewTransactionUtils.mapOfRTSettings.get('Pledge_Payment_Review_No_Match').Boolean_Value__c)){
                    oneRT.ucinn_ascendv2__Status__c = 'Manual Review';
                    oneRT.ucinn_ascendv2__Manual_Review_Reason__c = 'No Pledge match found.';
                }
                else{
                    //Check to see if Session needs to be initialized. Session ID is created here so we know there's at least one Transaction ready to be processed automatically.
                    if(!isDefaultSessionCreated){
                        if(oneRT.ucinn_ascendv2__External_System_ID__c!= null){
                            defaultSession = createSession(oneRT);                        
                            insert defaultSession;
                                                                                    
                            //Retrieve Name
                            defaultSession = [SELECT Id, Name, ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c, ucinn_ascendv2__Pledge_Amount__c, ucinn_ascendv2__Recurring_Gift_Pledge_Amount__c, ucinn_ascendv2__Recurring_Gift_Pledge_Amount_Posted__c,
                                              ucinn_ascendv2__Gift_Pledge_Payment_Amount__c, ucinn_ascendv2__Pledge_Amount_Posted__c, ucinn_ascendv2__Is_Ready_for_G_L__c, ucinn_ascendv2__Session_Totals_Approved__c
                                              ,ucinn_ascendv2__Session_Started__c, ucinn_ascendv2__Session_Completed__c, ucinn_ascendv2__Session_Completed_By__c, ucinn_ascendv2__Is_Completed_by_Gift_Specialist__c, ucinn_ascendv2__No_of_Transactions_Posted__c
                                              From ucinn_ascendv2__Session__c WHERE Id = :defaultSession.Id].get(0);
                            
                            //Only executes once if needed
                            isDefaultSessionCreated = true;
                            rtool.initializeSession(defaultSession);
                        }
                        else{
                            oneRT.addError('No External ID Provided.');
                        }                        
                    }
                    
                    //Assign Session to Transaction
                    oneRT.ucinn_ascendv2__Session__c = defaultSession.Id;
                    oneRT.ucinn_ascendv2__Status__c = 'Posted';
                    oneRT.OwnerId = UserInfo.getUserId();
                    
                    rtool.addTransaction(oneRT);
                    
                    if(oneRT.ucinn_ascendv2__Transaction_Type__c == 'Pledge'){
                        
                        defaultSession.ucinn_ascendv2__Pledge_Amount__c += oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
                        defaultSession.ucinn_ascendv2__Pledge_Amount_Posted__c += oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
                    } else if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift') {
                        defaultSession.ucinn_ascendv2__Recurring_Gift_Pledge_Amount_Posted__c += oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
                        defaultSession.ucinn_ascendv2__Recurring_Gift_Pledge_Amount__c += oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
                    } else{
                        defaultSession.ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c += oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
                        defaultSession.ucinn_ascendv2__Gift_Pledge_Payment_Amount__c += oneRT.ucinn_ascendv2__Total_Amount_Formula__c;
                    }
                    
                    if(defaultSession.ucinn_ascendv2__No_of_Transactions_Posted__c != null){
                        defaultSession.ucinn_ascendv2__No_of_Transactions_Posted__c ++;
                    }
                    else{
                        defaultSession.ucinn_ascendv2__No_of_Transactions_Posted__c = 1;
                    }
                }
            }
            // }
        }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Operations that are necessary before updating database
    *******************************************************************************/
    public void performOperationsBeforeUpdate(List<ucinn_ascendv2__Review_Transaction__c> trigger_new, Map<Id, ucinn_ascendv2__Review_Transaction__c> oldMap) {
        // Query all sessions related to these RT's
        Set<Id> assignedSessionIdSet = new Set<Id>();

        for (ucinn_ascendv2__Review_Transaction__c eachRT: trigger_new) {
            assignedSessionIdSet.add(eachRT.ucinn_ascendv2__Session__c);
        }

        Map<Id, ucinn_ascendv2__Session__c> assignedSessionsMap = new Map<Id, ucinn_ascendv2__Session__c>([SELECT ID, ucinn_ascendv2__No_of_Transactions_Posted__c, ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c,
                                                                    ucinn_ascendv2__Pledge_Amount_Posted__c, ucinn_ascendv2__Recurring_Gift_Pledge_Amount_Posted__c
                                                                    FROM ucinn_ascendv2__Session__c WHERE ID IN: assignedSessionIdSet]);

        List<ContentDocumentLink> giftReceiptsToInsert = new List<ContentDocumentLink>();
        
        for (ucinn_ascendv2__Review_Transaction__c oneRT_new : trigger_new) {
            if (oneRT_new.ucinn_ascendv2__Status__c == 'Posted' ||  oneRT_new.ucinn_ascendv2__Status__c == 'Completed') {
                continue;
            }

            Opportunity matchedPledge;

            ucinn_ascendv2__Review_Transaction__c oneRT_old = oldMap.get(oneRT_new.id);

            // if (oneRT_old.RecordTypeId != reviewTransCommDonorRT.Id && oneRT_new.RecordTypeId != reviewTransCommDonorRT.Id) {

            //Check to see if there is a change on the Designation or Appeal Code
            if(oneRT_old.ucinn_ascendv2__Designation_1_Name__c != oneRT_new.ucinn_ascendv2__Designation_1_Name__c){
                if(oneRT_new.ucinn_ascendv2__Designation_1_Name__c != null && mapOfDesignations.containsKey(oneRT_new.ucinn_ascendv2__Designation_1_Name__c)){
                    oneRT_new.ucinn_ascendv2__Designation_1__c = mapOfDesignations.get(oneRT_new.ucinn_ascendv2__Designation_1_Name__c);
                }
                else{
                    oneRT_new.ucinn_ascendv2__Designation_1__c = null;
                }
            }
            //Check Designation
            if(oneRT_new.ucinn_ascendv2__Designation_2_Name__c != null && mapOfDesignations.containsKey(oneRT_new.ucinn_ascendv2__Designation_2_Name__c )){
                oneRT_new.ucinn_ascendv2__Is_Designation_2_Valid__c = true;
                oneRT_new.ucinn_ascendv2__Designation_2__c = mapOfDesignations.get(oneRT_new.ucinn_ascendv2__Designation_2_Name__c);
            }
            else{
                oneRT_new.ucinn_ascendv2__Is_Designation_2_Valid__c = false;
                oneRT_new.ucinn_ascendv2__Designation_2__c = null;
            }
            if(oneRT_new.ucinn_ascendv2__Designation_2_Name__c == null){
                oneRT_new.ucinn_ascendv2__Is_Designation_2_Valid__c = true;
            }
            //Check Designation
            if(oneRT_new.ucinn_ascendv2__Designation_3_Name__c != null && mapOfDesignations.containsKey(oneRT_new.ucinn_ascendv2__Designation_3_Name__c )){
                oneRT_new.ucinn_ascendv2__Is_Designation_3_Valid__c = true;
                oneRT_new.ucinn_ascendv2__Designation_3__c = mapOfDesignations.get(oneRT_new.ucinn_ascendv2__Designation_3_Name__c);
            }
            else{
                oneRT_new.ucinn_ascendv2__Is_Designation_3_Valid__c = false;
                oneRT_new.ucinn_ascendv2__Designation_3__c = null;
            }
            if(oneRT_new.ucinn_ascendv2__Designation_3_Name__c == null){
                oneRT_new.ucinn_ascendv2__Is_Designation_3_Valid__c = true;
            }
            //Check Designation
            if(oneRT_new.ucinn_ascendv2__Designation_4_Name__c != null && mapOfDesignations.containsKey(oneRT_new.ucinn_ascendv2__Designation_4_Name__c )){
                oneRT_new.ucinn_ascendv2__Is_Designation_4_Valid__c = true;
                oneRT_new.ucinn_ascendv2__Designation_4__c = mapOfDesignations.get(oneRT_new.ucinn_ascendv2__Designation_4_Name__c);
            }
            else{
                oneRT_new.ucinn_ascendv2__Is_Designation_4_Valid__c = false;
                oneRT_new.ucinn_ascendv2__Designation_4__c = null;
            }
            if(oneRT_new.ucinn_ascendv2__Designation_4_Name__c == null){
                oneRT_new.ucinn_ascendv2__Is_Designation_4_Valid__c = true;
            }
            //Check Designation
            if(oneRT_new.ucinn_ascendv2__Designation_5_Name__c != null && mapOfDesignations.containsKey(oneRT_new.ucinn_ascendv2__Designation_5_Name__c)){
                oneRT_new.ucinn_ascendv2__Is_Designation_5_Valid__c = true;
                oneRT_new.ucinn_ascendv2__Designation_5__c = mapOfDesignations.get(oneRT_new.ucinn_ascendv2__Designation_5_Name__c);
            }
            else{
                oneRT_new.ucinn_ascendv2__Is_Designation_5_Valid__c = false;
                oneRT_new.ucinn_ascendv2__Designation_5__c = null;
            }
            if(oneRT_new.ucinn_ascendv2__Designation_5_Name__c == null){
                oneRT_new.ucinn_ascendv2__Is_Designation_5_Valid__c = true;
            }
            
            
            //Check to see if there is a change on the Designation or Appeal Code
            if(oneRT_old.ucinn_ascendv2__Appeal_No_Source_Code__c  != oneRT_new.ucinn_ascendv2__Appeal_No_Source_Code__c ){
                if(oneRT_new.ucinn_ascendv2__Appeal_No_Source_Code__c != null && mapOfAppealCodes.containsKey(oneRT_new.ucinn_ascendv2__Appeal_No_Source_Code__c)){
                    oneRT_new.ucinn_ascendv2__Appeal_Code__c= mapOfAppealCodes.get(oneRT_new.ucinn_ascendv2__Appeal_No_Source_Code__c );
                }
                else{
                    oneRT_new.ucinn_ascendv2__Appeal_Code__c = null;
                }
            }
            
            //Mark Edit --- 10/6/2017 Check Soft Credit, looking for constituents with corresponding Donor_ID__c
            if (oneRT_new.ucinn_ascendv2__Soft_Credit__c != null) {
                
                List<Contact> softCredit = [select Id from Contact where ucinn_ascendv2__Donor_ID__c =: oneRT_new.ucinn_ascendv2__Soft_Credit__c];
                if(softCredit.size() < 1) {
                    oneRT_new.ucinn_ascendv2__Soft_Credit_Contact__c = null;
                } else {
                    oneRT_new.ucinn_ascendv2__Soft_Credit_Contact__c = softCredit.get(0).Id;
                }
            }
                
            //Evaluate Manual Review
            //Reset manual review reason before looking for new reasons
            oneRT_new.ucinn_ascendv2__Manual_Review_Reason__c = null;
			ReviewTransactionUtils.mapOfManualReviewReasons.clear();
            if (oneRT_old.ucinn_ascendv2__Status__c != 'Posted') {
                addEvaluateManualReview(oneRT_new);
                
                if (oneRT_new.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift Payment') {
                    matchedPledge = rtool.getPledge(oneRT_new);
                }
                else if (matchingPledgeMap.containsKey(oneRT_new.ucinn_ascendv2__External_System_ID__c)) {
                    matchedPledge = matchingPledgeMap.get(oneRT_new.ucinn_ascendv2__External_System_ID__c);
                }
                
                if (ReviewTransactionUtils.mapOfManualReviewReasons != null) {
                    if (ReviewTransactionUtils.mapOfManualReviewReasons.containsKey(oneRT_new.ucinn_ascendv2__External_System_ID__c)) {
                        if (!ReviewTransactionUtils.mapOfManualReviewReasons.get(oneRT_new.ucinn_ascendv2__External_System_ID__c).isEmpty()) {
                            //hasManualReviewReason = True;
                            oneRT_new.ucinn_ascendv2__Status__c = 'Manual Review';
                            oneRT_new.ucinn_ascendv2__Manual_Review_Reason__c = String.join(ReviewTransactionUtils.mapOfManualReviewReasons.get(oneRT_new.ucinn_ascendv2__External_System_ID__c), '; ');
                        }
                    }
                }
            }
            
            system.debug('matchedPledge: ' + matchedPledge);

            System.debug('#### oneRT_old.ucinn_ascendv2__Status__c: '+oneRT_old.ucinn_ascendv2__Status__c);
            System.debug('#### oneRT_new.ucinn_ascendv2__Transaction_Date__c: '+oneRT_new.ucinn_ascendv2__Transaction_Date__c);
            System.debug('#### oneRT_new.ucinn_ascendv2__Appeal_Code__c: '+oneRT_new.ucinn_ascendv2__Appeal_Code__c);
            System.debug('#### oneRT_new.ucinn_ascendv2__Contact__c: '+oneRT_new.ucinn_ascendv2__Contact__c);
            System.debug('#### oneRT_new.ucinn_ascendv2__Session__c: '+oneRT_new.ucinn_ascendv2__Session__c);
            
            //Check to see if Transaction is clean and ready to Post
            if(((oneRT_new.ucinn_ascendv2__Designation_1__c != null &&
                    oneRT_new.ucinn_ascendv2__Is_Designation_2_Valid__c &&
                    oneRT_new.ucinn_ascendv2__Is_Designation_3_Valid__c &&
                    oneRT_new.ucinn_ascendv2__Is_Designation_4_Valid__c &&
                    oneRT_new.ucinn_ascendv2__Is_Designation_5_Valid__c) || matchedPledge != null)
                //Mark Edit --- 10/6/2017 ---- As of now, for all transactions, if any soft credit field is populated, the gift processor should process the transaction manually.
                //Otherwise, the transaction will be evaluated further for automatic processing.
                && ((oneRT_new.ucinn_ascendv2__Soft_Credit_First_Name__c == null 
                    && oneRT_new.ucinn_ascendv2__Soft_Credit_Last_Name__c == null 
                    && oneRT_new.ucinn_ascendv2__Soft_Credit__c == null) 
                    || oneRT_new.ucinn_ascendv2__Soft_Credit_Contact__c != null)
                //If BOFA transaction has any of the following, then do not post automatically
                //MICR Check Number not populated
                && ((oneRT_new.ucinn_ascendv2__External_System_ID__c.substring(0,4) == 'BOFA' && oneRT_new.ucinn_ascendv2__MICR_Check_Number__c != null) 
                    || oneRT_new.ucinn_ascendv2__External_System_ID__c.substring(0,4) != 'BOFA')
                && oneRT_new.ucinn_ascendv2__Transaction_Date__c != null
                && (oneRT_new.ucinn_ascendv2__Appeal_Code__c != null || matchedPledge != null)
                && (oneRT_new.ucinn_ascendv2__Contact__c != null || oneRT_new.ucinn_ascendv2__Account__c != null)
                && oneRT_old.ucinn_ascendv2__Status__c != 'Posted'
                && oneRT_new.ucinn_ascendv2__Manual_Review_Reason__c == null
            ) {
                  //Ephraim  --- 10/05/2019 --- Skip this transaction if Pledge Number is provided but did not find a Pledge and If RT Settings : Pledge Payment Review No Match is true
                if(oneRT_new.Pledge_No__c != null && matchedPledge == null 
                          && (ReviewTransactionUtils.mapOfRTSettings.containsKey('Pledge_Payment_Review_No_Match') 
                              && ReviewTransactionUtils.mapOfRTSettings.get('Pledge_Payment_Review_No_Match').Boolean_Value__c)){
                    //oneRT_new.addError('No Pledge match found.');
                    oneRT_new.ucinn_ascendv2__Status__c = 'Manual Review';
                    oneRT_new.ucinn_ascendv2__Manual_Review_Reason__c = 'No Pledge match found.';
                }
                else{                    
                    // If oneRT_new does not have a session, create it.
                    if (oneRT_new.ucinn_ascendv2__Session__c == null) {
                        ucinn_ascendv2__Session__c newSession = createSession(oneRT_new);    

                        if(oneRT_new.ucinn_ascendv2__Transaction_Type__c == 'Pledge'){                        
                            newSession.ucinn_ascendv2__Pledge_Amount__c += oneRT_new.ucinn_ascendv2__Total_Amount_Formula__c;
                        } else if (oneRT_new.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift') {
                            newSession.ucinn_ascendv2__Recurring_Gift_Pledge_Amount__c += oneRT_new.ucinn_ascendv2__Total_Amount_Formula__c;
                        } else{
                            newSession.ucinn_ascendv2__Gift_Pledge_Payment_Amount__c += oneRT_new.ucinn_ascendv2__Total_Amount_Formula__c;
                        }   

                        insert newSession;
                        // Need this to set paymentgroup id correctly
                        newSession = [SELECT ID,Name,ucinn_ascendv2__Pledge_Amount_Posted__c,ucinn_ascendv2__Recurring_Gift_Pledge_Amount_Posted__c,ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c,
                                        ucinn_ascendv2__No_of_Transactions_Posted__c
                                         FROM ucinn_ascendv2__session__c WHERE ID =: newSession.Id];

                        rtool.initializeSession(newSession);
                        
                        oneRT_new.ucinn_ascendv2__Session__c = newSession.Id;        
                        sessionsToUpdateMap.put(oneRT_new.ucinn_ascendv2__Session__c, newSession);                                                
                    }

                    // If sessions to U
                    if (!sessionsToUpdateMap.containsKey(oneRT_new.ucinn_ascendv2__Session__c) && assignedSessionsMap.containsKey(oneRT_new.ucinn_ascendv2__Session__c)) {                    
                        sessionsToUpdateMap.put(oneRT_new.ucinn_ascendv2__Session__c, assignedSessionsMap.get(oneRT_new.ucinn_ascendv2__Session__c));
                    }

                    ucinn_ascendv2__session__c sessiontoUpdate = sessionsToUpdateMap.get(oneRT_new.ucinn_ascendv2__Session__c);
                    
                    system.debug('charlie sessiontoUpdate' + sessiontoUpdate);

                    if(oneRT_new.ucinn_ascendv2__Transaction_Type__c == 'Pledge') {
                        if (sessiontoUpdate.ucinn_ascendv2__Pledge_Amount_Posted__c == null) {
                            sessiontoUpdate.ucinn_ascendv2__Pledge_Amount_Posted__c = 0;
                        }                        
                        sessiontoUpdate.ucinn_ascendv2__Pledge_Amount_Posted__c += oneRT_new.ucinn_ascendv2__Total_Amount_Formula__c;
                    } else if (oneRT_new.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift') {
                        if (sessiontoUpdate.ucinn_ascendv2__Recurring_Gift_Pledge_Amount_Posted__c == null) {
                            sessiontoUpdate.ucinn_ascendv2__Recurring_Gift_Pledge_Amount_Posted__c = 0;
                        }   
                        sessiontoUpdate.ucinn_ascendv2__Recurring_Gift_Pledge_Amount_Posted__c += oneRT_new.ucinn_ascendv2__Total_Amount_Formula__c;
                    } else{
                        if (sessiontoUpdate.ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c == null) {
                            sessiontoUpdate.ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c = 0;
                        }  
                        sessiontoUpdate.ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c += oneRT_new.ucinn_ascendv2__Total_Amount_Formula__c;
                    }

                    if (sessiontoUpdate.ucinn_ascendv2__No_of_Transactions_Posted__c == null) {
                        sessiontoUpdate.ucinn_ascendv2__No_of_Transactions_Posted__c = 0;
                    }
                    sessiontoUpdate.ucinn_ascendv2__No_of_Transactions_Posted__c ++;  

                    oneRT_new.ucinn_ascendv2__Status__c = 'Posted';   
                    postedRTIdSet.add(oneRT_new.Id);

                    // Setup the opp + related records for insertion
                    rtool.addTransaction(oneRT_new);                                    
                }
                  
            }
            else if(oneRT_old.ucinn_ascendv2__Status__c != oneRT_new.ucinn_ascendv2__Status__c 
                        && oneRT_new.ucinn_ascendv2__Status__c == 'Posted' 
                        && oneRT_new.ucinn_ascendv2__Exception_Reasons_Formula__c != 'No Exceptions'
                        && oneRT_new.ucinn_ascendv2__Manual_Review_Reason__c != null) {
                oneRT_new.addError('There are still exceptions for this transaction. Please view Exception Reasons');
            }
            // }
        }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Look up to review transaction from created opportunity.
    *******************************************************************************/
    public void performOperationsAfterInsert(List<ucinn_ascendv2__Review_Transaction__c> trigger_new) {

         for (ucinn_ascendv2__Review_Transaction__c oneRT : trigger_new) {

             

            if(mapOfOpps != null && mapOfOpps.containsKey(oneRT.ucinn_ascendv2__External_System_ID__c)){

                Opportunity oneOpp = mapOfOpps.get(oneRT.ucinn_ascendv2__External_System_ID__c);

                ucinn_ascendv2__Review_Transaction__c tempRT = (ucinn_ascendv2__Review_Transaction__c) Trigger.newMap.get(oneRT.Id);
                oneOpp.ucinn_ascendv2__Review_Transaction__c = tempRT.Id;

                mapOfOpps.put(oneRT.ucinn_ascendv2__External_System_ID__c, oneOpp);
            }
             
         }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Update session values.
    *******************************************************************************/
    public void updateSessionBeforeInsert() {
        Savepoint sp = Database.setSavepoint();

       // try{
            if(defaultSession != null){
                //Creates the Opportunity, Designation Details, etc.
                if(rtool != null){
                    rtool.createTransactionRecords();
                }

                //Approve the Process
                DateTime completedDate = DateTime.Now();
                defaultSession.ucinn_ascendv2__Is_Ready_for_G_L__c = true;
                defaultSession.ucinn_ascendv2__Session_Totals_Approved__c = completedDate;
                defaultSession.ucinn_ascendv2__Session_Started__c = completedDate;
                defaultSession.ucinn_ascendv2__Session_Completed__c = completedDate;
                defaultSession.ucinn_ascendv2__Session_Completed_By__c = UserInfo.getUserId();
                defaultSession.ucinn_ascendv2__Is_Completed_by_Gift_Specialist__c = true;
                defaultSession.ucinn_ascendv2__Is_Sent_to_Laserfiche__c = true;

                
                //If coming from batch, do not run the session trigger. Be responsible for calling update giving summary batch from initial batch finish.
                if (System.isBatch() == true) {
                    ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Session__c', false);
                }
                
                update defaultSession;
            

                //Update the Session again for Ruffalo Cody. The first update is in charge of generating the giving detail records.
                if(!sendToGL){
                    defaultSession.ucinn_ascendv2__Is_Sent_to_G_L__c = !sendToGL;
                    update defaultSession;
                }
                
                if (System.isBatch() == true) {
                    ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Session__c', true);
                }

                //asc_OTHER_LaserficheUtils lf = new asc_OTHER_LaserficheUtils(defaultSession,true, Trigger.new);
            }
        //}
        /*catch(Exception e)
        {
            System.Debug(e.getMessage());
            Database.rollback(sp);
            throw new applicationException(e.getMessage());
        }*/
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Update session values before update.
    *******************************************************************************/
    public void updateSessionBeforeUpdate() {
        if(asc_TriggerController.ReviewTransactionHandlerIsRunning){
            Savepoint sp = Database.setSavepoint();
            try {
                if(rtool != null){
                    rtool.createTransactionRecords();
                }

                if (!sessionsToUpdateMap.isEmpty()) {
                    update sessionsToUpdateMap.values();
                }

                if(!sessionsToUpdateMap.isEmpty()){
                    List<ucinn_ascendv2__Session__c> sessionsToUpdate = new List<ucinn_ascendv2__Session__c>();
                    List<ucinn_ascendv2__Session__c> queriedSessions = [SELECT ID,
                                                                        ucinn_ascendv2__Pledge_Amount__c,
                                                                        ucinn_ascendv2__Pledge_Amount_Posted__c,
                                                                        ucinn_ascendv2__Recurring_Gift_Pledge_Amount_Posted__c,
                                                                        ucinn_ascendv2__Recurring_Gift_Pledge_Amount__c,
                                                                        ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c,
                                                                        ucinn_ascendv2__Gift_Pledge_Payment_Amount__c,
                                                                        ucinn_ascendv2__No_of_Transactions_Posted__c,
                                                                        (SELECT ID,ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Review_Transactions_Session__r)
                                                                        FROM ucinn_ascendv2__Session__c WHERE ID IN: sessionsToUpdateMap.keySet()];
                    
                    system.debug('queriedSessions: ' + queriedSessions);
                    system.debug('postedRTIdSet: ' + postedRTIdSet);
                    for (ucinn_ascendv2__Session__c eachSession: queriedSessions) {
                        // Only approve the session if all child RTs are posted
                        Boolean allRTPosted = true;
                        for (ucinn_ascendv2__Review_Transaction__c eachRT: eachSession.ucinn_ascendv2__Review_Transactions_Session__r) {
                            // If old rt's are not posted OR the RT currently being updated is not posted still.. then don't approve.
                            // Basically just want to approve as long as all the sibling RTs are posted AND the RT that is currently being updated is also being posted. 
                            // The query will not return 'Posted' status for the RT that is currently being updated since this is before update context.
                            if (eachRT.ucinn_ascendv2__Status__c != 'Posted' && !postedRTIdSet.contains(eachRT.Id)) {
                                allRTPosted = false;
                            }
                        }

                        //If coming from batch, do not run the session trigger. Be responsible for calling update giving summary batch from initial batch finish.
                        if (allRTPosted) {
                            //Approve the Process
                            DateTime completedDate = DateTime.Now();
                            eachSession.ucinn_ascendv2__Is_Ready_for_G_L__c = true;
                            eachSession.ucinn_ascendv2__Session_Totals_Approved__c = completedDate;
                            eachSession.ucinn_ascendv2__Session_Started__c = completedDate;
                            eachSession.ucinn_ascendv2__Session_Completed__c = completedDate;
                            eachSession.ucinn_ascendv2__Session_Completed_By__c = UserInfo.getUserId();
                            eachSession.ucinn_ascendv2__Is_Completed_by_Gift_Specialist__c = true;
                            eachSession.ucinn_ascendv2__Is_Sent_to_Laserfiche__c = true;

                            sessionsToUpdate.add(eachSession);
                        }
                    }

                    update sessionsToUpdate;           
                }

                //If there are any attachments that need to be deleted
                if(!listOfAttachments.isEmpty()){
                    delete listOfAttachments;                    
                }
            }
            catch(Exception e) {
                Database.rollback(sp);
                throw new applicationException(e.getMessage());
            }
        }
    }

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Update opportunities with review transaction IDs
    *******************************************************************************/
    public void updateMapOfOpportunitiesAfterInsert() {
        //Update all Opportunities with Review Transaction ID
        if(mapOfOpps != null){

            update mapOfOpps.values();
            
        }
    }

    /*******************************************************************************
    * @date         12/17/2019 
    * @description  If RT is updated to 'Posted', check for transaction data records and update cybersource related fields.
    *******************************************************************************/
    public void updateFromTransactionData(List<ucinn_ascendv2__Review_Transaction__c> trigger_new) {
        Set<ID> rtsToQuery = new Set<ID>();
        List<ucinn_ascendv2__Transaction_Data__c> transactionDataToProcess = new List<ucinn_ascendv2__Transaction_Data__c>();

        for (ucinn_ascendv2__Review_Transaction__c eachRT: trigger_new) {
            // If status has just been updated to 'Posted', update related records based on transaction data
            if (eachRT.ucinn_ascendv2__Status__c == 'Posted') {
                rtsToQuery.add(eachRT.ID);
            }
        }

        List<ucinn_ascendv2__Review_Transaction__c> queriedRTs = [SELECT ID, ucinn_ascendv2__Status__c, ucinn_ascendv2__Session__c, ucinn_ascendv2__Contact__c,
                                                    (SELECT ID FROM ucinn_ascendv2__Opportunities_Review_Transaction__r),
                                                    (SELECT ID,ucinn_ascendv2__Authorized_Date__c,
                                                                ucinn_ascendv2__Contact__c,ucinn_ascendv2__Gift_or_Pledge__c,ucinn_ascendv2__Is_Success__c,
                                                                ucinn_ascendv2__Merchant_Reference_Code__c,ucinn_ascendv2__Message__c,ucinn_ascendv2__Account__c,
                                                                ucinn_ascendv2__Reason_Code__c,ucinn_ascendv2__Request_ID__c,Review_Transaction__c,ucinn_ascendv2__Session__c,
                                                                ucinn_ascendv2__Subscription_ID__c,ucinn_ascendv2__Transaction_Type__c FROM Transaction_Data__r)
                                                    FROM ucinn_ascendv2__Review_Transaction__c 
                                                    WHERE ID IN: rtsToQuery];

        for (ucinn_ascendv2__Review_Transaction__c eachRT: queriedRTs) {
            // If transaction data records exist, parent them to the related opp/session/contact. Then carry out updates.
            if (!eachRT.Transaction_Data__r.isEmpty()) {
                ucinn_ascendv2__Transaction_Data__c thisTransData = eachRT.Transaction_Data__r[0];
                if (!eachRT.ucinn_ascendv2__Opportunities_Review_Transaction__r.isEmpty()) {
                    thisTransData.ucinn_ascendv2__Gift_or_Pledge__c = eachRT.ucinn_ascendv2__Opportunities_Review_Transaction__r[0].Id;
                }
                thisTransData.ucinn_ascendv2__Session__c = eachRT.ucinn_ascendv2__Session__c;
                thisTransData.ucinn_ascendv2__Contact__c = eachRT.ucinn_ascendv2__Contact__c;
                transactionDataToProcess.add(thisTransData);
            }
        }        
    
        update transactionDataToProcess;
        PORTAL_UCIN_CybSourceUtils.updateRelatedRecords(transactionDataToProcess);                                    
    }
    
    /**
    * Evaluate Review Transaction to check if there is a need for Manual Review
    * When matching pledge is found, add it to the matchingPledgeMap
    *
    * @param: oneRT             Review Transaction record
    */
    public void addEvaluateManualReview(ucinn_ascendv2__Review_Transaction__c oneRT) {
        if (oneRT.ucinn_ascendv2__Account__c == null && oneRT.ucinn_ascendv2__Contact__c == null) {
            ReviewTransactionUtils.addManualReviewReason(oneRT, 'Invalid Donor');
        }
        if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Pledge Payment' && oneRT.Pledge_No__c != null) {
            if (oneRT.Pledge_No__c != null) {
                Opportunity matchedPledge = rtool.getPledge(oneRT);
                if (matchedPledge != null) {
                    matchingPledgeMap.put(oneRT.ucinn_ascendv2__External_System_ID__c, matchedPledge);
                } else {
                    ReviewTransactionUtils.addManualReviewReason(oneRT, 'No Pledge match found');
                }
            }
        } else {
            if (oneRT.ucinn_ascendv2__Designation_1_Name__c == null && oneRT.ucinn_ascendv2__Designation_1__c == null) {
                ReviewTransactionUtils.addManualReviewReason(oneRT, 'Invalid Designation for designation text missing');
            } else {
                if (!(oneRT.ucinn_ascendv2__Designation_1__c != null &&
                      oneRT.ucinn_ascendv2__Is_Designation_2_Valid__c &&
                      oneRT.ucinn_ascendv2__Is_Designation_3_Valid__c &&
                      oneRT.ucinn_ascendv2__Is_Designation_4_Valid__c &&
                      oneRT.ucinn_ascendv2__Is_Designation_5_Valid__c)) {
                          ReviewTransactionUtils.addManualReviewReason(oneRT, 'Invalid Designation');
                }
            }
            if (oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c == null && oneRT.ucinn_ascendv2__Appeal_Code__c == null) {
                ReviewTransactionUtils.addManualReviewReason(oneRT, 'Invalid Appeal code for appeal code text missing');
            } else {
                if (oneRT.ucinn_ascendv2__Appeal_No_Source_Code__c != null && oneRT.ucinn_ascendv2__Appeal_Code__c == null) {
                    ReviewTransactionUtils.addManualReviewReason(oneRT, 'Invalid Appeal Code');
                }
            }
        }
        if (oneRT.ucinn_ascendv2__Transaction_Type__c == 'Pledge' && oneRT.Pledge_No__c != null) {
            Opportunity matchedPledge = rtool.getPledge(oneRT);
            if (matchedPledge != null) {
                ReviewTransactionUtils.addManualReviewReason(oneRT, 'Pledge already exist');
            }
        }
    }

    private ucinn_ascendv2__Session__c createSession(ucinn_ascendv2__Review_Transaction__c oneRT) {
        //Creates the Automatic Session for Clean Transactions
        defaultSession = new ucinn_ascendv2__Session__c();
        //defaultSession.External_System_ID__c = 'S-'+ oneRT.External_System_ID__c.substring(0,4) + '-' +String.valueOf(Date.Today()).replaceAll('[^0-9]', '');
        //Debug External System ID
        System.Debug('Session External ID for Default Session : ' + defaultSession.ucinn_ascendv2__External_System_ID__c);
        if(oneRT.ucinn_ascendv2__Description__c != null){
            defaultSession.ucinn_ascendv2__Session_Description__c = oneRT.ucinn_ascendv2__Description__c;// 07182016 Changed 'This session is assigned to '+UserInfo.getName()+'.';
            
        }
        else{
            defaultSession.ucinn_ascendv2__Session_Description__c = oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4);// 07182016 Changed 'This session is assigned to '+UserInfo.getName()+'.';
        }
        //If Transaction Type is a Pledge, Don't send to GL
        if(oneRT.ucinn_ascendv2__Transaction_Type__c == 'Pledge'){
            sendToGL = false;
            
            //Disable Matching Gift Functionality
            if(rtool != null){
                rtool.Payment_CreateMatchingGift_WantRun = false;
            }
        }
        defaultSession.Name = '[Default Name]';
        defaultSession.ucinn_ascendv2__Special_Instructions__c = oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4);
        defaultSession.ucinn_ascendv2__Session_Date__c = Date.Today();
        defaultSession.ucinn_ascendv2__Source__c = oneRT.ucinn_ascendv2__External_System_ID__c.substring(0,4);
        defaultSession.ucinn_ascendv2__Session_Operator_Assigned__c = UserInfo.getUserId();
        defaultSession.ucinn_ascendv2__Session_Completed_By__c = UserInfo.getUserId();
        defaultSession.ucinn_ascendv2__Session_Started__c = DateTime.Now();
        defaultSession.ucinn_ascendv2__Session_Completed__c = DateTime.Now();
        defaultSession.ucinn_ascendv2__Gift_Pledge_Payment_Amount__c = 0;
        defaultSession.ucinn_ascendv2__Gift_Pledge_Payment_Amount_Posted__c = 0;
        defaultSession.ucinn_ascendv2__Recurring_Gift_Pledge_Amount__c = 0;
        defaultSession.ucinn_ascendv2__Recurring_Gift_Pledge_Amount_Posted__c = 0;
        defaultSession.ucinn_ascendv2__Pledge_Amount__c = 0;
        defaultSession.ucinn_ascendv2__Pledge_Amount_Posted__c = 0;
        defaultSession.ucinn_ascendv2__No_of_Transactions__c = 1;
        
        return defaultSession;
    }

    public class applicationException extends Exception {}

}