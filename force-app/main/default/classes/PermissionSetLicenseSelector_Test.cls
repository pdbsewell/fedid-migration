/**
 * @description Test class for PermissionSetLicenseSelector
 */
@isTest(isParallel=true)
public class PermissionSetLicenseSelector_Test {

    @isTest
    static void shouldReturnSObjectType() {
        PermissionSetLicenseSelector selector = 
            new PermissionSetLicenseSelector();
        System.assertNotEquals(null, selector.getSObjectType(), 
            'Expected getSObjectType to return a value');
    }

    @isTest
    static void shouldReturnEmptyListWhenPermSetLicenseIsFound() {
        PermissionSetLicenseSelector selector = 
            new PermissionSetLicenseSelector();
        List<PermissionSetLicense> result = 
            selector.selectActivePermissionSetLicenseByDeveloperName(
                'someDeveloperNameThatDoesNotExist'
            );
        System.assertEquals(true, result.isEmpty(), 
            'Expected no results because the developer name provided should ' 
            + 'not exist in the system.'
        );
    }

    @isTest
    static void shouldReturnPermSetLicenceWhenDeveloperNameMatches() {
        PermissionSetLicenseSelector selector = 
            new PermissionSetLicenseSelector();
        // a permission set license that should exist in the org
        // this can't be created as dml operation insert is not allowed on 
        // PermissionSetLicense if we try to create it as part of this unit test
        List<PermissionSetLicense> result = 
            selector.selectActivePermissionSetLicenseByDeveloperName(
                'SalesConsoleUser'
            );
        System.assertEquals(1, result.size(), 
            'Expected 1 permission set licence to be returned as the Sales ' +
            + 'Console User permission set license should exist in the org.'
        );
    }
}