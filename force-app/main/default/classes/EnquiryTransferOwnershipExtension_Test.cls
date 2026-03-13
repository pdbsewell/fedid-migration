/**
 * @author          Kristian Vegerano
 * @description     Test class for EnquiryTransferOwnershipExtension - Extension for the page used by a quick action to transfer enquiry ownership
 */
@isTest(isParallel=true)
private class EnquiryTransferOwnershipExtension_Test {
    /**
     * @author          Kristian Vegerano
     * @description     Test setup method for setting up all necessary records for the test context
     */
    @testSetup
    static void setup() {
        
    }
    
    /**
     * @author          Kristian Vegerano
     * @description     Method for executing the page update button to transfer ownership
     */
    static testMethod void testTransferEnquiryOwnership(){
        //Initialize test variables
        //Retrieve Active assignment rule for cases
        AssignmentRule activeAssignmentRule = [SELECT Id, Name, SobjectType FROM AssignmentRule WHERE Active = true AND SobjectType = 'Case' LIMIT 1];
        Database.DMLOptions dmo = new Database.DMLOptions();
        //Use stated assignment rule if populated, use default if not
        dmo.assignmentRuleHeader.useDefaultRule = false;
        dmo.assignmentRuleHeader.assignmentRuleId = activeAssignmentRule.Id;
        
        //Create enquiry to use for testing
        Case testCase = new Case(Subject = 'TestSubject', Description = 'TestDescription');
        testCase.setOptions(dmo);
        insert testCase;
        
        //Setup Extension class variable
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        EnquiryTransferOwnershipExtension quickActionTransferOwnership = new EnquiryTransferOwnershipExtension(sc);
        
        //Setup test page
        PageReference pageRef = Page.EnquiryTransferOwnership;
        pageRef.getParameters().put('id', String.valueOf(testCase.Id));
        Test.setCurrentPage(pageRef);
        
        /* Test Assertions */
        //Verify that there were course records related to the enquiry
        System.assertEquals(null, testCase.OwnerId);
        
        //Start test context
        Test.startTest();
            //Change Owner
            quickActionTransferOwnership.transferEnquiry.OwnerId = UserInfo.getUserId();
            //Commit Update
            quickActionTransferOwnership.updateOwner();
        //Stop test context
        Test.stopTest();
        
        /* Test Assertions */
        //Verify that the enquiry owner has been updated to the current user
        System.assertEquals(UserInfo.getUserId(), [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id LIMIT 1].OwnerId);
    }
}