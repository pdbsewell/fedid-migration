/**
 * @description       : Test class for PermsetFileCreator.
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2020-11-13
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2020-11-11   Stefan Scheit   Initial Version
**/
@isTest(isParallel=true)
public class PermsetFileCreator_Test {
    
    
    /**
     * Basic test to ensure the permission set xml output is generated.
     */
    @isTest
    public static void testPersetFileCreator() {
        // GIVEN: an instance
        PermsetFileCreator creator = new PermsetFileCreator();
        // pick an object different to Account, Contact, or Case to shorten execution time of the test
        SObjectType sobjType = AuthorizationFormConsent.getSObjectType();
        
        // WHEN: a permission set is generated
        Test.startTest();
        String outputXml = creator.generate(sobjType);
        Test.stopTest();
        
        // THEN: The permission set xml is generated (and not blank)
        System.assert(String.isNotBlank(outputXml), 'The generated permission set xml string is blank.');
        
        // THEN: The permission set xml contains the SobjectType
        String objPermission = String.format('<object>{0}</object>', new List<String>{sobjType.getDescribe().getName()});
        System.assert(outputXml.contains(objPermission), 'The generated permission set xml does not contain the object permissions for the Sobject input.');
    }
}