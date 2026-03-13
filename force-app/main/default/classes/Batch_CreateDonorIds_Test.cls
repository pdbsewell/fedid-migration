/**
 * @author Charlie Park, UC Innovation
 * @date 11/20/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test Class for PORTAL_UCIN_EventListingUtil_Test
 */
@isTest(isParallel=true)
public class Batch_CreateDonorIds_Test {
    @IsTest
    public static void test_Batch()
    {
        Contact thisContact = new Contact();
        thisContact.LastName = 'test';
        insert thisContact;

        test.startTest();
        Batch_CreateDonorIds createDonorIds = new Batch_CreateDonorIds();
        createDonorIds.objectName = 'Contact';
        Database.executeBatch(createDonorIds, 1);
        test.stopTest();

        thisContact = [SELECT ID,ucinn_ascendv2__Donor_ID__c FROM Contact LIMIT 1];
        system.assertNotEquals(thisContact.ucinn_ascendv2__Donor_ID__c, '');
    }
}