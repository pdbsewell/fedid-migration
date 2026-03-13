/**
 * @description       : Service class to be invoked for publishing Duplicate Contact Events.
 * @author            : Sheeba T
 * @group             : Service class
 * @last modified on  : 2022-02-10
 * @last modified by  : Sheeba T
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   2022-02-10   Sheeba   Initial Version 
**/
public with sharing class DuplicateContactEventService {
    
    /***
    * Method name	: dupSetting
    * Description	: DuplicateConAutomationSetting__c to control the filters for Duplicate Automation records
    * Author		: Sheeba
    * Return Type	: n/a
    * Parameter		: n/a
    */
    public static DuplicateConAutomationSetting__c dupSetting {
        get {
            if (dupSetting == null) {
                // look in custom setting
                dupSetting = DuplicateConAutomationSetting__c.getValues('DuplicateContactSetting');
            }
            return dupSetting;
        } set;
    }

    /***
    * Method name	: dateEpochDays
    * Description	: Static ref to control the delay of duplicate automation
    * Author		: Sheeba
    * Return Type	: Integer
    * Parameter		: n/a
    */
    public static Integer dateEpochDays {
        get {
            if (dateEpochDays == null) {
                // if setting is not present, make default 3 days
                dateEpochDays = (
                    dupSetting != null
                    ? Integer.valueOf(dupSetting.LastModDays__c != null ? dupSetting.LastModDays__c : 3)
                    : 3
                );
            }
            return dateEpochDays;
        } set;
    }

    /***
    * Method name	: duplicateRuleName
    * Description	: Static ref to filter the duplicateRule for automation
    * Author		: Sheeba
    * Return Type	: String
    * Parameter		: n/a
    */
    public static String duplicateRuleName {
        get {
            if (duplicateRuleName == null) {
                // if setting is not present, make default Contact_Perfect_Match
                duplicateRuleName = (
                    dupSetting != null
                    ? String.valueOf(dupSetting.duplicateRuleName__c != null ? dupSetting.DuplicateRuleName__c : 'Contact Perfect Match')
                    : 'Contact Perfect Match'
                );
            }
            return duplicateRuleName;
        } set;
    }

    /***
    * Method name	: queryLimit
    * Description	: Static ref to limit the query for automation
    * Author		: Sheeba
    * Return Type	: String
    * Parameter		: n/a
    */
    public static Integer queryLimit {
        get {
            if (queryLimit == null) {
                // if setting is not present, make default null
                queryLimit = (
                    dupSetting != null
                    ? Integer.valueOf(dupSetting.queryLimit__c != null ? dupSetting.queryLimit__c : 1)
                    : 1
                );
            }
            return queryLimit;
        } set;
    }
    /***
    * Method name	: queryLimit
    * Description	: Static ref to limit the query for automation
    * Author		: Sheeba
    * Return Type	: List<String>
    * Parameter		: n/a
    */
    public static List<String> idList {
        get {
            if (idList == null) {
                // if setting is not present, make default null
                idList = (
                    dupSetting != null
                    ? dupSetting.idList__c != null ? dupSetting.idList__c.split(',') : null
                    : null
                );
            }
            return idList;
        } set;
    }

    /***
    * Method name	: Use Process Flag On DRS
    * Description	: Static reference to indicate if the the process flag on the DRS records need to be used for automation
    * Author		: Sachin Shetty
    * Return Type	: Boolean
    * Parameter		: n/a
    */
    public static Boolean UseProcessFlagOnDRS {
        get {
            if (UseProcessFlagOnDRS == null) {
                // if setting is not present, make default false
                UseProcessFlagOnDRS = dupSetting != null
                                    ? dupSetting.Use_Process_Flag_On_DRS__c
                                    : false;
            }
            return UseProcessFlagOnDRS;
        } set;
    }

    /**
     * @description     Invokable method for the scheduled flow to publish duplicate Contact Events to handle duplicate contact records.
     * @revision
     *                  05.Feb.2022 - Sheeba - Initial Version                  
     */
    @InvocableMethod(label='Publish Events' description='Publish Duplicate Contact Events')
    public static void publishEvents(){
        Date d = System.today() - dateEpochDays;
        
        String condition = ' and createdDate >: d and recordCount > 1';
        String likeFilter = duplicateRuleName + '%';
        if(idList != null && !idList.isempty()){
            condition = ' and ID IN : idList';
        }
        if(UseProcessFlagOnDRS){
            condition = ' and Process__c = true';
        }
        String query = 'Select Id from DuplicateRecordSet where (DuplicateRule.MasterLabel LIKE :duplicateRuleName OR Parent.Name LIKE :likeFilter) ' + condition;
        if(queryLimit != null){
            if(queryLimit > 0){
                query += ' LIMIT : queryLimit';
            }
            else{
                LogUtilityException.logExceptionMSG('Error', queryLimit, 'QueryLimit must be a non-negative number');
            }
        }

        List<Duplicate_Contact_Event__e> eventsList = new List<Duplicate_Contact_Event__e>();
        for(DuplicateRecordSet drs : Database.query(query)) {
            Duplicate_Contact_Event__e dc = DuplicateContactEventService.createPayloadItem(drs.Id, 'DuplicateContactEventService.DuplicateContactAutomation');
            if (dc != null) {
                eventsList.add(dc);
            }
        }
        EventBus.publish(eventsList); 
    }


    public static Duplicate_Contact_Event__e createPayloadItem(Id drsId, String processName) {
        Duplicate_Contact_Event__e dc;
        if (drsId != null && String.isNotBlank(processName)) {
            AsyncProcessPayload payload = new AsyncProcessPayload();
            payload.put('drsIds', new Set<Id> {drsId});
            dc = new Duplicate_Contact_Event__e(
                Process_Name__c = processName,
                Parameter__c = payload.serialize()
                );
        }
        return dc;
    }

    /**
     * @description     Logic to perform duplicate handling by invoking DuplicateRecordSetService and ContactMergeController methods.
     * @revision
     *                  05.Feb.2022 - Sheeba - Initial Version                  
     */
    public class DuplicateContactAutomation implements IPlatformEventInvocable {

        private Set<Id> drsIds = new Set<Id>();
        private Id primaryAccountId;
        private Id duplicateAccountId;
        private Id primaryContactId;
        private Id duplicateContactId;
        private Integer counter;
        private Integer totalRecordCount;
        private String uniqueId;
        private String queueProcess;
        @TestVisible
        public String payloadKeyDrsIds = 'drsIds';
        public String payloadKeyPrimaryAccountId = 'primaryAccountId';
        public String payloadKeyDuplicateAccountId = 'duplicateAccountId';
        public String payloadKeyPrimaryContactId = 'primaryContactId';
        public String payloadKeyDuplicateContactId = 'duplicateContactId';
        public String payloadKeyCounter = 'counter';
        public String payloadKeyTotalRecordCount = 'totalRecordCount';
        public String payloadKeyUniqueId = 'uniqueId';
        public String payloadKeyQueueProcess = 'queueProcess';

        public void execute(List<AsyncProcessPayload> payload) {
            try {
                initialize(payload);
                run();
            } catch(Exception e) {
                LogUtilityException.logException(e, this.drsIds);
            } finally {
                LogUtilityException.getLimits();
            }
        }

        public void run() {
            System.debug(LoggingLevel.FINEST, '### DuplicateContactEventService drsIds ==>' + drsIds);
            
            // Invoke MergeAccount of Contact Merge Controller class
            if(queueProcess == 'MergeAccount'){
                if(primaryAccountId != null && duplicateAccountId != null && primaryContactId != null){
                    ContactMergeController.mergeAccount(primaryAccountId, duplicateAccountId, primaryContactId);
                }
                else{
                    LogUtilityException.addLogEvent('Account', queueProcess, 'Merge account process has failed due to insufficient attributes - primaryAccountId: ' + primaryAccountId + ' duplicateAccountId : ' + duplicateAccountId + ' primaryContactId : '+ primaryContactId , 'DuplicateContactAutomation.run');
                }
            }else if(queueProcess == 'MergeContact'){
                if(primaryContactId != null && duplicateContactId != null){
                    ContactMergeController.mergeContact(primaryContactId, duplicateContactId);
                }
                else{
                    LogUtilityException.addLogEvent('Contact', queueProcess, 'Merge Contact process has failed due to insufficient attributes - primaryContactId: ' + primaryContactId + ' duplicateContactId : ' + duplicateContactId , 'DuplicateContactAutomation.run');
                }
            }
            else if(queueProcess == 'PostMerge'){
                if(primaryContactId != null){
                    //invoke post merge logic in the right order as in the merge tool
                    ContactMergeController.recalculatePrimaryLeads(primaryContactId);
                    ContactMergeController.evaluateCulateContactPoints(primaryContactId);
                    ContactMergeController.recalCulateContactPoints(primaryContactId, true);
                    DCAStagingEventUtility.dispatchStagingEvent(primaryContactId, counter, totalRecordCount, uniqueId, false);
                    
                    //Update the merge status of surviving User records
                    ContactMergeController.updateUserMergeStatus(primaryContactId);
                }
                else{
                    LogUtilityException.addLogEvent('PostMerge', queueProcess, 'Post Merge process has failed due to insufficient attributes - primaryContactId: ' + primaryContactId , 'DuplicateContactAutomation.run');
                }
                
            }
            // Invoke duplicate handling service class
            else{
                if(drsIds != null){
                    DuplicateRecordSetService.handleDuplicates(drsIds);
                }
                else{
                    LogUtilityException.addLogEvent('DuplicateRecordSet', queueProcess, 'Duplicate Contact Automation cannot be performed due to null set of duplicate record set Ids.', 'DuplicateContactAutomation.run');
                }                
            }
            LogUtilityException.publishAll();            
        }

        /**
         * @description initialize process by extracting the method
         *  parameters from the platform event payload
         */
        private void initialize(List<AsyncProcessPayload> payloads) {
            if (payloads != null) {
                for(AsyncProcessPayload payload : payloads) {
                    Map<String, Object> allArgs = payload.getArgs();
                    if (allArgs != null && !allArgs.isEmpty()){
                        if(allArgs.containsKey(payloadKeyDrsIds)) {
                            // Get drs Id
                            //first, cast the get return of List<Object> into List<Id>
                            List<Object> objList1 = (List<Object>) payload.get('drsIds');
                            if (objList1 != null) {
                                //then, instantiate a Set out of it
                                for (Object io : objList1) {
                                    //parse object to ID
                                    this.drsIds.add(Id.valueOf(io.toString()));
                                }
                            }
                        }
                        if(allArgs.containsKey(payloadKeyPrimaryAccountId)) {
                            // Get primaryId
                            Object obj = (Object) payload.get('primaryAccountId');
                            if (obj != null) {
                                this.primaryAccountId = (obj.toString());
                            }
                        }
                        if (allArgs.containsKey(payloadKeyDuplicateAccountId)) {
                            // Get duplicateId
                            Object obj = (Object) payload.get('duplicateAccountId');
                            if (obj != null) {
                                this.duplicateAccountId = (obj.toString());
                            }
                        }
                        if (allArgs.containsKey(payloadKeyPrimaryContactId)) {
                            // Get primaryId
                            Object obj = (Object) payload.get('primaryContactId');
                            if (obj != null) {
                                this.primaryContactId = (obj.toString());
                            }
                        }
                        if (allArgs.containsKey(payloadKeyDuplicateContactId)) {
                            // Get duplicateId 
                            Object obj = (Object) payload.get('duplicateContactId');
                            if (obj != null) {
                                this.duplicateContactId = (obj.toString());
                            }
                        }
                        if (allArgs.containsKey(payloadKeyQueueProcess)) {
                            // Get queueProcess Name for either Merge or PostMerge process
                            Object obj = (Object) payload.get('queueProcess');
                            if (obj != null) {
                                this.queueProcess = (obj.toString());
                            }
                        }
                        if (allArgs.containsKey(payloadKeyCounter)) {
                            // Get counter
                            Object obj = (Object) payload.get('counter');
                            if (obj != null) {
                                this.counter = Integer.valueOf(obj);
                            }
                        }
                        if (allArgs.containsKey(payloadKeyTotalRecordCount)) {
                            // Get totalRecordCount
                            Object obj = (Object) payload.get('totalRecordCount');
                            if (obj != null) {
                                this.totalRecordCount = Integer.valueOf(obj);
                            }
                        }
                        if (allArgs.containsKey(payloadKeyUniqueId)) {
                            // Get uniqueId
                            Object obj = (Object) payload.get('uniqueId');
                            if (obj != null) {
                                this.uniqueId = (obj.toString());
                            }
                        }
                    }
                }
            }
        }
    }
}