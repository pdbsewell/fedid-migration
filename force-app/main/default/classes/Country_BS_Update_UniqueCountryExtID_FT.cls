/**
 * @Class              : Country_BS_Update_UniqueCountryExtID_FT.cls
 * @Description        : Test class for Country BS Update UniqueCountryExtID flow
 * @Author             : SMendu
 * @Group              : Admissions
 * @Revision           : 
 * 2024-06-21        Created 
 */
@isTest(isParallel=true)
private  class Country_BS_Update_UniqueCountryExtID_FT {

     /*
    * @description: Verifies that  Unique CountryExtID gets populated on Country_Attribute__c insert
    */
    @isTest 
    private static void shouldPopulateUniqueCountryExtID() {
    
            // GIVEN - Country_Attribute__c is created by the running user
            Country_Attribute__c country = AgentPortalTestDataBuilder.factory.createCountryAttribute(BDPConstants.AUSTRALIA_CALLISTA_CODE, 'Australia');
   
            // WHEN- Country_Attribute__c is inserted 
            Test.startTest();
                insert country;
            Test.stopTest();
            
            //THEN - uniqueCountryExternalId__c should be populated on the Country_Attribute__c record 
            Assert.isTrue(([select uniqueCountryExternalId__c from Country_Attribute__c where id=:country.Id].uniqueCountryExternalId__c!=null), 'UniqueCountryExternalId must be populated');

        
    }


   
}