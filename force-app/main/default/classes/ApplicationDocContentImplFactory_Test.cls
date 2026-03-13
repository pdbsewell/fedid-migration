/**
 * @description Covers the ApplicationDocumentContentImplFactory class
 * @author      Kai-Fan Hsieh
 * @since       08/08/2024
 */
@isTest(isParallel=true)
private class ApplicationDocContentImplFactory_Test {
    /**
     * @description Tests the getImplementation method of the ApplicationDocumentContentImplFactory class.
     * This test verifies that the correct implementation of RESTlib_IClientImpl is returned
     * based on the user's persona. Specifically, it checks that a DigitaryApplicationDocumentImpl
     * is returned for Digitary users and throws an error when no implementation is found.
     */
    @isTest
    private static void testGetImplementation() {
        // Given
        RESTlib_IClientImpl implDigitary;
        Boolean hasError = false;

        Test.startTest();
        // When : running user is a digitary API user
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            ApplicationDocumentContentImplFactory factory = new ApplicationDocumentContentImplFactory();
            implDigitary = factory.getImplementation();
        }

        // When : no implementation for running user
        System.runAs(StudFirst_TestHelper.buildMinimalAccessApiUser()) {
            try {
                new ApplicationDocumentContentImplFactory().getImplementation();
            } catch (RESTlib_Ex.DeveloperException ex) {
                hasError = true;
            }
        }
        Test.stopTest();

        // Then : digitary specific implementation should be returned for digitary running user
        Assert.isTrue(implDigitary instanceof DigitaryApplicationDocContentImpl, 'Expected DigitaryApplicationDocContentImpl for digitary user');
        // Then : Throws an error when no implementation is found for non-persona specific running user
        Assert.isTrue(hasError, 'Expected an error to be thrown for non-persona specific user');
    }
}