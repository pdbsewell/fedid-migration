/**
 * @description       : Common Utility ERDA - Test Class
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 05-05-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest
public with sharing class CommonUtilityERDA_Test {
	@isTest
    public static void generateRandomStringTest(){
        String strRandomString = null;
        Test.startTest();
        strRandomString = CommonUtilityERDA.generateRandomString(10);
        Test.stopTest();
        System.assert(strRandomString!=null, 'Random string generated.');

    }
}