/**
 * @Class              : Qualification_BI_Populate_QualUID_FT.cls
 * @Description        : Test class forQualification_BI_Populate_QualUID flow
 * @Author             : SMendu
 * @Group              : Admissions
 * @Revision           : 
 * 2024-06-21           Created 
 */
@isTest(isParallel=true)
private  class Qualification_BI_Populate_QualUID_FT {
     /*
    * @description: Verifies Qualification UID gets populated on Qualification insert
    */
    @isTest 
    private static void shouldPopulateQualificationUID() {
            //GIVEN a valid Qualification is created by the running user
            Qualification__c qual = new Qualification__c();
            qual.Qualification_Name__c = 'IELTS';
            qual.Overseas__c = false;
            qual.Callista_Code__c = '123';
            qual.Sub_score_Type__c = 'Listening; Reading; Speaking; Writing';   
            // WHEN- that Qualification__c is inserted 
            Test.startTest();
                insert qual;
            Test.stopTest();
            
            //THEN - Qualification_UID__c  must have been populated on the Qualification__c record 
            Assert.isTrue(([select Qualification_UID__c from Qualification__c where id=:qual.Id].Qualification_UID__c!=null), 'UniqueCountryExternalId must be populated');
        
    }

}