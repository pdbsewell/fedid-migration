/**
 * @author : [Babyshark]
 * @description : Test class for FormElementsCloneService
 * @group : Abroad Outbound
 * @date : 19/08/2024
 * @rev
 * 
 */
@isTest(IsParallel=true)
public with sharing class FormElementsCloneService_Test {
    
    @TestSetup
    static void makeData(){
        AOTestDataFactory.setupForms();
    }

    /**
     * @description : test method to check if form elements are successfully cloned to the new form
     */
    @isTest
    static void testCloneFormElements(){
        
        AO_Form__c form = [SELECT id,Name,AO_Form_Display_Name__c,AO_Form_Description__c,AO_Active__c FROM AO_Form__c LIMIT 1][0];
        List<AO_Form_Element__c> formElements = [SELECT 
                                                 	id, Element_Definition__c, Label__c, Parent_Element__c, Name,Visibility_Rule_Form_Element__c, AO_Type__c
                                                 FROM 
                                                 	AO_Form_Element__c 
                                                 WHERE 
                                                	Form__c =: form.id];

        FormElementsCloneService.inputs inputs = new FormElementsCloneService.inputs();
        list<FormElementsCloneService.inputs> inputsList = new list<FormElementsCloneService.inputs>();

        AO_Form__c newForm = form.clone(false,false,false,false);
        insert newForm;
        
        inputs.newFormId = newForm.Id;
        inputs.formElementsList = formElements;

        inputsList.add(inputs);

        Test.startTest();
        List<String> results = FormElementsCloneService.cloneFormElements(inputsList);
        Test.stopTest();

        List<AO_Form_Element__c> newFormElements = [SELECT 
                                                    	id
                                                    FROM 
                                                    	AO_Form_Element__c 
                                                    WHERE 
                                                    	Form__c =: newForm.id];
        
        assert.areEqual(formElements.size(),newFormElements.size(),'all form elements have not been cloned');
    }
}