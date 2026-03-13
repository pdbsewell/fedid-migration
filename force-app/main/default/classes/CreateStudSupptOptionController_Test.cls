/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         17/06/2024
* @description  Class that will test Student Support Options
* @revision     17/06/2024 - Initial Version
*******************************************************************************/
@isTest(isParallel=true)
public class CreateStudSupptOptionController_Test {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         8.June.2024
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
        List_of_Values__c listOfVal = (List_of_Values__c)TestDataFactory.createSObject(new List_of_Values__c(Value__c = 'testOption', System_Code_Description__c = 'tmp',
                                                        System_Code__c = 'testArea', Enquiry_Type__c = 'Student Support', Type__c = 'Student Support', Is_Active__c = true), true);

        Contact cont = (Contact)TestDataFactory.createSObject(new Contact(Salutation = 'Mr',FirstName = 'First',LastName = 'Last',Email = 'test@test.com'), true);

        Outbound_Call_Result__c listOfOCR = (Outbound_Call_Result__c)TestDataFactory.createSObject(new Outbound_Call_Result__c(Contact__c = cont.Id,Event_Link_Status__c = 'Pending'), true);
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         8.June.2024
     * @description  Tests regarding to capturing the mapping
    *******************************************************************************/ 
	@isTest 
    static void test_fetchSupportOptionMappings() {
        // GIVEN: The List of values record exists
        Test.startTest();
        // WHEN : the Method is invoked
        List<CreateStudSupptOptionController.SupportOptionWrapper> result = CreateStudSupptOptionController.fetchSupportOptionMappings();
        Test.stopTest();
        // THEN : The mappings are fetched
        Assert.areEqual(result.size(), 1, 'Mappings not fetched');      
    }

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         8.June.2024
     * @description  Tests regarding to saving the Fresh records
    *******************************************************************************/ 
	@isTest 
    static void test_saveMappings() {
        // GIVEN: OCR record exists
        Id ocrId = [SELECT Id FROM Outbound_Call_Result__c WHERE Event_Link_Status__c = 'Pending' ORDER BY createdDate DESC LIMIT 1].Id;
        String mapping = 'testArea' + '-' + 'testOption';
        Test.startTest();
        // WHEN : the Method is invoked
        String result = CreateStudSupptOptionController.saveMappings(mapping, String.valueOf(ocrId));
        Test.stopTest();
        // THEN : The mappings are fetched
        Assert.areEqual(result, 'Success', 'Mappings not fetched'); 
        List<Student_Support_Options__c> newOption = [SELECT Id FROM Student_Support_Options__c WHERE Outbound_Call__c = :ocrId];
        Assert.areEqual(newOption.size(), 1, 'New Mapping not created');     
    }
}