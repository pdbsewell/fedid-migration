/**
 * @author : [Babyshark]
 * @description : Test class for AOProgramFormMapTriggerHandler
 * @group : Abroad Outbound
 * @date : 16/08/2024
 * @rev
 * 
 */ 
@IsTest(isParallel=true)
private class AOProgramFormMapTriggerHandler_Test {
    @TestSetup
    static void makeData(){
        AOTestDataFactory.setupForms();
      
    }
    @IsTest
    static void testCreateEncyptedText(){

        //GIVEN - Form has been successfully constructed
        AO_Program_Form_Map__c formM = [SELECT Id, AO_Encoded_Id__c, AO_Form_Name__c FROM AO_Program_Form_Map__c LIMIT 1];

        // WHEN - Get the Encoded Id
        Test.startTest();
        Assert.isNotNull(formM.AO_Encoded_Id__c,'Encoded Id for Form Map hasn\'t been created');
        Test.stopTest();
    }
}