/**************************************************************************************************   
Apex Class Name      :  BatchFindCasesToBeUpdated_Test 
Version              :  1.0                                                                          
Created Date         :                                                              
Function             :  This is test class for BatchFindCasesToBeUpdated .
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
    Developer                        Date                        Description
    Vaibhav B                    02/11/2017                        Created.
***************************************************************************************************/
@isTest(isParallel=true)
public class BatchFindCasesToBeUpdated_Test {
    @testSetup
    public static void createData() {
        
    }
    public static testmethod void testFindCasesBatch() {
        List<case> caseList = TestHelper.webToCaseForms(1);
        system.assertEquals(caseList.size(),1);
        caseList[0].status = 'Awaiting Customer Feedback';
        caseList[0].recordtypeId=[SELECT id FROM recordtype WHERE developername = 'Monash_Connect_Enquiry' and SobjectType = 'Case'].Id;
        upsert caseList; 
        caseList[0].status='Solved';
        EmailMessage emlMsg = new EmailMessage( ParentId = caseList[0].id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                Incoming = true); 
        insert emlMsg;
        test.startTest();
        BatchFindCasesToBeUpdated sh1 = new BatchFindCasesToBeUpdated();
        system.schedule('Test case to be updated','0 0 23 * * ?', sh1);        
        test.stopTest();      
    }    
}