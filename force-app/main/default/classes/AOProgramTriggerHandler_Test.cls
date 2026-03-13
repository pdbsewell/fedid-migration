/**
 * @author : [Babyshark]
 * @description : Test class for AOProgramTriggerHandler class
 *  - Tests Duplicate Program creation based upon Program Name
 * @group : Abroad Outbound
 * @date : 19/08/2024
 * @rev
 * 
 */
@isTest(isParallel=true)
private class AOProgramTriggerHandler_Test {
    @TestSetup
    static void makeData(){
        AOTestDataFactory.createProgram(true);
    }
     /**
     * @description - Test testCheckDuplicateName class on Program trigger Handler for creation of Duplicate Programs
     * @revision
     */
    @isTest
    static void testCheckDuplicateNameInsert(){
        try{
            AOTestDataFactory.createProgram(true);
        }
        catch(Exception ex){
            Assert.isTrue(ex.getMessage().contains('The Program Name has already been taken , Please use a different Name'));
        }
    }
    /**
     * @description - Test testCheckDuplicateName class on Program trigger Handler for creation of Duplicate Programs
     * @revision
     */
    @isTest
    static void testCheckDuplicateNameUpdate(){
        
        AO_Program__c objP = new AO_Program__c(
            Name='Global Study Test 02',
            AO_Description__c = 'Global study tours',
            AO_Form_Deadline_Date__c = Date.Today().addDays(5),
            AO_Program_Location__c ='Malaysia',
            AO_Program_Type__c = 'Global Study Tours (GST)',
            AO_Program_Year__c = String.valueOf(Date.Today().year()),
            End_Date__c = Date.Today().addDays(7),
            Start_Date__c = Date.Today(),
            Terms__c = 'Sem 1 & Sem 2'
        );
        AO_Program__c program = AOTestDataFactory.createProgram(objP, true);
        try{
            program.Name='Global Study Test 01';
            update program;
        }
        catch(Exception ex){
            Assert.isTrue(ex.getMessage().contains('The Program Name has already been taken , Please use a different Name'));
        }
    }
}