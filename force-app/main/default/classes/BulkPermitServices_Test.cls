/**
 * @description     Test class for BulkPermitServices service class
 * 
 * @author          K. Vegerano
 * @date            26/08/2020
 * 
 * @revision
 * 
 *      26/08/2020 - K Vegerano - created
 *      26/08/2020 - K Vegerano - added tests for BuildCongaParameters
 */
@isTest(isParallel=true)
public with sharing class BulkPermitServices_Test {

    /**
     * Set up Data
     * @return [description]
     */
    @testSetup static void setupData(){
        APXTConga4__Conga_Template__c testCongaTemplate = new APXTConga4__Conga_Template__c(APXTConga4__Name__c = 'Child Care Permit Template');
        insert testCongaTemplate;
    }

    static testMethod void testInsertPermit() {
        Conga_Bulk_Processing__c testPermit = new Conga_Bulk_Processing__c(
            SAP_Staff_Id__c = '7127579',
            Title__c = 'Mr.',
            First_name__c = 'TestFirstName',
            Last_name__c = 'TestLastName',
            Date_of_Birth__c = '6/06/1990',
            Position_Title__c = 'Assistant Lecturer',
            Street__c = '100 St. Kilda Road',
            Suburb__c = 'Melbourne',
            State__c = 'VIC',
            Postcode__c = '3004',
            Start_Date__c = '11/08/2020',
            End_Date__c = '12/08/2020',
            Status__c = 'Ready for Processing',
            Permit_Type__c = 'Childcare Permit',
            Permitted_Worker_Category__c = '',
            Work_Location_Campus__c = 'Test Work Location Campus',
            Work_Location_Address__c = 'Test Work Location Address',
            Faculty_Division__c = 'Test Faculty Division',
            School_Division__c = 'Test School Division',
            Organisational_Unit_Text__c = 'Test Unit Text'
        );

        //start tests
        Test.startTest();
        insert testPermit;
        Test.stopTest();

        //assert results
        Conga_Bulk_Processing__c resultPermit = [SELECT Id, Conga_Template_Id__c, Email_Template_Id__c, Email_From_Id__c, Subject_Content__c, Email_BCC__c 
                                                 FROM Conga_Bulk_Processing__c 
                                                 WHERE Id = :testPermit.Id];
        System.assertNotEquals(null, resultPermit.Conga_Template_Id__c);
        System.assertNotEquals(null, resultPermit.Email_Template_Id__c);
        System.assertNotEquals(null, resultPermit.Email_From_Id__c);
        System.assertNotEquals(null, resultPermit.Subject_Content__c);
        System.assertNotEquals(null, resultPermit.Email_BCC__c);
    }

    static testMethod void testUpdatePermit() {
        Conga_Bulk_Processing__c testPermit = new Conga_Bulk_Processing__c(
            SAP_Staff_Id__c = '7127579',
            Title__c = 'Mr.',
            First_name__c = 'TestFirstName',
            Last_name__c = 'TestLastName',
            Date_of_Birth__c = '6/06/1990',
            Position_Title__c = 'Assistant Lecturer',
            Street__c = '100 St. Kilda Road',
            Suburb__c = 'Melbourne',
            State__c = 'VIC',
            Postcode__c = '3004',
            Start_Date__c = '11/08/2020',
            End_Date__c = '12/08/2020',
            Status__c = 'Permit Issued',
            Permit_Type__c = 'Childcare Permit',
            Permitted_Worker_Category__c = '',
            Work_Location_Campus__c = 'Test Work Location Campus',
            Work_Location_Address__c = 'Test Work Location Address',
            Faculty_Division__c = 'Test Faculty Division',
            School_Division__c = 'Test School Division',
            Organisational_Unit_Text__c = 'Test Unit Text'
        );
        insert testPermit;

        //start tests
        Test.startTest();
        testPermit.Status__c = 'Ready for Processing';
        update testPermit;
        Test.stopTest();

        //assert results
        Conga_Bulk_Processing__c resultPermit = [SELECT Id, Conga_Template_Id__c, Email_Template_Id__c, Email_From_Id__c, Subject_Content__c, Email_BCC__c 
                                                 FROM Conga_Bulk_Processing__c 
                                                 WHERE Id = :testPermit.Id];
        System.assertNotEquals(null, resultPermit.Conga_Template_Id__c);
        System.assertNotEquals(null, resultPermit.Email_Template_Id__c);
        System.assertNotEquals(null, resultPermit.Email_From_Id__c);
        System.assertNotEquals(null, resultPermit.Subject_Content__c);
        System.assertNotEquals(null, resultPermit.Email_BCC__c);
    }
}