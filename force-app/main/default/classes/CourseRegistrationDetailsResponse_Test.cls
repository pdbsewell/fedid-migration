/**
 * @author Nadula Karunaratna
 * @date 14-01-2020
 * @group Professional Development
 * @description Test class for CourseRegistrationDetailsResponse
 */

@isTest(isParallel=true)
private class CourseRegistrationDetailsResponse_Test {
    @isTest static void CourseInfoTest() {

        CourseRegistrationDetailsResponse crdr = new CourseRegistrationDetailsResponse();
        crdr.courseInfo = new CourseRegistrationDetailsResponse.CourseInfo();
        
        crdr.courseInfo.courseCode = 'PDD1001';
        crdr.courseInfo.courseName = 'PD Education Test Course';
        crdr.courseInfo.glAccount = 'ABC123';
        crdr.courseInfo.costCenter = 'XYZ456';
        crdr.courseInfo.fund = 'PQR789';
        crdr.courseInfo.startDate = '20-02-2020';
        crdr.courseInfo.location = 'Clayton';
        crdr.courseInfo.price = 500.00;
        crdr.courseInfo.quantity = 1.00;
        crdr.courseInfo.paymentId = '1234567890A';
        crdr.courseInfo.bookingId = '0987654321B';
        crdr.courseInfo.courseTaxType = true;
        crdr.courseInfo.vendorId = 12345;

        String testValue1 = 'PDD1001';
        System.assertEquals(testValue1, crdr.courseInfo.courseCode, 'Value Failed testValue');

    }

    @isTest static void CandidateInfo() {

        CourseRegistrationDetailsResponse crdr2 = new CourseRegistrationDetailsResponse();
        crdr2.CandidateInfo = new CourseRegistrationDetailsResponse.CandidateInfo();

        crdr2.CandidateInfo.firstName = 'Test';
        crdr2.CandidateInfo.lastName = 'User';
        crdr2.CandidateInfo.email = 'test@mailinator.com';
        crdr2.CandidateInfo.homePhone = '0312345678';
        crdr2.CandidateInfo.workPhone = '0387654321';
        crdr2.CandidateInfo.mobile = '041234567890';
        crdr2.CandidateInfo.companyName = 'Mario Brothers';
        crdr2.CandidateInfo.streetAddress = '100 High Street';
        crdr2.CandidateInfo.suburb = 'Clayton';
        crdr2.CandidateInfo.postCode = '3000';
        crdr2.CandidateInfo.state = 'VIC';
        crdr2.CandidateInfo.country = 'Australia';

        String testValue2 = 'test@mailinator.com';
        System.assertEquals(testValue2, crdr2.CandidateInfo.email, 'Value Failed testValue');

    }

}