/*******************************************************************************
* @author       Ant Custodio
* @date         24.May.2017        
* @description  test class for applicationHomeCC
* @revision     
*******************************************************************************/
@isTest(isParallel=true)
public class applicationHomeCC_Test {
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017        
    * @description  test the application redirection functionality
    * @revision     
    *******************************************************************************/
    static testMethod void test_redirection_FirstTimeLogin() {
        
        //create a community user
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();
        System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');
        test.startTest();
        //only run if there is a Domestic Applicant Profile User
        if (communityUserRec != null) {
            System.runAs(communityUserRec) {

                //user logs in on the community
                applicationHomeCC ctrl = new applicationHomeCC();
                PageReference pageRef = ctrl.redirectToCorrectPage();
                //users should be redirected to My Details if the DOB is blank
                System.assertNotEquals(null, pageRef, 'Redirected to invalid page');
            }
        }
        test.stopTest();
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         24.May.2017        
    * @description  test the application redirection functionality
    * @revision     
    *******************************************************************************/
    static testMethod void test_redirection_Regular() {
        
        //create a community user
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();
        System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');
        
        //only run if there is a Domestic Applicant Profile User
        if (communityUserRec != null) {
            System.runAs(communityUserRec) {
                test.startTest();
                
                //update details on the portal
                communityUserRec.App_Birthdate__c = date.today().addYears(-20);
                update communityUserRec;
                
                // forces queueable to execute
                test.stopTest(); 
                //make sure the trigger fired for the user 
                Contact contactRec = [SELECT Id, Birthdate FROM Contact WHERE Id =: communityUserRec.ContactId];
                
                // Removed assert as personal details are no longer copied from User to Contact
                // System.assertEquals(date.today().addYears(-20), contactRec.Birthdate, 'The UserServices trigger did not fire the updateAssociatedContact() method');
                
                //user logs in on the community
                applicationHomeCC ctrl = new applicationHomeCC();
                PageReference pageRef = ctrl.redirectToCorrectPage();
                //users should be redirected to Homepage if the DOB has a value
                System.assertNotEquals(null, pageRef, 'Redirected to invalid page');
            }
            
        }
        
    }
}