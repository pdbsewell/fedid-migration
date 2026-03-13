/**
 * @author      Kristian Vegerano
 * @description Test class for ContactQualificationUtility class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
public with sharing class ContactQualificationUtility_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
    }

    /**
     * @description Test select accounts by Id
     */
    @isTest 
    static void test_RetrieveRecordTypes() {
        //Start test process
	 	Test.startTest();
            Id englishRecTypeId = ContactQualificationUtility.CONTACT_QUALIFICATION_ENGLISH_REC_TYPE;
            Id secondaryRecTypeId = ContactQualificationUtility.CONTACT_QUALIFICATION_SECONDARY_REC_TYPE;
            Id tertiaryRecTypeId = ContactQualificationUtility.CONTACT_QUALIFICATION_TERTIARY_REC_TYPE;
            Id otherRecTypeId = ContactQualificationUtility.CONTACT_QUALIFICATION_OTHER_REC_TYPE;
	 	Test.stopTest();

        //Start assertion
        System.assertNotEquals(englishRecTypeId, null);
        System.assertNotEquals(secondaryRecTypeId, null);
        System.assertNotEquals(tertiaryRecTypeId, null);
        System.assertNotEquals(otherRecTypeId, null);
    }
}