/**
 * @author Trent De Laney
 * @date 28 Nov 2019 at 2:59:54 pm
 * @group Test Class
 * @description Covers the ACP Request class which sends outbound communication to Callista. Needs to be called line by line for SF to pick up the line coverage
 * Shalini Mendu - 13/09/2020 - SFTG-2212 - Remove offerRound element from Outbound ACP payload

 */
@IsTest
public with sharing class ObdACPRequest_Test {

    @IsTest
    public static void test_AssignPropertyValues(){
        ObdACPRequest request = new ObdACPRequest();
        System.assert(request != null, 'Unable to create the ACP Request');

        //Variable assignment
        ObdACPRequest.Application app = request.getApplication();
        app.type = 'application';
        app.admissionApplNumber = 1;
        app.submittedDate = String.valueOf(Date.today());

        app.academicCiSequenceNumber = 8619;
        app.academicCalendarType = 'ACAD-YR';
        app.admissionCalendarType = 'ADM-WNTR';
        app.admissionCiSequenceNum = 8701;
        app.admissionCategory = 'PG-FEE';

        ObdACPRequest.CoursePreference pref = app.getCoursePreference();
        pref.type = 'coursePreference';
        pref.admissionCode = null;
        pref.basisForAdmissionType = '311';
        pref.courseCode = 'L6005';
        pref.transferCourseCode = null;
        pref.requestForAdvancedStandingIndicator = false;
        pref.recruitmentReferenceCode = null;
        pref.primaryNationalityCode = null;
        pref.submissionLocationCode = null;

        //Create a course preference instance
        ObdACPRequest.CoursePreferenceInstance preferenceInstance = new ObdACPRequest.CoursePreferenceInstance();
        preferenceInstance.unitSetCode = null;
        preferenceInstance.unitSetVersion = null;
        preferenceInstance.sequenceNumber = 1;
        preferenceInstance.preferenceNumber = 1;
        preferenceInstance.outcomeStatus = 'OFFER-COND';
        preferenceInstance.offerResponseStatus = 'PENDING';
        preferenceInstance.offerResponseDate = String.valueOf(Date.today());
        preferenceInstance.offerDate = String.valueOf(Date.today());
        preferenceInstance.offerCondition = 'No Condition';
        preferenceInstance.locationCode = 'MEL-LAWCHM';
        preferenceInstance.hecsPaymentOption = '302';
        preferenceInstance.fundingSource = null;
        preferenceInstance.feeCategory = 'AU_DOM_FF';
        preferenceInstance.entryQualificationStatus = 'QUALIFIED';
        preferenceInstance.enrolmentCategory = 'ALL-STEPS';
        preferenceInstance.documentationStatus = 'DOC-PEND';
        preferenceInstance.defermentStatus = 'NOT-APPLIC';
        preferenceInstance.deferredAdmissionCalendarType = 'ADM-1';
        preferenceInstance.deferredAdmissionCiSequenceNum = 12551;
        preferenceInstance.courseVersionNumber = 3;
        preferenceInstance.courseCode = 'L6005';
        preferenceInstance.correspondenceCategory = 'STANDARD';
        preferenceInstance.conditionalOfferStatus = 'PENDING';
        preferenceInstance.conditionalOfferSatisfiedDate = String.valueOf(Date.today());
        preferenceInstance.conditionalOfferMustBeSatisfiedIndicator = false;
        preferenceInstance.attendanceType = 'FT';
        preferenceInstance.attendanceMode = 'IN';
        preferenceInstance.applicantAcceptanceCondition = null;
        preferenceInstance.agreedStartDate = null;
        preferenceInstance.admissionOutcomeStatusReason = null;
        preferenceInstance.admissionOutcomeStatusAuthPersonId = null;
        preferenceInstance.admissionOutcomeStatusAuthDate = null;
        preferenceInstance.actualOfferResponseDate = null;

        preferenceInstance.precedents = new List<ObdACPRequest.PrecedentInfo>();

        //Create precedent
        ObdACPRequest.PrecedentInfo precedentInfo = new ObdACPRequest.PrecedentInfo();
        precedentInfo.precedentId = 1;
        precedentInfo.requirementSatisfiedCode = '111';
        preferenceInstance.precedents.add(precedentInfo);
    }
}