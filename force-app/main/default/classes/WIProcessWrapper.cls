/**
 * @description       : Wrapper Class for WI Process Data Items
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @last modified on  : 2021-01-21
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-01-21 - Angelo Rivera - Initial Creation
**/

public class WIProcessWrapper{

    public ItemData itemData;

    public class ItemData {
        public String Name;
        public SpecificContent SpecificContent;
        public String Reference;
    }

    public class SpecificContent {
        public String personID;
        public String academicPeriod;
        public String teachingPeriod;
        public String unitCode;
        public String courseCode;
        public String uniCRMCaseID;

        public SpecificContent(String pID, String acadPeriod, String teachPeriod, String uCode, String crsCode, String caseId) {
            personID = pID;
            academicPeriod = acadPeriod;
            teachingPeriod = teachPeriod;
            unitCode = uCode;
            courseCode = crsCode;
            uniCRMCaseID = caseId;
        }

    }
}