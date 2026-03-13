/**
 * @author      Kristian Vegerano
 * @description Test class for AccountUtility class
 * @group       Test Class
 * @revision    13/12/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
public with sharing class AccountUtility_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
    }

    /**
     * @description Test retrieve agency record type id
     */
    @isTest 
    static void test_RetrieveRecordTypes() {
        //Start test process
	 	Test.startTest();
            Id agencyRecTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE;
	 	Test.stopTest();

        //Start assertion
        System.assertNotEquals(agencyRecTypeId, null);
    }
    /**
     * @description Test retrieve external record type id
     */
    @isTest 
    static void external_RetrieveRecordTypes() {
        //Start test process
	 	Test.startTest();
            Id extenalRecTypeId = AccountUtility.ACCOUNT_EXTERNAL_ORG_REC_TYPE;
	 	Test.stopTest();

        //Start assertion
        System.assertNotEquals(extenalRecTypeId, null);
    }
    
    
}