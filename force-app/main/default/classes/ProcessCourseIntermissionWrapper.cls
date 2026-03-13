/**
 * @description       : Wrapper Class for Process Course Intermission Data Items
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @last modified on  : 2021-05-05
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-05-05 - Angelo Rivera - Initial Creation
 * 1.1   2021-06-24 - Inderpal Dhanoa - Add Risk Category, caseNumber to payload
**/

public with sharing class ProcessCourseIntermissionWrapper {

    public ItemData itemData;

    public class ItemData {
        public String Name;
        public SpecificContent SpecificContent;
        public String Reference;
    }

    public class SpecificContent {
        public String uniCRMCaseID;
        public String personID;
        public String courseCode;
        public String startDate;
        public String endDate;
        public Boolean isESOS;
        public String enrolmentExceptionsLine;
        public String monashConnectOfficerName;
        public String reason;
        public String caseNumber;

        public SpecificContent(String pID, String crsCode,  String sDate, String eDate, Boolean bEsos,
                                                    String caseId,  String strExceptions, String officer, String secondaryReason, String sCaseNumber) {
            uniCRMCaseID = caseId;
            personID = pID;
            courseCode = crsCode;
            startDate = sDate;
            endDate = eDate;
            isESOS = bEsos;
            enrolmentExceptionsLine = strExceptions;
            monashConnectOfficerName = officer;
            reason = secondaryReason;
            caseNumber = sCaseNumber;
        }
    }
}