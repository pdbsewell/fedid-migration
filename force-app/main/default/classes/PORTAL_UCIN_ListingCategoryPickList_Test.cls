/*
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for listing category picklist
 */
@isTest(isParallel=true)
public class PORTAL_UCIN_ListingCategoryPickList_Test {
	@IsTest
    public static void callAllFunctions()
    {
        Schema.DescribeFieldResult fr = Listing__c.Category__c.getDescribe();

        test.startTest();
        PORTAL_UCIN_ListingCategoryPickList listCatPick = new PORTAL_UCIN_ListingCategoryPickList();
        System.assertNotEquals(listCatPick.getDefaultValue(), null);
        System.assertEquals(listCatPick.getValues().size(), fr.getPicklistValues().size());
        test.stopTest();
    }
}