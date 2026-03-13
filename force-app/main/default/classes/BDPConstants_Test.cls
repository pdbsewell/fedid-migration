/**
 * @author      Jasmin Joy Rudio
 * @description Test class for BDPConstants class
 * @group       Bulk Data Processing 
 * @revision    07/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class BDPConstants_Test {
    @isTest
    private static void testBDPConstants(){
        BDPConstants constants = new BDPConstants();
        System.assertEquals(BDPConstants.COURSE_TRANSFER_TYPE, 'Course Transfer');
        System.assertEquals(BDPConstants.CAMPUS_TRANSFER_TYPE, 'Campus Transfer');
        System.assertEquals(BDPConstants.CC_TRANSFER_RECORDTYPE, 'CC_Transfer');
        System.assertEquals(BDPConstants.READY_STATUS, 'Ready for Offer');
        System.assertEquals(BDPConstants.AUSTRALIA_CALLISTA_CODE, '1101');
        System.assertEquals(BDPConstants.VICTORIA_CALLISTA_CODE, '3000');
        System.assertEquals(BDPConstants.CALENDAR_CATEGORY, 'ADMISSION');
        System.assertEquals(BDPConstants.DEFAULT_CITIZENSHIP, 'INTRNTNL');
        System.assertEquals(BDPConstants.REVIEW_REQUIRED , 'Review Required');
        System.assertEquals(BDPConstants.BDP_NEW , 'New');
        System.assertEquals(BDPConstants.COURSE_ATTEMPT_NOT_FOUND_MSG , 'Unable to find a matching Current Course Attempt record. Please check the data in the spreadsheet, delete this record and re-upload the spreadsheet, or manually update the BDP record.');
        System.assertEquals(BDPConstants.ACP_NOT_FOUND_MSG , 'Unable to find a matching current ACP record. Please check the data in the spreadsheet, delete this record and re-upload the spreadsheet, or manually update the BDP record.');
        System.assertEquals(BDPConstants.CO_NOT_FOUND_MSG , 'Unable to find a matching Transfer Course Offering record. Please check the data in the spreadsheet, delete this record and re-upload the spreadsheet, or manually update the BDP record.');
        System.assertEquals(BDPConstants.MULTI_CO_FOUND_MSG , 'Multiple matching Course Offering records found. Please go to Suggested Course Offerings related list and mark the matching one as primary to continue.');
        System.assertEquals(BDPConstants.STUDENT_NOT_FOUND , 'Unable to find an applicant with the same person ID in Salesforce.');
        System.assertEquals(BDPConstants.CALENDAR_NOT_FOUND , 'Unable to find a calendar with the same calendar alternate name in Salesforce.');
    }
}