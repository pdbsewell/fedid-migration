/*
 * Flow Test Coverage 
 * Flow Name: Case : BS : Assign MCR fields
 * Flow API: V60.0
 * Flow Version : 1.0
 */
@isTest
(seeAllData=false isParallel=true)public class CaseBSAssignMCRfields_FT {
    
    @testSetup
    public static void createTestData() {
    
        list<list_of_values__c> LOVs = new list<list_of_values__c> {
            new list_of_values__c (enquiry_type__c ='Current Course', category_Level_1__c='Enrolment - Current Course', category_Level_2__c='Intermission', Type__c='CaseCategorisation', value__c='LOVTST1', System_Code__c='LOVTST1',Is_Active__c=true,Is_Active_system_code__c=true),
            new list_of_values__c (enquiry_type__c ='Current Course', category_Level_1__c='Enrolment - Current Course', category_Level_2__c='Alt Exit', Type__c='CaseCategorisation', value__c='LOVTST2', System_Code__c='LOVTST2',Is_Active__c=true,Is_Active_system_code__c=true),
            new list_of_values__c (enquiry_type__c ='Future Course', category_Level_1__c='Course Enquiry', category_Level_2__c='Course Information', Type__c='CaseCategorisation', value__c='LOVTST3', System_Code__c='LOVTST3',Is_Active__c=true,Is_Active_system_code__c=true)
        };
        insert LOVs;
        
        Case aCase = new Case (Subject='Existing Case for updates', CaseTypeCategorisation__c=LOVs[0].id);
        insert aCase;
            
    }
  
   /*
    * EnquiryCheck NewCaseRecord branch test
    * 
    * GIVEN
    * 	A new case in inserted
    * WHEN
    * 	A valid MCR lookup have been included
    * THEN
    *   The enquiry type, category level 1 & 2 should all be prepopulated based on the LOV values
    */
    @isTest
    public static void enquirycheck_newCase() {
		Case aCase; 
        list<list_of_values__c> LOVs = [select id, enquiry_type__c, category_Level_1__c, category_Level_2__c from list_of_values__c where Type__c='CaseCategorisation']; 

        aCase = new Case (Subject='Insert a new case', CaseTypeCategorisation__c=LOVs[0].id);
		test.startTest();
        insert aCase;
		test.stopTest();
        
        aCase = [select id, enquiry_type__c, category_Level_1__c, category_Level_2__c, CaseTypeCategorisation__c from case where id = :aCase.id];
        
        Assert.areEqual(LOVs[0].Enquiry_Type__c, aCase.Enquiry_Type__c);
        Assert.areEqual(LOVs[0].category_Level_1__c, aCase.category_Level_1__c);
        Assert.areEqual(LOVs[0].category_Level_2__c, aCase.category_Level_2__c);
    }
    

   /*
    * EnquiryCheck UpdateCaseRecord branch test
    * 
    * GIVEN
    * 	A case in update
    * WHEN
    * 	The MCR lookup value has been changed
    * THEN
    *   The enquiry type, category level 1 & 2 should all updated based on the new LOV value
    */
    @isTest
    public static void enquirycheck_updatedCase() {
        list<list_of_values__c> LOVs = [select id, enquiry_type__c, category_Level_1__c, category_Level_2__c from list_of_values__c where Type__c='CaseCategorisation']; 
        Case aCase = [select id, enquiry_type__c, category_Level_1__c, category_Level_2__c, CaseTypeCategorisation__c from case limit 1];

        test.startTest();
        aCase.CaseTypeCategorisation__c = LOVs[1].id;
        update aCase;
		test.stopTest();
        
        aCase = [select id, enquiry_type__c, category_Level_1__c, category_Level_2__c, CaseTypeCategorisation__c from case where id = :aCase.id];

	    Assert.areEqual(LOVs[1].Enquiry_Type__c, aCase.Enquiry_Type__c);
	    Assert.areEqual(LOVs[1].category_Level_1__c, aCase.category_Level_1__c);
	    Assert.areEqual(LOVs[1].category_Level_2__c, aCase.category_Level_2__c);
    }
    
   /*
    * EnquiryCheck MCRControlledFieldChanged branch test
    * 
    * GIVEN
    * 	A case in updated
    * WHEN
    * 	One of the driven fields is changed 
    * THEN
    *   The MCR field should be cleared but the other fields will remain unchanged
    */
    @isTest
    public static void enquirycheck_MCRControlledFieldChanged() {
        Case aCase = [select id, enquiry_type__c, category_Level_1__c, category_Level_2__c, CaseTypeCategorisation__c from case limit 1];
        list_of_values__c LOV = [select id, enquiry_type__c, category_Level_1__c, category_Level_2__c from list_of_values__c where id = :aCase.CaseTypeCategorisation__c]; 

		test.startTest();
        aCase.Enquiry_Type__c = 'Future Course';
        update aCase;
		test.stopTest();
        
        aCase = [select id, enquiry_type__c, category_Level_1__c, category_Level_2__c, CaseTypeCategorisation__c from case where id = :aCase.id];

	    Assert.areEqual('Future Course', aCase.Enquiry_Type__c);
	    Assert.isNull(aCase.CaseTypeCategorisation__c,'Changing the Enquiry Type should have cleared the MCR lookup');
	    Assert.areEqual(LOV.category_Level_1__c, aCase.category_Level_1__c, 'The Category level 1 value should be unaltered');
	    Assert.areEqual(LOV.category_Level_2__c, aCase.category_Level_2__c, 'The Category level 1 value should be unaltered');
    }
}