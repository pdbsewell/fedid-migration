/*
 * @author			ayush.agrawal@monash.edu
 * @group			Student Administration
 */
@isTest(isParallel=true)
public class CopyToClipboardController_Test {
    
	/*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			16-04-2021
	 */
    @isTest
    static void testGetRecordDetails() {
        // Case
        Case case_1 = new Case();
        case_1.Origin = 'Web - Monash Forms';
        insert case_1;
        
        // Case Unit Attempt
        Case_Unit_Attempt__c caseUnitAttempt_1 = new Case_Unit_Attempt__c();
        caseUnitAttempt_1.Assessment_Name__c = 'Assessment Name';
        caseUnitAttempt_1.Assessment_Type__c = 'Assessment Type';
        caseUnitAttempt_1.Assessment_Due_Date_New__c = Date.Today();
        caseUnitAttempt_1.Assessment_Due_Date_Effective__c = Date.Today();
        caseUnitAttempt_1.Enquiry__c = case_1.Id;
        insert caseUnitAttempt_1;
        
        Test.startTest();
        
        String jsonString = CopyToClipboardController.getRecordDetails(caseUnitAttempt_1.Id);
        
        Test.stopTest();
        
        Case_Unit_Attempt__c cuaToAssert = (Case_Unit_Attempt__c) JSON.deserialize(jsonString, Case_Unit_Attempt__c.class);
        
        System.assertEquals('Assessment Name', cuaToAssert.Assessment_Name__c, 'testGetRecordDetails is not working.');
        System.assertEquals('Assessment Type', cuaToAssert.Assessment_Type__c, 'testGetRecordDetails is not working.');
    }
    
}