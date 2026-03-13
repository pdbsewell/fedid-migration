/**
 * @description       : Wrapper Class for Change Of Residency Data Items
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @last modified on  : 2021-03-10
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-03-10 - Angelo Rivera - Initial Creation
**/

public with sharing class ChangeOfResidencyWrapper {

    public ItemData itemData;

    public class ItemData {
        public String Name;
        public SpecificContent SpecificContent;
        public String Reference;
    }

    public class SpecificContent {
        public String personID;
        public String courseCode;
        public String locationCode;
        public String startDate;
        public String endDate;
        public String postCode;
        public String dateOfResidency;
        public String uniCRMCaseID;
        public String subclassOfTheVisa;
        public String studentStatus;
        public String facultyManagerName;
        public String monashConnectOfficerName;

        public SpecificContent(String pID, String crsCode, String locCode, String sDate, String eDate, String pCode,
                                String dtResidency, String caseId, String visa, String studentStat, String faculty, String officer) {
            personID = pID;
            courseCode = crsCode;
            locationCode = locCode;
            startDate = sDate;
            endDate = eDate;
            postCode = pCode;
            dateOfResidency = dtResidency;
            uniCRMCaseID = caseId;
            subclassOfTheVisa = visa;
            studentStatus = studentStat;
            facultyManagerName = faculty;
            monashConnectOfficerName = officer;
        }
    }

}