/**
 * @author Nick Guia
 * @date 30-09-2020
 * @group Common
 * @description test class for DuplicateContact 
 **/
@isTest(isParallel=true)
private class DuplicateContact_Test {
    
    @isTest
    static void shouldReturnHasDuplicates() {
        //given
        DuplicateContact dupCon;

        Test.startTest();
        
        //when
        dupCon = new DuplicateContact();
        dupCon.matchedContactRecords.add(
            new Contact(
                FirstName = 'Test', 
                LastName = 'test', 
                Email = 'test@test.org')
        );

        Test.stopTest();

        //then
        System.assert(dupCon.hasDuplicates(), 'Unable to detect matched contact records!');
    }
}