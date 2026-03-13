/*
 * @author          Shalini Mendu
 * @date			23/03/2020
 * @group			Test
 * @description     Test class for batch job to run query on all the purge Custom Metadata types and purge data
 * @revision         
 *                  23/03/2020 - Stefan Scheit - Updated method name & ddescriptions
 * 					06/05/2019 - Shalini Mendu - Initial version	
 *                  03/02/2022 - Shalini Mendu - Rewriting unit code to cover new solution -  SFTG-2366 
 *
 */
@isTest(isParallel=true)
public class PurgeRecordsBatch_Test {

   
    @isTest
    static void testPurgeRecordsBatch() {
        // GIVEN, a contact qualification is defined
        Contact testContact = StudFirst_TestHelper.createInternationalApplicant();
        testContact.FirstName = 'PurgeRecordsBatch';
        testContact.LastName = 'Test';
        insert testContact;
        Contact_Qualification__c cq1 = new Contact_Qualification__c(Contact__c=testContact.Id, Deleted_on_Source__c= true);
        insert cq1;

        // WHEN, run the batch job
        Test.startTest();
        List<Purge_Recs__mdt> mdtList = [SELECT Id,Object__c, Older_than__c,BatchSize__c, Filter_Criteria__c,Filter_By_Date__c, label, order_by__c, limit__c  FROM Purge_Recs__mdt
        WHERE Label='Contact Qual Purge' and Active__c = true];
        if(!mdtList.isEmpty())
            Database.executeBatch(new PurgeRecordsBatch(mdtList[0], mdtList));
        Test.stopTest();

        // THEN, the records (Contact Qualification record(s)) should be purged
        List<Contact_Qualification__c> cq = [SELECT Id FROM Contact_Qualification__c WHERE Contact__c = :testContact.Id];
        if(!mdtList.isEmpty()){
            Assert.areEqual(0, cq.size(), 'Records not deleted.');
        }else 
        {
            Assert.areEqual(1, cq.size(), 'Records deleted.');

        }
    }
}