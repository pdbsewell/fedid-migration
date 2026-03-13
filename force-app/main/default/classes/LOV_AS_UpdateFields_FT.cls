/**
 * @author          Matthew Maramot
 * @description     Test class for List_of_Values_AS_Update_Fields flow
 * @revision
 * 	2025-05-06 - Matthew Maramot - Created class
 */
    
@isTest(isParallel=true)
public with sharing class LOV_AS_UpdateFields_FT {
    //Standard
    static final string value = 'SATISFIED';
    static final string sysCode = 'COND-OFFER';
    static final string type = 'ADM_OUTCOME_STATUS';

    //CaseCategorisation
    static final string enqType = 'Future Course Test';
    static final string catOne = 'Supervisor Accreditation Test' ;
    static final string catTwo = 'Other Test';
    static final string typeCase = 'CaseCategorisation';
    
    /*******************************************************************************
     * @author       Matthew Maramot
     * @date         06.May.2025
     * @description  Test that name and unique key are correctly set when inserting List of Values record
    *******************************************************************************/
	@isTest 
    static void lovInsert() {
        //GIVEN: We have new LOV records
        List<List_of_Values__c> lovList = new List<List_of_Values__c>{
        new List_of_Values__c(
            Unique_Key__c = 'OFFER-G-CO',
            Value__c = value,
            System_Code__c = sysCode,
            Name = 'TESTNAME',
            Type__c = type),
            
        new List_of_Values__c(
                Unique_Key__c = 'FutureCourse',
                Value__c = value,
                System_Code__c = sysCode,
                Name = 'TESTNAME',
                Type__c = typeCase,
                Enquiry_Type__c = enqType,
                Category_Level_1__c = catOne,
                Category_Level_2__c = catTwo
        )};

        //WHEN: It is inserted
        Test.startTest();
        insert lovList;
        Test.stopTest();

        //THEN: Name and Unique Key should be properly formatted;
        List_Of_Values__c lovStandard = [SELECT Name, Unique_Key__c FROM List_Of_Values__c WHERE Type__c =: type LIMIT 1];
        String expectedName = value + ' (' + sysCode + ')';
        String expectedKey =  value + '-' + type;
        Assert.areEqual(lovStandard.Name, expectedName, 'LOV Name did not get properly set');
        Assert.areEqual(lovStandard.Unique_Key__c, expectedKey, 'LOV Unique Key did not get properly set');

        List_Of_Values__c lovCC = [SELECT Name, Unique_Key__c FROM List_Of_Values__c WHERE Type__c =: typeCase LIMIT 1];
        String expectedCaseName =  catOne + '>' + catTwo;
        String expectedCaseKey =  enqType + '-' + catOne + '-' + catTwo;
        Assert.areEqual(lovCC.Name, expectedCaseName, 'CaseCategorisation LOV Name did not get properly set');
        Assert.areEqual(lovCC.Unique_Key__c, expectedCaseKey, 'CaseCategorisation LOV Unique Key did not get properly set');
    }

    /*******************************************************************************
     * @author       Matthew Maramot
     * @date         06.May.2025
     * @description  Test that name and unique key are correctly set when updating List of Values record
    *******************************************************************************/
	@isTest 
    static void lovUpdate() {
        //GIVEN: We have existing LOV records
        List<List_of_Values__c> lovList = new List<List_of_Values__c>{
            new List_of_Values__c(
            Unique_Key__c = 'OFFER-G-CO',
            Value__c = 'DOC-ENROL',
            System_Code__c = 'SATISFIED',
            Name = 'TESTNAME',
            Type__c = type
            ),
                
            new List_of_Values__c(
                    Unique_Key__c = 'Current Course',
                    Value__c = 'MGRO00523',
                    System_Code__c = 'MGRO00523',
                    Name = 'TESTNAME',
                    Type__c = typeCase,
                    Enquiry_Type__c = 'Current Course',
                    Category_Level_1__c = 'MGE Admissions',
                    Category_Level_2__c = 'Other',
                    System_Code_Description__c = 'testDescription'
        )};
        insert lovList;

        //WHEN: they are updated
        List<List_of_Values__c> updateLOVList = new List<List_of_Values__c>();

        List_Of_Values__c lovUpdate = [SELECT Value__c, System_Code__c, Type__c  FROM List_Of_Values__c WHERE Type__c =: type LIMIT 1];
        lovUpdate.value__c = value;
        lovUpdate.system_Code__c = sysCode;
        updateLOVList.add(lovUpdate);

        List_Of_Values__c lovCCUpdate = [SELECT System_Code_Description__c, Enquiry_Type__c, Category_Level_1__c, Category_Level_2__c  FROM List_Of_Values__c WHERE Type__c =: typeCase LIMIT 1];
        lovCCUpdate.System_Code_Description__c = 'updatedDescription';
        lovCCUpdate.Enquiry_Type__c = enqType;
        lovCCUpdate.Category_Level_1__c = catOne;
        lovCCUpdate.Category_Level_2__c = catTwo;
        updateLOVList.add(lovCCUpdate);

        Test.startTest();
        update updateLOVList;
        Test.stopTest();

        //THEN: Name and Unique Key should be properly formatted;
        String expectedName = value + ' (' + sysCode + ')';
        String expectedKey =  value + '-' + type;
        List_Of_Values__c lovStandard = [SELECT Name, Unique_Key__c FROM List_Of_Values__c WHERE Type__c =: type LIMIT 1];
        Assert.areEqual(lovStandard.Name, expectedName, 'LOV Name did not get properly set');
        Assert.areEqual(lovStandard.Unique_Key__c, expectedKey, 'LOV Unique Key did not get properly set');

        List_Of_Values__c lovCC = [SELECT Name, Unique_Key__c FROM List_Of_Values__c WHERE Type__c =: typeCase LIMIT 1];
        String expectedCaseName =  catOne + '>' + catTwo;
        String expectedCaseKey =  enqType + '-' + catOne + '-' + catTwo;
        Assert.areEqual(lovCC.Name, expectedCaseName, 'CaseCategorisation LOV Name did not get properly set');
        Assert.areEqual(lovCC.Unique_Key__c, expectedCaseKey, 'CaseCategorisation LOV Unique Key did not get properly set');
    }
}