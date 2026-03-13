/**
 * @description     Controller class for TaskPartialMatch.cmp
 * @author          J.Mapanao
 * @date            24/05/2019
 * 
 * @revision
 *                  26.MAR.2020 - J.Mapanao         - Modified flagDuplicate() to accommodate advance contact merging
 *                                                      contact points search
 *                  25.MAY.2020 - KL                - Changes for epic SFTLG-802
 * 					27.07.2023  - Seeva             - Added Code for EPCP-2864
 */
public with sharing class TaskPartialMatchCtrl {
    @TestVisible
    private static String sObj = 'Contact';
    @TestVisible
    private static String fieldSetApiName = 'Partial_Match_Field_Sets';
    @TestVisible
    private static List<Schema.FieldSetMember> partialMatchFieldSets {get;set;}
    @TestVisible
    private static List<String> columnFieldApi {get;set;}
    @TestVisible
    private static List<Datacloud.FindDuplicatesResult> duplicateContacts{get;set;}
    @TestVisible
    private static Set<Id> contactIds {get;set;}
    
    public TaskPartialMatchCtrl() {
        // constructor
    }
    
    public static void init() {
        partialMatchFieldSets = new List<Schema.FieldSetMember>();
        duplicateContacts = new List<Datacloud.FindDuplicatesResult>();
        contactIds = new Set<Id>();
    }
    
    /**
	 * @description Fetch field sets for table columns
	 * @param String masterContactId
	 */
    @AuraEnabled
    public static List<ColumnDefinitionWrapper> getDataTableColumns(){
        init();
        //List<Schema.FieldSetMember> fieldSetMember = SObjectType.Contact.FieldSets.Partial_Match_Field_Sets.getFields();
        List<Schema.FieldSetMember> fieldSetMember = getFieldSetMembers(sObj,fieldSetApiName);
        List<ColumnDefinitionWrapper> tableColumns = new List<ColumnDefinitionWrapper>();
        
        for (FieldSetMember fsm : fieldSetMember) {
            String temp_Label = (String) fsm.getLabel();
            String temp_FieldName = (String) fsm.getFieldPath();
            
            ColumnDefinitionWrapper colDefWrapper = new ColumnDefinitionWrapper();
            colDefWrapper.label = temp_Label;
            colDefWrapper.fieldName = temp_FieldName;
            colDefWrapper.type = 'text';
            colDefWrapper.sortable = false;
            
            // Create hyperlink for Name column
            if (colDefWrapper.fieldName == 'Name') {
                colDefWrapper.fieldName = 'linkName';
                colDefWrapper.type = 'url';
                
                LabelWrapper lWrapper = new LabelWrapper();
                lWrapper.fieldName = temp_FieldName;
                
                TypeAttributeWrapper taWrapper = new TypeAttributeWrapper();
                taWrapper.label = lWrapper;
                taWrapper.target = '_blank';
                
                colDefWrapper.typeAttributes = taWrapper;
            }
            tableColumns.add(colDefWrapper);
        }
        System.debug('### tableColumns ==> ' + JSON.serializePretty(tableColumns));
        return tableColumns;
    }
    
    /**
	 * @description Fetch details of Application's Applicant (Contact record)
	 * @param String masterContactId
	 */
    @AuraEnabled
    public static List<Contact> showMasterContact(String applicationId) {
        List<Contact> masterContact = new List<Contact>();
        List<Application__c> application = getApplicationDetails(applicationId);
        if (application != null && !application.isEmpty()) {
            partialMatchFieldSets = getFieldSetMembers(sObj,fieldSetApiName);
            if (partialMatchFieldSets != null && !partialMatchFieldSets.isEmpty()) {
                retrieveFieldApiFromFieldSetMember();
                masterContact = retrieveMasterContact(application.get(0).Applicant__c);
            }
        }
        return masterContact;
    }

    /**
	 * @description     Fetch details of Potential Contact Match records from Application's Applicant (Contact record)
	 * @param           String applicationId
	 * @param           Integer limits
	 * @param           Integer offsets
     * @return          List<Contact>
	 */
    @AuraEnabled
    public static List<Contact> showDupContacts(String applicationId, Integer limits, Integer offsets) {
        
        Integer intLimits = Integer.valueof(limits);
        Integer intOffsets = Integer.valueof(offsets);
        List<Contact> dupContactList = new List<Contact>();
        //ADDED TO RUN NEW CODE VIA CUSTOM SETTING SWITCH
        Feature_Switch__c fs = Feature_Switch__c.getInstance();
            if(fs.Enable_Enhanced_Admissions_Contact_Merge__c) {
                dupContactList = showDupContactsViaPlatform(applicationId,limits,offsets);
            }
        else{
        // Query application record details
        List<Application__c> application = getApplicationDetails(applicationId);
        if (!application.isEmpty()) {
            List<Contact> contactList = TaskDupCheckHelper.queryContactFieldsForSearchingDuplicates(application.get(0).Applicant__r.Id);

            if (contactIds == null) {
                contactIds = new Set<Id>();
            }
            // Find if there are Potential Match and/or Loose Match and/or email search and/or person id match
            contactIds = TaskDupCheckHelper.findPotentialDuplicateContacts(contactList.get(0));

            if (!contactIds.isEmpty()) {
                // Retrieve field set 1. for querying duplicate contact details 2. dynamic column definition in data table
                partialMatchFieldSets = getFieldSetMembers(sObj,fieldSetApiName);
                if (!partialMatchFieldSets.isEmpty()) {
                    retrieveFieldApiFromFieldSetMember();
                    dupContactList = retrieveContacts(contactIds, intLimits, intOffsets);
                }
            }
        }
        }
        return dupContactList;
    }
    
    @AuraEnabled
    public static void mergeContacts(String applicationId, String childContactIds) {
        List<Id> childConIds = (List<Id>) JSON.deserialize(childContactIds, List<Id>.class);
        System.debug('### mergeContacts => childConIds ==>'+childConIds);
        List<Application__c> application = getApplicationDetails(applicationId);
        String masterConId = null;
        if (!application.isEmpty()) {
            masterConId = application.get(0).Applicant__c;
            if (String.isNotBlank(masterConId)) {
                //ADDED SWITCH TO USE PLATFORM'S CODE
                Feature_Switch__c fs = Feature_Switch__c.getInstance();
                if(fs.Enable_Enhanced_Admissions_Contact_Merge__c ) {
                AdmissionsDupCheckHelper helper = new AdmissionsDupCheckHelper();
                    helper.init(masterConId,new Set<Id>(childConIds));
            }
                else{
						TaskDupCheckHelper helper = new TaskDupCheckHelper();
                    helper.init(masterConId,new Set<Id>(childConIds));
					}
                Async_Process__e evt = createPayload(masterConId);
                EventBus.publish(evt);
            }
        }
    }

    private static Async_Process__e createPayload(Id conId) {
        Async_Process__e evt;
        
        if(conId != null) {
            AsyncProcessPayload payload = new AsyncProcessPayload();
            payload.put ('contactId', new Set<Id> {conId});
            Feature_Switch__c fs = Feature_Switch__c.getInstance();
            String processName ='';
            //TO USE PLATFORM'S CODE
            if(fs.Enable_Enhanced_Admissions_Contact_Merge__c ) {
              processName='AdmissionDupCheckServices.PerformContactPointRehash';
            }
            else{
                processName='DupCheckServices.PerformContactPointRehash';
            } 
            evt = new Async_Process__e (
                //SEEVA - ADDING NEW CODE TO HANDLE POST MERGE ACTIVITIES
                Process_Name__c = processName,
                Parameter__c = payload.serialize()
            );
        }
        return evt;
    }    
    
    @TestVisible
    private static List<Schema.FieldSetMember> getFieldSetMembers(String sObj, String fieldSetApiName) {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(sObj);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetApiName);
        return (fieldSetObj != null && fieldSetObj.getFields() != null) ? fieldSetObj.getFields() : new List<Schema.FieldSetMember>(); 
    }
    
    @TestVisible
    private static void retrieveFieldApiFromFieldSetMember() {
        if (columnFieldApi == null) {
            columnFieldApi = new List<String>();
        }
        if (partialMatchFieldSets != null && !partialMatchFieldSets.isEmpty()) {
            Set<String> tempColumns = new Set<String>();
            for (Schema.FieldSetMember fsm : partialMatchFieldSets) {
                tempColumns.add(fsm.getFieldPath());
            }
            if (!tempColumns.isEmpty())
                columnFieldApi = new List<String>(tempColumns);
        }
    }
    
    private static List<Application__c> getApplicationDetails(String applicationId) {
        return new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id FROM Application__c WHERE Id =: applicationId]);
    }
    
    @TestVisible
    private static List<Contact> retrieveContacts(Set<Id> contactIds, Integer limits, Integer offsets) {
        List<Contact> potentialDuplicateContacts = new List<Contact>();
        if (columnFieldApi != null && !columnFieldApi.isEmpty()) {
            String soql = 'SELECT ';
            soql += String.join(columnFieldApi, ',');
            if (!soql.contains('Id')) {
                soql += ',Id';
            }
            soql += ' FROM Contact';
            soql += ' WHERE Id IN: contactIds';
            soql += ' Limit :limits Offset :offsets';
            System.debug('### retrieveContacts soql ==> ' + soql);
            potentialDuplicateContacts = Database.query(soql);
        }
        return potentialDuplicateContacts;
    }
    
    @TestVisible
    private static List<Contact> retrieveMasterContact(String masterConId) {
        List<Contact> masterContact = new List<Contact>();
        if (columnFieldApi != null && !columnFieldApi.isEmpty()) {
            String soql = 'SELECT ';
            soql += String.join(columnFieldApi, ',');
            if (!soql.contains('Id')){
                soql += ',Id';
            }
            soql += ' FROM Contact';
            soql += ' WHERE Id =: masterConId';
            System.debug('### retrieveMasterContact soql ==> ' + soql);
            masterContact = Database.query(soql);
        }
        return masterContact;
    }
   /**
	 * @description     Fetch details of Potential Contact Match records from Application's Applicant (Contact record)
	 * @param           String applicationId
	 * @param           Integer limits
	 * @param           Integer offsets
     * @return          List<Contact>
     * @author          Seeva
	 */
    @AuraEnabled
    public static List<Contact> showDupContactsViaPlatform(String applicationId, Integer limits, Integer offsets) {
        Integer intLimits = Integer.valueof(limits);
        Integer intOffsets = Integer.valueof(offsets);
        List<Contact> dupContactList = new List<Contact>();
        
        // Query application record details
        List<Application__c> application = getApplicationDetails(applicationId);
        if (!application.isEmpty()) {
            
			// SEEVA - Added Platform Team's code
                Set<Id> appsContactIdSet = new Set<Id>();
        if (String.isNotBlank(application.get(0).Applicant__r.Id)) {
            appsContactIdSet.ADD(application.get(0).Applicant__r.Id);
        }
        	List<Contact> contactList = ContactMergeHelper.getContacts(null, null, null, null,appsContactIdSet);
            if (contactIds == null) {
                contactIds = new Set<Id>();
            }
            // Find if there are Potential Match and/or Loose Match and/or email search and/or person id match
            contactIds = AdmissionsDupCheckHelper.findPotentialDuplicateContacts(contactList.get(0));
            if (!contactIds.isEmpty()) {
                // Retrieve field set 1. for querying duplicate contact details 2. dynamic column definition in data table
                partialMatchFieldSets = getFieldSetMembers(sObj,fieldSetApiName);
                if (!partialMatchFieldSets.isEmpty()) {
                    retrieveFieldApiFromFieldSetMember();
                    dupContactList = retrieveContacts(contactIds, intLimits, intOffsets);
                }
            }
        }
        return dupContactList;
    }
     
    public class ColumnDefinitionWrapper {
        @AuraEnabled
        public string label {get;set;}
        @AuraEnabled
        public String fieldName {get;set;}
        @AuraEnabled
        public string type {get;set;}
        @AuraEnabled
        public boolean sortable {get;set;}
        @AuraEnabled
        public TypeAttributeWrapper typeAttributes {get;set;}
    }
    
    public class TypeAttributeWrapper {
        @AuraEnabled
        public LabelWrapper label {get;set;}            
        @AuraEnabled
        public String target {get;set;}
    }
    
    public class LabelWrapper {
        @AuraEnabled
        public String fieldName {get;set;}
    }
}