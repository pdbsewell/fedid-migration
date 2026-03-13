/*
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for listing record type pick list
 */
 @IsTest
public class PORTAL_UCIN_ListingRecordTypePickTest {
    @IsTest
	public static void test_all_methods()
    {
        List<RecordType> rtList = [Select Name, DeveloperName From RecordType Where SObjectType='Listing__c'];

        test.startTest();
        PORTAL_UCIN_ListingRecordTypePickList listRecTypePick = new PORTAL_UCIN_ListingRecordTypePickList();
        System.assertNotEquals(listRecTypePick.getDefaultValue(), null);
        System.assertEquals(listRecTypePick.getValues().size(), rtList.size());
        test.stopTest();
    }
    
}