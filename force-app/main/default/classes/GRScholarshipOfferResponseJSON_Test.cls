/**
 * @author       : Sachin Shetty
 * @date         : 17-08-2025
 * @group        : Test Class
 * @description  : Test Class for GRScholarshipOfferResponseJSON
 * @revision
 * 		17-08-2025	Sachin Shetty	Created
**/
@IsTest(isParallel=true)
public class GRScholarshipOfferResponseJSON_Test {
    @IsTest
    static void testDefaultConstructorsAndAssignments_GivenWhenThen() {
        // GIVEN - A fresh GRScholarshipOfferResponseJSON structure with nested details
        GRScholarshipOfferResponseJSON response = new GRScholarshipOfferResponseJSON();
        response.scholarship = new GRScholarshipOfferResponseJSON.Scholarship();
        response.scholarship.offerStatus = 'OFFERED';
        response.scholarship.responseStatus = 'ACCEPTED';
        response.scholarship.continueCandidatureWithoutScholarshipFlag = true;
        response.scholarship.responseReason = 'No reason';

        response.scholarship.applicationDetails = new GRScholarshipOfferResponseJSON.ApplicationDetails();
        response.scholarship.applicationDetails.applicant = new GRScholarshipOfferResponseJSON.Applicant();
        response.scholarship.applicationDetails.applicant.smsContactId = '2454220';

        response.scholarship.applicationDetails.application = new GRScholarshipOfferResponseJSON.Application();
        response.scholarship.applicationDetails.application.hdrApplicationDetails = 
            new GRScholarshipOfferResponseJSON.HdrApplicationDetails();
        response.scholarship.applicationDetails.application.hdrApplicationDetails.hdrApplicationNumber = '5239170';

        // WHEN - We access values from the nested object
        String offerStatus = response.scholarship.offerStatus;
        String smsContactId = response.scholarship.applicationDetails.applicant.smsContactId;
        String hdrAppNumber = response.scholarship.applicationDetails.application.hdrApplicationDetails.hdrApplicationNumber;

        // THEN - The values should match what was set
        Assert.areEqual('OFFERED', offerStatus, 'Offer Status should be OFFERED');
        Assert.areEqual('ACCEPTED', response.scholarship.responseStatus, 'Response Status should be ACCEPTED');
        Assert.areEqual(true, response.scholarship.continueCandidatureWithoutScholarshipFlag, 'Flag should be true');
        Assert.areEqual('No reason', response.scholarship.responseReason, 'Response reason should match');
        Assert.areEqual('2454220', smsContactId, 'Applicant contact id should match');
        Assert.areEqual('5239170', hdrAppNumber, 'HDR application number should match');
    }
}