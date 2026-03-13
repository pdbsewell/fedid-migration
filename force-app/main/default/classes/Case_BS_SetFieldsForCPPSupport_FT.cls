/**
 * @description This class is a test class for the Case : BS : Set fields for CPP Support flow
 * @author Vinothraja
 * @date 02-07-2025
 * @group Platforms
 * @revision
 *  02-07-2025      Vinothraja      
 */ 
@isTest(isParallel=true)
public with sharing class Case_BS_SetFieldsForCPPSupport_FT {
    /**
     * @description Test method to verify that the Case fields are set correctly for CPP Support - Standard enquiry - during create.
     * @author Vinothraja
     * @date 02-07-2025
     * @group Platforms
     * @revision
     * 02-07-2025 Vinothraja - EPCP-5000 created
     */
    @isTest
    static void testSetFieldsForCPPSupport_StandardEnquiry_create() {
        // GIVEN
        // A new Case instance with required fields
        Case testCase = new Case(
            Subject = 'Test Case for CPP Support - Standard Enquiry',
            Origin = 'CPP - Support',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'Standard Enquiry' LIMIT 1].Id
        );
        
        // WHEN
        // The Case is created
        Test.startTest();
            insert testCase;
        Test.stopTest();
        
        // THEN
        // Verify that the fields are set correctly for CPP Support - Standard Enquiry
        testCase = [SELECT Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :testCase.Id LIMIT 1];
        Assert.areEqual('Fees & Financial Matters', testCase.Category_Level_1__c, 'Category Level 1 should be set.');
        Assert.areEqual('Commonwealth Prac Payment (CPP)', testCase.Category_Level_2__c, 'Category Level 2 should be set.');
        Assert.areEqual('Current Course', testCase.Enquiry_Type__c, 'Enquiry Type should be set.');
    }
    /**
     * @description Test method to verify that the Case fields are set correctly for CPP Support - Standard enquiry - during update.
     * @author Vinothraja
     * @date 02-07-2025
     * @group Platforms
     * @revision
     * 02-07-2025 Vinothraja - EPCP-4545 created
     */
    @isTest
    static void testSetFieldsForCPPSupport_StandardEnquiry_update() {
        // GIVEN
        // A new Case instance with required fields
        Case testCase = new Case(
            Subject = 'Test Case for CPP Support - Standard Enquiry',
            Origin = 'Back Office - General',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'Standard Enquiry' LIMIT 1].Id
        );
        insert testCase;
        // Verify that the fields are not set yet for CPP Support - Standard Enquiry
        testCase = [SELECT Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :testCase.Id LIMIT 1];
        Assert.isNull(testCase.Category_Level_1__c, 'Category Level 1 should not be set.');
        Assert.isNull(testCase.Category_Level_2__c, 'Category Level 2 should not be set.');
        Assert.isNull(testCase.Enquiry_Type__c, 'Enquiry Type should not be set.');
        
        // WHEN
        // The Case is updated
        Test.startTest();
            testCase.Origin = 'CPP - Support';
            update testCase;
        Test.stopTest();
        
        // THEN
        // Verify that the fields are set correctly for CPP Support - Standard Enquiry
        testCase = [SELECT Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :testCase.Id LIMIT 1];
        Assert.areEqual('Fees & Financial Matters', testCase.Category_Level_1__c, 'Category Level 1 should be set.');
        Assert.areEqual('Commonwealth Prac Payment (CPP)', testCase.Category_Level_2__c, 'Category Level 2 should be set.');
        Assert.areEqual('Current Course', testCase.Enquiry_Type__c, 'Enquiry Type should be set.');
    }
    /**
     * @description Test method to verify that the Case fields are set correctly for CPP Support - Special Consideration - during create.
     * @author Vinothraja
     * @date 02-07-2025
     * @group Platforms
     * @revision
     * 02-07-2025 Vinothraja - EPCP-4545 created
     */
    @isTest
    static void testSetFieldsForCPPSupport_SpecialConsideration_create() {
        // GIVEN
        // A new Case instance with required fields
        Case testCase = new Case(
            Subject = 'Test Case for CPP Support - Special Consideration',
            Origin = 'CPP - Support',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'Special Consideration' LIMIT 1].Id
        );
        
        // WHEN
        // The Case is created
        Test.startTest();
            insert testCase;
        Test.stopTest();
        
        // THEN
        // Verify that the fields are set correctly for CPP Support - Special Consideration
        testCase = [SELECT Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :testCase.Id LIMIT 1];
        Assert.areEqual('Fees & Financial Matters', testCase.Category_Level_1__c, 'Category Level 1 should be set.');
        Assert.areEqual('Commonwealth Prac Payment (CPP)', testCase.Category_Level_2__c, 'Category Level 2 should be set.');
        Assert.areEqual('Special Circumstances', testCase.Enquiry_Type__c, 'Enquiry Type should be set.');
    }
    /**
     * @description Test method to verify that the Case fields are set correctly for CPP Support - Special Consideration - during update.
     * @author Vinothraja
     * @date 02-07-2025
     * @group Platforms
     * @revision
     * 02-07-2025 Vinothraja - EPCP-4545 created
     */
    @isTest
    static void testSetFieldsForCPPSupport_SpecialConsideration_update() {
        // GIVEN
        // A new Case instance with required fields
        Case testCase = new Case(
            Subject = 'Test Case for CPP Support - Special Consideration',
            Origin = 'Back Office - General',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'Special Consideration' LIMIT 1].Id
        );
        insert testCase;
        // Verify that the fields are not set yet for CPP Support - Special Consideration
        testCase = [SELECT Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :testCase.Id LIMIT 1];
        Assert.isNull(testCase.Category_Level_1__c, 'Category Level 1 should not be set.');
        Assert.isNull(testCase.Category_Level_2__c, 'Category Level 2 should not be set.');
        Assert.isNull(testCase.Enquiry_Type__c, 'Enquiry Type should not be set.');
        
        // WHEN
        // The Case is updated
        Test.startTest();
            testCase.Origin = 'CPP - Support';
            update testCase;
        Test.stopTest();
        
        // THEN
        // Verify that the fields are set correctly for CPP Support - Special Consideration
        testCase = [SELECT Category_Level_1__c, Category_Level_2__c, Enquiry_Type__c FROM Case WHERE Id = :testCase.Id LIMIT 1];
        Assert.areEqual('Fees & Financial Matters', testCase.Category_Level_1__c, 'Category Level 1 should be set.');
        Assert.areEqual('Commonwealth Prac Payment (CPP)', testCase.Category_Level_2__c, 'Category Level 2 should be set.');
        Assert.areEqual('Special Circumstances', testCase.Enquiry_Type__c, 'Enquiry Type should be set.');
    }
}