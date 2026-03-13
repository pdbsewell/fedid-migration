/**
* @author Trent De Laney
* @date 2019 
* @group Test Class
* @description Check the Citizenship options available for a community user
*/
@isTest(isParallel=true)
public class CitizenshipController_Test {
	static testMethod void test_retrieveApplicantCitizenship()
    {
        User communityUserRec = StudFirst_TestHelper.createContactAndCommunityUser();
		System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');

		if (communityUserRec != null) {
			System.runAs(communityUserRec) {
                String citizenshipTypeCode = CitizenshipController.retrieveApplicantCitizenship();
        		System.assertEquals('INT-TEP', citizenshipTypeCode, 'Citizenship Type code is not valid');
			}
		}
    }
}