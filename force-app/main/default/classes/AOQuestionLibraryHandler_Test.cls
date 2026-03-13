/**
 * @author : [Babyshark]
 * @description : Test class for AOQuestionLibraryHandler and AOQuestionLibraryTrigger
 * @group : Abroad Outbound
 * @date : 19/05/2024
 * @rev
 * 
 */
@isTest(isParallel=true)
private class AOQuestionLibraryHandler_Test {
	@TestSetup
    static void makeData(){
        AOTestDataFactory.createQuestionLibrary(true);
    }
    /**
     * @description - Test validateQuestionDuplication class on Question Library trigger Handler for Insert scenario
     * @revision
     */
    @isTest
    static void testInsertvalidateQuestionDuplication(){
        AO_Question_Library__c qlib01 = new AO_Question_Library__c(
            Name = 'Test Text Question',
            AO_Type__c = 'Text',
            AO_Default_Value__c = 'Default Value',
            AO_Help_Text__c = 'Help Text',
            AO_Question__c = 'Enter Your Text Answer',
            AO_Prefill_Value_Object__c = 'Contact',
            AO_Prefill_Value_Field__c = 'Preferred_Name__c'
        );
        try{
        	AOTestDataFactory.createQuestionLibrary(qLib01, true);
        }
        catch(Exception ex){
            Assert.isTrue(ex.getMessage().contains('The Question with same type has already been created please use the existing Question or rename your question'), 'Duplicate Question is created');
        }
    }
    /**
     * @description - Test validateQuestionDuplication class on Question Library trigger Handler for Update scenario
     * @revision
     */
    @isTest
    static void testUpdatevalidateQuestionDuplication(){
        AO_Question_Library__c qlib01 = new AO_Question_Library__c(
            Name = 'Test Duplicate Question',
            AO_Type__c = 'Text',
            AO_Default_Value__c = 'Default Value',
            AO_Help_Text__c = 'Help Text',
            AO_Question__c = 'Enter Your Text Answer',
            AO_Prefill_Value_Object__c = 'Contact',
            AO_Prefill_Value_Field__c = 'Preferred_Name__c'
        );
        AOTestDataFactory.createQuestionLibrary(qLib01, true);
        qLib01.Name= 'Test Test Question';
        try{
        	update qLib01;
        }
        catch(Exception ex){
            Assert.isTrue(ex.getMessage().contains('The Question with same type has already been created please use the existing Question or rename your question'), 'Duplicate Question is created');
        }
    }
}