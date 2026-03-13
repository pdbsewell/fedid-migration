/**
 * @author Trent De Laney
 * @date 24 Jan 2020 at 2:24:31 pm
 * @group Test Class
 * @description Test class for Engage Utils
 */
@IsTest
public with sharing class EngageUtils_Test {
    @IsTest
    public static void test_getRecordTypeIDByDeveloperName(){
        Contact c = new Contact();
        Id result = EngageUtils.getRecordTypeIDByDeveloperName(c, 'Non_Student');
        System.assertNotEquals(result, null, 'Unable to find record type');
    }

    @IsTest
    public static void test_getBadRecordTypeIDByDeveloperName(){
        Contact c = new Contact();
        Id result = EngageUtils.getRecordTypeIDByDeveloperName(c, 'dummy');
        System.assertEquals(result, null, 'Found an unexpected record type');
    }
}