/**
 * @author Charlie Park, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Test class for listing sort picklist
 */
@isTest(isParallel=true)
public class PORTAL_UCIN_ListingSortPickList_Test {
	@IsTest
    public static void test_all_methods()
    {
        test.startTest();
        PORTAL_UCIN_ListingSortPickList listSortPick = new PORTAL_UCIN_ListingSortPickList();
        System.assertNotEquals(listSortPick.getDefaultValue(), null);
        System.assertEquals(listSortPick.getValues().size(), 3);
        test.stopTest();
    }
}