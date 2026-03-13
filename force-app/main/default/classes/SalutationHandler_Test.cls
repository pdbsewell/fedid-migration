/**
 * For testing salutation creation
 * 
 * @author 		Mark Johnson - UC Innovation
 * @date        01/05/2019    
 * @revision
 */

@isTest(isParallel=true)
public class SalutationHandler_Test {
	
    @isTest
    public static void salutationDefaultNameCreationTest() {
        
        ucinn_ascendv2__Trigger_Handler__c ascTrigHandler = new ucinn_ascendv2__Trigger_Handler__c(Name = 'SalutationHandler', ucinn_ascendv2__Class__c = 'SalutationHandler', 
                                                                                                   ucinn_ascendv2__Object__c = 'ucinn_ascendv2__Salutation__c', ucinn_ascendv2__Load_Order__c = 1.00, ucinn_ascendv2__Is_Active__c = true,
                                                                                                   ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete');
        
        insert ascTrigHandler;
        
        Contact testCon = new Contact(LastName = 'salutationDefaultNameCreationTest');
        insert testCon;
        
        ucinn_ascendv2__Salutation__c salutation = new ucinn_ascendv2__Salutation__c();
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);
        
        salutation.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Salutation__c.getRecordTypeInfosByDeveloperName().get('Individual_Salutation').getRecordTypeId();
        salutation.ucinn_ascendv2__Contact__c = testCon.Id;
        salutation.ucinn_ascendv2__Salutation_Type__c = 'Formal';
        salutation.ucinn_ascendv2__Inside_Salutation__c = 'Salutation';
        salutation.ucinn_ascendv2__Addressee_Line_1__c = 'Salutation';
        salutation.ucinn_ascendv2__Addressee_Line_2__c = 'Default';
        salutation.ucinn_ascendv2__Addressee_Line_3__c = 'Name';
        salutation.ucinn_ascendv2__Salutation_Author__c = 'Honor Roll';
        salutation.Name = '[Default Name]';
        
        insert salutation;
        
        ucinn_ascendv2__Salutation__c queriedSalutation = [SELECT Name FROM ucinn_ascendv2__Salutation__c WHERE Id =: salutation.Id LIMIT 1];

        System.assert(queriedSalutation.Name.startsWith('SAL'));
	}
}