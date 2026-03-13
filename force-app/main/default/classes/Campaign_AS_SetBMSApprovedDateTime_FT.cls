/**
 * @description       : Test class for Campaign : AS : Set BMS Approved Date Time 
 * @author            : Vinothraja
 * @date              : 13/06/2025
 * @group             : Platforms
 * @revision
 * 13/06/2025   -   EPCP-4484 Created
**/
@isTest(isParallel = true)
public with sharing class Campaign_AS_SetBMSApprovedDateTime_FT {
    @isTest
    private static void shouldUpdateApprovedDateTime() {
        // GIVEN
        // A valid campaign record
        Campaign camp = new Campaign(Name = '-',
                                    StartDate = Date.today(),
                                    Status = 'Approved',
                                    Approved_Date_Time__c = null);
                                    
        // WHEN
        // Campaign is created 
        Test.startTest();
            insert camp;
        Test.stopTest();

        // THEN
        // Approved Date Time is filled
        camp = [SELECT Approved_Date_Time__c FROM Campaign WHERE id = :camp.Id LIMIT 1];
        Assert.isNotNull(camp.Approved_Date_Time__c, 'Approved_Date_Time__c is not populated');
    }
}