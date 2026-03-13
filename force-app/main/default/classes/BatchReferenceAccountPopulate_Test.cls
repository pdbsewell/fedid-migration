/**
 * @author          Steffi
 * @description     Test class for Batch class for BatchReferenceAccountPopulate
 * @revision        
 */
@isTest(isParallel=false)
public class BatchReferenceAccountPopulate_Test {
@testSetup
    static void setup(){
        
        //reference data..
        Id cmpRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('ERDA Guest List').getRecordTypeId();
        Id monashRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();
        
        //creating a new Welcome campiagn 
        Campaign cmp = new Campaign(Name='Welcome Campaign', IsActive=true, RecordTypeId = cmpRecordTypeId);
        insert cmp;
        
         //setting campaign into Custom setting
        Alumni_Welcome_Campaign__c setting = new Alumni_Welcome_Campaign__c();
		setting.id__c = cmp.Id;
		insert setting;
        
        //create a Alumni Community User Access  and put Id Account into custom Setting..    
        Account acc = new Account(Name='Alumni Community User Access',RecordTypeId= monashRecordTypeId);
        insert acc;
        
        //setting Account Id into Custom setting
        Alumni_Community_User_Access__c AlumniSetting = new Alumni_Community_User_Access__c();
        AlumniSetting.Id__c =acc.Id;
        insert AlumniSetting;
        
        //creating a contact with no reference account
        List<Contact> lstCont = new List<Contact>();
        lstCont = TestHelper.createOrphanContactRecords(2);
        lstCont[0].Personal_Email__c = 'john@invalid.com';
        lstCont[1].Personal_Email__c = 'Smithr@invalidd.com';
        insert lstCont;
        
        //adding Contacts into Campaign...
        List<CampaignMember> lstCmpMember = new List<CampaignMember>{
                new CampaignMember(CampaignId = cmp.Id, SSA__c = UserInfo.getUserId(), ContactId = lstCont.get(0).Id,Status='Sent'),
                new CampaignMember(CampaignId = cmp.Id, SSA__c = UserInfo.getUserId(), ContactId = lstCont.get(1).Id,Status='Sent')

        };
        insert  lstCmpMember;
            
    }
    //method is used to test the BatchReferenceAccountPopulate
    static testmethod void BatchReferenceAccountPopulateTest() {
        Test.startTest();
        BatchReferenceAccountPopulate uca = new BatchReferenceAccountPopulate();
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();
        // after the testing stops, assert records were inserted properly
        List<Contact> conList = [select id,Reference_account__c from Contact];
        System.assertNotEquals(null, conList[0].Reference_account__c);

    }
}