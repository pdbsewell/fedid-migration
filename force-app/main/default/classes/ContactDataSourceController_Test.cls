/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group	Retention (Monash Connect) - BabyShark
 */

@isTest(isParallel=true)
private class ContactDataSourceController_Test {

    // This method tests if values for contact field lookup in App Builder
    // configuration are being generated properly or not.
    static testMethod void testAppBuilderDesignComponent() {
        Test.startTest();
        
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Outbound_Call_Result__c';
        context.pageType = 'RecordPage';
        ContactDataSourceController cdsc = new ContactDataSourceController(context);
		VisualEditor.DynamicPickListRows rows = cdsc.getValues();
        
        Test.stopTest();
        
        System.assertEquals(1, rows.size(), 'App Builder design configuration is not working.');
    }
    
}