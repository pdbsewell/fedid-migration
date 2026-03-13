/**
 * @description       : Test class for EmailComparable
 * @author            : Nick Guia
 * @last modified on  : 11-09-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class EmailComparable_Test {
    
    /**
     * @description instantiate EmailComparable class
     */
    @isTest
    static void shouldInstantiate() {

        // GIVEN
        EmailComparable emailComp;
        
        Test.startTest();

        // WHEN
        emailComp = new EmailComparable(new Email__c());

        Test.stopTest();

        // THEN
        Assert.isNotNull(emailComp, 'Unable to instantiate EmailComparable');
    }
}