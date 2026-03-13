/*******************************************************************************
* @author		Suman Gunaganti
* @date         18.Dec.2019        
* @description  test class for StudFirst_Utilities
* @group        Test class
* @revision     
*******************************************************************************/
@isTest(isParallel=true)
private class StudFirst_Utilities_Test {
    @isTest
    static void test_convertTo7BitAcceptedString() {
        string convertedstring = StudFirst_Utilities.convertTo7BitAcceptedString('string to be replaced','r');
        system.assert(convertedstring == 'string to be replaced', 'ERROR# converted string should match the original string');
    }
}