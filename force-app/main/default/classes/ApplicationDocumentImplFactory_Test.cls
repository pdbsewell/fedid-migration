/**
 * @description Covers the ApplicationDocumentImplFactory class
 * @author      Kai-Fan Hsieh
 * @since       26 June 2024
 */
@isTest(isParallel=true)
private class ApplicationDocumentImplFactory_Test {
    /**
     * @description Tests the getImplementation method of the ApplicationDocumentImplFactory class.
     * This test verifies that the correct implementation of RESTlib_IClientImpl is returned
     * based on the user's persona. Specifically, it checks that a DigitaryApplicationDocumentImpl
     * is returned for Digitary users and a BaseApplicationDocumentImpl is returned for users
     * without specific PSG assignments.
     */
    @isTest
    private static void test_GetImplementation() {
        // Given
        RESTlib_IClientImpl implBase;
        RESTlib_IClientImpl implDigitary;

        Test.startTest();
        // When : running user is a digitary API user
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            ApplicationDocumentImplFactory factory = new ApplicationDocumentImplFactory();
            implDigitary = factory.getImplementation();
        }

        // When : running user does not have any PSG assigned
        System.runAs(StudFirst_TestHelper.buildMinimalAccessApiUser()) {
            ApplicationDocumentImplFactory factory = new ApplicationDocumentImplFactory();
            implBase = factory.getImplementation();
        }

        Test.stopTest();

        // Then : digitary specific implementation should be returned for digitary running user
        Assert.isTrue(implDigitary instanceof DigitaryApplicationDocumentImpl, 'Expected DigitaryApplicationDocumentImpl for digitary user');
        // Then : base implementation should be returned for non-persona specific running user
        Assert.isTrue(implBase instanceof BaseApplicationDocumentImpl, 'Expected BaseApplicationDocumentImpl for non-persona specific user');
    }
}