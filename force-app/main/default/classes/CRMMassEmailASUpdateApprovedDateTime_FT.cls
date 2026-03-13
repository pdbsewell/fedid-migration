/**
 * @description       : Test class for CRM Mass Email: AS: Update Approved DateTime
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 08-08-2025
 * @last modified by  : Jackie Ho
**/
@isTest(isParallel=true)
public with sharing class CRMMassEmailASUpdateApprovedDateTime_FT {
    @testSetup
    static void setupTestData() {
        // GIVEN: Common setup for all test methods
        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);

        CRM_Mass_Email__c CRM_Mass_Email = new CRM_Mass_Email__c();
        CRM_Mass_Email.Status__c = 'New';
        insert CRM_Mass_Email;

    }
    
    @isTest
    static void testUpdateApprovedDateTime() {
        CRM_Mass_Email__c CRM_Mass_Email = [SELECT Id, Approved_Date_Time__c 
                                    FROM CRM_Mass_Email__c 
                                    ORDER BY createddate DESC 
                                    LIMIT 1];
        
        // WHEN: Update approved date time
        Test.startTest();
        CRM_Mass_Email.Status__c = 'Approved';
        update CRM_Mass_Email;
        Test.stopTest();

        // THEN: Verify results
        CRM_Mass_Email = [SELECT Id, Approved_Date_Time__c 
                                    FROM CRM_Mass_Email__c 
                                    ORDER BY createddate DESC 
                                    LIMIT 1];
        Assert.isNotNull(CRM_Mass_Email.Approved_Date_Time__c, 'Approved Date Time should be updated');
    }
}