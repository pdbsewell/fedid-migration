@isTest(isParallel=true)
public class EngageInterimService_Test {

    @isTest
    //For testing Interim phone type population.
    public static void testEngageInterimServiceREPhone() {

        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__Phone_1__c = '1231231234',
                ucinn_ascendv2__Phone_2__c = '2231231234',
                ucinn_ascendv2__Phone_3__c = '3231231234',
                ucinn_ascendv2__Phone_4__c = '4231231234',
                ucinn_ascendv2__Phone_5__c = '5231231234',
                RecordTypeID = reRecordTypeID);

        insert testInterim;

        testInterim = [SELECT 	ucinn_ascendv2__Phone_1_Type__c,
                                ucinn_ascendv2__Phone_2_Type__c,
                                ucinn_ascendv2__Phone_3_Type__c,
                                ucinn_ascendv2__Phone_4_Type__c,
                                ucinn_ascendv2__Phone_5_Type__c
                                FROM ucinn_ascendv2__Interim__c
                                WHERE Id =: testInterim.Id];

        System.debug(testInterim.ucinn_ascendv2__Phone_1_Type__c);
        System.assert(testInterim.ucinn_ascendv2__Phone_1_Type__c == 'Mobile', 'Phone 1 should be Mobile.');
        System.assert(testInterim.ucinn_ascendv2__Phone_2_Type__c == 'Landline', 'Phone 2 should be Landline.');
        System.assert(testInterim.ucinn_ascendv2__Phone_3_Type__c == 'Undefined', 'Phone 3 should be Undefined.');
        System.assert(testInterim.ucinn_ascendv2__Phone_4_Type__c == 'Other', 'Phone 4 should be Other.');
        System.assert(testInterim.ucinn_ascendv2__Phone_5_Type__c == 'Assistant', 'Phone 5 should be Assistant.');
    }

    @isTest
    //For testing Interim email type population.
    public static void testEngageInterimServiceREEmail() {

        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__Email_1__c = 'Email@Email.com',
                ucinn_ascendv2__Email_2__c = 'Email2@Email.com',
                Email_3__c = 'Email3@Email.com',
                RecordTypeID = reRecordTypeID);

        insert testInterim;

        testInterim = [SELECT 	ucinn_ascendv2__Email_1__c,
                                ucinn_ascendv2__Email_1_Type__c,
                                ucinn_ascendv2__Email_2__c,
                                ucinn_ascendv2__Email_2_Type__c,
                                Email_3_Type__c,
                                Email_3__c
                                FROM ucinn_ascendv2__Interim__c
                                WHERE Id =: testInterim.Id];

        System.assert(testInterim.ucinn_ascendv2__Email_1_Type__c == 'Private', 'Email 1 should be Private.');
        System.assert(testInterim.ucinn_ascendv2__Email_2_Type__c == 'Private', 'Email 2 should be Private.');
        System.assert(testInterim.Email_3_Type__c == 'Business', 'Email 3 should be Business.');
    }
	
	/*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         22.Feb.2023
     * @description  Tests regarding Interim phone formatting.
    *******************************************************************************/ 
    @isTest
    public static void testFormatMobile() {

        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Online_Donation_Interface' AND SObjectType = 'ucinn_ascendv2__Interim__c'].Id;

        ucinn_ascendv2__Interim__c testInterim = (ucinn_ascendv2__Interim__c)TestDataFactory.createSObject(new ucinn_ascendv2__Interim__c(ucinn_ascendv2__Phone_1__c = '52312/31234', RecordTypeID = reRecordTypeID), true);

        testInterim = [SELECT ucinn_ascendv2__Phone_1__c FROM ucinn_ascendv2__Interim__c WHERE Id =: testInterim.Id];

        System.assertEquals('5231231234', testInterim.ucinn_ascendv2__Phone_1__c);
    }

    @isTest
    //For testing Interim email type population.
    public static void testEngageInterimServiceZkipPhone() {

        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Zkipster_Interface' AND RecordType.NamespacePrefix = ''].Id;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__Phone_1__c = '1231231234',
                ucinn_ascendv2__Phone_2__c = '2231231234',
                ucinn_ascendv2__Phone_3__c = '3231231234',
                ucinn_ascendv2__Phone_4__c = '4231231234',
                ucinn_ascendv2__Phone_5__c = '5231231234',
                RecordTypeID = reRecordTypeID);

        insert testInterim;

        testInterim = [SELECT 	ucinn_ascendv2__Phone_1_Type__c,
                                ucinn_ascendv2__Phone_2_Type__c,
                                ucinn_ascendv2__Phone_3_Type__c,
                                ucinn_ascendv2__Phone_4_Type__c,
                                ucinn_ascendv2__Phone_5_Type__c
                                FROM ucinn_ascendv2__Interim__c
                                WHERE Id =: testInterim.Id];

        System.assert(testInterim.ucinn_ascendv2__Phone_1_Type__c == 'Mobile', 'Phone 1 should be Mobile.');
        System.assert(testInterim.ucinn_ascendv2__Phone_2_Type__c == 'Landline', 'Phone 2 should be Landline.');
        System.assert(testInterim.ucinn_ascendv2__Phone_3_Type__c == 'Undefined', 'Phone 3 should be Undefined.');
        System.assert(testInterim.ucinn_ascendv2__Phone_4_Type__c == 'Other', 'Phone 4 should be Other.');
        System.assert(testInterim.ucinn_ascendv2__Phone_5_Type__c == 'Assistant', 'Phone 5 should be Assistant.');
    }

    @isTest
    //For testing Interim phone type population with no record type.
    public static void testEngageInterimServiceNoRecordTypePhone() {

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__Phone_1__c = '1231231234',
                ucinn_ascendv2__Phone_2__c = '2231231234',
                ucinn_ascendv2__Phone_3__c = '3231231234',
                ucinn_ascendv2__Phone_4__c = '4231231234',
                ucinn_ascendv2__Phone_5__c = '5231231234',
                RE_ID__c = '123125412125');

        insert testInterim;

        testInterim = [SELECT 	ucinn_ascendv2__Phone_1_Type__c,
                                ucinn_ascendv2__Phone_2_Type__c,
                                ucinn_ascendv2__Phone_3_Type__c,
                                ucinn_ascendv2__Phone_4_Type__c,
                                ucinn_ascendv2__Phone_5_Type__c
                                FROM ucinn_ascendv2__Interim__c
                                WHERE Id =: testInterim.Id];

        System.assert(testInterim.ucinn_ascendv2__Phone_1_Type__c == 'Mobile', 'Phone 1 should be Mobile.');
        System.assert(testInterim.ucinn_ascendv2__Phone_2_Type__c == 'Landline', 'Phone 2 should be Landline.');
        System.assert(testInterim.ucinn_ascendv2__Phone_3_Type__c == 'Undefined', 'Phone 3 should be Undefined.');
        System.assert(testInterim.ucinn_ascendv2__Phone_4_Type__c == 'Other', 'Phone 4 should be Other.');
        System.assert(testInterim.ucinn_ascendv2__Phone_5_Type__c == 'Assistant', 'Phone 5 should be Assistant.');
    }
    
    @isTest
    //For testing Interim Name generation
    public static void testInterimNameGeneration() {

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(RE_ID__c = '123125412125');

        insert testInterim;

        testInterim = [SELECT Id, Name, ucinn_ascendv2__Interim_Name_Auto_Number__c
                                FROM ucinn_ascendv2__Interim__c
                                WHERE Id =: testInterim.Id];

        System.assert(testInterim.Name == testInterim.ucinn_ascendv2__Interim_Name_Auto_Number__c);

    }


}