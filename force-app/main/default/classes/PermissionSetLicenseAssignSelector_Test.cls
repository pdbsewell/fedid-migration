/**
 * @description Test class for PermissionSetLicenseAssignSelector
 */
@isTest(isParallel=true) 
public class PermissionSetLicenseAssignSelector_Test {

    @isTest
    static void shouldReturnSObjectType() {
        PermissionSetLicenseAssignSelector selector = 
            new PermissionSetLicenseAssignSelector();
        System.assertNotEquals(null, selector.getSObjectType(), 
            'Expected getSObjectType to return a value');
    }

    @isTest
    static void shouldReturnNoPermSetLicenseAssignWhenLicenseIdDoesNotExist() {
        PermissionSetLicenseAssignSelector selector = 
            new PermissionSetLicenseAssignSelector();
        
        // Permission Set Licenses are tied to the org's metadata and can't be 
        // created in Apex for unit testing, so the scenario to unit test is 
        // limited

        List<PermissionSetLicenseAssign> permSetLicenseAssign = 
            selector.selectPermissionSetLicenseAssignByUserIdsAndLicenseId(
                new Set<Id>(), 
                FakeRecordIdGenerator.generateId(PermissionSetLicense.getSObjectType())
            );
        System.assertEquals(true, permSetLicenseAssign.isEmpty(), 
            'Expected no permission set license returned because id provided ' 
            + 'does not exist.'
        );
    }
}