/**
 * @description Test class for the QFlowContact_CC class
 */
@isTest(isParallel=true)
private class QFlowContact_CC_Test {

    static testMethod void checkContactMatch(){
        
        Contact testContact = TestHelper.createStudentContacts(1, null)[0];
        testContact.Person_ID_Unique__c = '12345';
        insert testContact;
        
        Test.setCurrentPage(Page.Redirect_To_New_Case);
        ApexPages.currentPage().getParameters().put('StudentId', '12345');
        
        QFlowContact_CC con = new QFlowContact_CC();
        system.assert( con.cid != '',' Contact record was matched as expected');
        
        
        Test.setCurrentPage(Page.Redirect_To_New_Case); // reset params
        ApexPages.currentPage().getParameters().put('StudentId', '123');
        
        con = new QFlowContact_CC();
        system.assert( con.cid == '',' Contact record was not matched as expected');
        
    }     
    
}