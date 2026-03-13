@isTest
private class ASNController_Test {
    private final static String PERSON_ID = '12345678';
    private final static String COURSE_CODE = 'CODE01';

    @testSetup static void dataSetup() {

        // Disable some of the automation that occurs when contacts are created
        triggerCommon.disableTrigger('Contact');
        ucinn_ascendv2__Trigger_Handler__c disableEngageTrig = new ucinn_ascendv2__Trigger_Handler__c(ucinn_ascendv2__Object__c ='Contact',ucinn_ascendv2__Is_Active__c=False,ucinn_ascendv2__class__c='ascend_TRIG_Contact');
        insert disableEngageTrig;

        //create contact
        Contact con = TestHelper.createOrphanContactRecords(1)[0];
        con.LastName = 'ASNController';
        con.Person_ID_unique__c =PERSON_ID;
        con.SAP_Staff_Id__c = 'NoDupRules'; // this will filter the contact out of the most of the duplicate rules
        insert con;
        System.assertEquals(1, [SELECT COUNT() FROM Contact], 'An error occurred while creating setup Contact');

        String enchklbl = Label.ASN_Encumbrance_Check;
        List<String> effTypeList = new List<String>();
        if(String.isNotBlank(enchklbl))
        {
            effTypeList =  enchklbl.split(',');
        }
         // create an admin encumbrance
         Encumbrance__c enc = StudFirst_TestHelper.createEncumbranceAdmin(con.id);
         enc.eff_type__c = effTypeList[0];
         insert enc;

        //create course
        Course__c courseRec = TestHelper.createCoursesWithType(1, 'Course-All')[0];
        courseRec.Name = COURSE_CODE;
        insert courseRec;
        System.assertEquals(1, [SELECT COUNT() FROM Course__c], 'An error occurred while creating setup Course');

        //create course attempt
        Course_Attempt__c ca = TestHelper.createCourseAttempts(1, con.Id, courseRec.Id)[0];
        ca.Callista_External_Id__c = PERSON_ID + '_' + COURSE_CODE;
        insert ca;
        System.assertEquals(1, [SELECT COUNT() FROM Course_Attempt__c], 'An error occurred while creating setup Course Attempt');

        //create org unit
        Account ou = new Account(Callista_Org_Unit_Code__c = 'OrgUnitCode', name = 'Test Faculty', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId());
        insert ou;

        //create calendar
        Calendar__c cal = new Calendar__c(name='TestCalendar', sequence_number__c = 0001, Description__c = 'Hello',Type__c = '');
        insert cal;
        
        List<ASN_Teaching_Periods__mdt> mdt = [SELECT Teaching_Period__c,Academic_Year__c,Group_CI_Sequence_Numbers__c FROM ASN_Teaching_Periods__mdt WHERE Location__c = NULL];

        //create unit attempt for 'update' and 'delete' scenario
        Unit_Attempt__c ua = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
        ua.Unit_Code__c = 'ATS2560';
        ua.Academic_Year__c = '2018';
        ua.Unit_Mode__c = 'ON CAMPUS';
        ua.Calendar_Type__c = 'ADM-2';
        ua.CI_Sequence_Number__c = mdt[0].Group_CI_Sequence_Numbers__c.split(',')[0];
        ua.Teaching_Period__c = '2';
        ua.Student__c = con.Id;
        ua.Achieved_Credit_Points__c = 22;
        ua.Title__c = 'Nursing';
        ua.Grade__c = 'C';
        ua.ASN_Exclude__c = false;
        ua.Teaching_Calendar__c  = cal.Id;
     

        insert ua;
        System.assertEquals(1, [SELECT COUNT() FROM Unit_Attempt__c], 'An error occurred while creating setup Unit Attempt');
    }
    
    @isTest
    public static void testRetrieveTPAndUpdate()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact con = [Select Id,LastName,FirstName,Email from Contact where Person_ID_unique__c='12345678' and LastName = 'ASNController'];
        System.runAs(applicant)
        {
            List<TeachingPeriod> tpList = ASNController.retrieveStudentTeachingPeriods(con.Id);
            tpList[0].studentUpdated = true;
            System.assert( tpList.size()>0);
            
            Boolean isSuccess = ASNController.updateUnitAttempts(tpList[0], con);
            // System.assertEquals(true , isSuccess); 
         }

    }

    @isTest
    public static void testRetriveConAndEnc()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact con = [Select Id,LastName,FirstName,Email from Contact where Person_ID_unique__c='12345678' and LastName = 'ASNController'];
        System.runAs(applicant)
        {
            Contact retCon = ASNController.retrieveUserContact(applicant.Id);
            System.assert(retCon!=null);
            Boolean chkEnc = ASNController.checkEncumbrance(con.Id);
            System.assert(retCon!=null);
        }

    }
   
}