@IsTest(isParallel=true)
public  with sharing class UnitOfferingServices_Test {
    
    /*
     * Verify the trigger has populated the name and uo key fields
     * GIVEN
     * A new Unit Offering
     * WHEN
     * It is inserted without a name or unique key values
     * THEN
     * The values will be calculated
   	 */
    @isTest
    public static void unitOfferOperations(){
        Unit_Offering__c aUO = new Unit_Offering__c();
        
        aUO.Academic_Year__c = '2021';
		aUO.Active_Ind__c = true;
		aUO.Location__c = 'Clayton';
        aUO.Unit_Version__c = '1';
        aUO.Unit_Code__c = 'UnitXYZ';
        aUO.Calendar_Type__c = 'S0-1';
        aUO.Teaching_Period__c = 'S0-1';
        aUO.CI_Sequence_Number__c = '10001';
        aUO.Unit_Class__c = 'ON-CAMPUS';
		
        test.startTest();
        insert aUO;
        test.stopTest();
		
        Unit_Offering__c rUO = [Select name, uo_unique_key__c from unit_offering__c where id = :aUO.id];
        
        Assert.areEqual(unitOfferingServices.getUniqueName(aUO), rUO.name, 'Unit Offering name does not match expected pattern');
        Assert.areEqual(unitOfferingServices.getUniqueKey(aUO), rUO.UO_Unique_Key__c, 'Unit Offering key does not match expected pattern');
        
    }

}