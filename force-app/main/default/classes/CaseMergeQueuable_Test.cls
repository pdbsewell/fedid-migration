/**
 * @description       : Test Class - SS-71 and SS-104 Case Merge
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 01-08-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest
public class CaseMergeQueuable_Test {
    @testSetup
    static void setup() {
        Contact oContact = new Contact();
        oContact.FirstName = 'Test'+CommonUtilityERDA.generateRandomString(5);
        oContact.LastName = 'MergeEnquiries'+CommonUtilityERDA.generateRandomString(5);
        oContact.Email = CommonUtilityERDA.generateRandomString(5) + 'merge@enquiries.edu';
        insert oContact;
        
		Case oCase1 = new Case ();
		oCase1.ContactId = oContact.Id;
        oCase1.Subject = 'ChildCase';
        oCase1.Description = 'MergeEnquiryTest - Question.'+CommonUtilityERDA.generateRandomString(5);
        insert oCase1;
    }
    
    /**
    * @description Testing Case Description Merge.
    * @author rajesh.punjabi@monash.edu | 22-06-2022 
    **/
    @isTest
    public static void caseMergeQueuableTest(){
        Case oCase1 = [SELECT Id,ParentId FROM Case WHERE Subject = 'ChildCase'];
                  
        Test.startTest();
        System.enqueueJob(new CaseMergeQueuable(new List<Case>{oCase1}));
        Test.stopTest();
        Case oChildCase = [SELECT Id, ParentId FROM Case WHERE Subject = 'ChildCase' LIMIT 1];
        System.assert(oChildCase !=null, 'Enquiries are merged.');
    }
}