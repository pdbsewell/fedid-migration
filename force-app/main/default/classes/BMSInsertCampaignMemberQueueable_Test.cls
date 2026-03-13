/*******************************************************************************
* @author       Anterey Custodio
* @date         21.Nov.2016
* @description  test class for BMSInsertCampaignMemberQueueable
* @revision
*******************************************************************************/
@isTest(isParallel=true)
public class BMSInsertCampaignMemberQueueable_Test {
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         21.Nov.2016
    * @description  Schedule batch using contact Ids
    * @revision
    *******************************************************************************/
    static testMethod void test_BatchByContactIds() {
        //insert sample Contacts
        String KnownToMonashRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Known to Monash systems').getRecordTypeId();
        List<Contact> contactRecordList = BMS_TestDataHelper.buildSampleContacts();
        insert contactRecordList;

        List<Contact> changeContactRecordType = new List<Contact>();
        for (Contact contactRecord: [SELECT Id,Person_Id_unique__c, RecordTypeId FROM Contact WHERE Id IN: contactRecordList]) {
            contactRecord.RecordTypeId = KnownToMonashRecTypeId;
            changeContactRecordType.add(contactRecord);
        }

        if (!changeContactRecordType.isEmpty()) {
            update changeContactRecordType;
        }

        Campaign crmMassEmailRecord = BMS_TestDataHelper.buildSampleCRMMassEmail('Student Communication');
        insert crmMassEmailRecord;

        Test.startTest();
            List<String> contactIdList = new List<String>();
            for (Contact contactRecord: changeContactRecordType) {
                contactIdList.add(contactRecord.Id);
            }
            BMSInsertCampaignMemberQueueable campaignMemberJob = new BMSInsertCampaignMemberQueueable(contactIdList, crmMassEmailRecord.Id);
            Id jobID = System.enqueueJob(campaignMemberJob);
        Test.stopTest();

        system.assertNotEquals(null, campaignMemberJob);
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         21.Nov.2016
    * @description  Schedule batch using queryString (for big data)
    * @revision
    *******************************************************************************/
    static testMethod void test_BatchByQueryString() {
        //insert sample Contacts
        String KnownToMonashRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Known to Monash systems').getRecordTypeId();
        List<Contact> contactRecordList = BMS_TestDataHelper.buildSampleContacts();
        insert contactRecordList;

        List<Contact> changeContactRecordType = new List<Contact>();
        for (Contact contactRecord: [SELECT Id,Person_Id_unique__c, RecordTypeId FROM Contact WHERE Id IN: contactRecordList]) {
            contactRecord.RecordTypeId = KnownToMonashRecTypeId;
            changeContactRecordType.add(contactRecord);
        }

        if (!changeContactRecordType.isEmpty()) {
            update changeContactRecordType;
        }

        Campaign crmMassEmailRecord = BMS_TestDataHelper.buildSampleCRMMassEmail('Student Communication');
        insert crmMassEmailRecord;

        Test.startTest();
            String contactBatchQuery = 'SELECT Id,Person_Id_unique__c FROM Contact WHERE Person_Id_unique__c IN: searchValueSet';
            BMSInsertCampaignMemberQueueable campaignMemberJob = new BMSInsertCampaignMemberQueueable(contactBatchQuery, crmMassEmailRecord.Id, new Set<String> {changeContactRecordType[0].Person_Id_unique__c, changeContactRecordType[1].Person_Id_unique__c});
            Id jobID = System.enqueueJob(campaignMemberJob);
        Test.stopTest();

        system.assertNotEquals(null, campaignMemberJob);
    }
}