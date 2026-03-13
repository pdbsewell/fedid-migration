@isTest
private class TeachingPeriod_Test {
    private final static String PERSON_ID = '12345678';
    private final static String COURSE_CODE = 'CODE01';
    
    @testSetup static void dataSetup() {

        // Disable some of the automation that occurs when contacts are created
        triggerCommon.disableTrigger('Contact');
        ucinn_ascendv2__Trigger_Handler__c disableEngageTrig = new ucinn_ascendv2__Trigger_Handler__c(ucinn_ascendv2__Object__c ='Contact',ucinn_ascendv2__Is_Active__c=False,ucinn_ascendv2__class__c='ascend_TRIG_Contact');
        insert disableEngageTrig;

        //create contact
        Contact con = TestHelper.createOrphanContactRecords(1)[0];
        con.LastName = 'TeachingPeriod';
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
        Calendar__c cal = new Calendar__c(name='TeachingPeriodCalendar', sequence_number__c = 0001, Description__c = 'Hello',Type__c = '');
		insert cal;
        
	
    }
    @isTest
    public static void testRetrieveTPUserFlow2()
    {
        List<ASN_Teaching_Periods__mdt> mdt = [SELECT Teaching_Period__c,Academic_Year__c,Group_CI_Sequence_Numbers__c FROM ASN_Teaching_Periods__mdt WHERE Location__c = NULL];
        Course_Attempt__c ca = [Select id from Course_Attempt__c limit 1];
        Contact con = [Select Id,LastName,FirstName,Email from Contact where Person_ID_unique__c='12345678' and LastName = 'TeachingPeriod'];

        Calendar__c cal = [Select id from Calendar__C where name ='TeachingPeriodCalendar'];
        Unit_Attempt__c ua1 = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
        List<Unit_Attempt__c> uaList = new List<Unit_Attempt__c>();

		ua1.Unit_Code__c = 'ATS2561';
        ua1.Academic_Year__c = '2020';
        ua1.Unit_Mode__c = 'ON CAMPUS';
		ua1.Calendar_Type__c = 'ADM-2';
        ua1.CI_Sequence_Number__c = mdt[0].Group_CI_Sequence_Numbers__c.split(',')[0];
        ua1.Teaching_Period__c = '2';
        ua1.Student__c = con.Id;
        ua1.Achieved_Credit_Points__c = 22;
        ua1.Title__c = 'Economy';
        ua1.Grade__c = 'N';
        ua1.Teaching_Calendar__c  = cal.Id;

        uaList.add(ua1);
        insert uaList;
        User applicant = StudFirst_TestHelper.createCommunityUser();
        System.runAs(applicant)
        {
            List<TeachingPeriod> tpList = ASNController.retrieveStudentTeachingPeriods(con.Id);
            System.assert( tpList.size()>0);
            System.assertEquals(tpList[0].userFlowNumber, 'UserFlow2');
        }
    }

    @isTest
    public static void testRetrieveTPUserFlow3()
    {
        List<ASN_Teaching_Periods__mdt> mdt = [SELECT Teaching_Period__c,Academic_Year__c,Group_CI_Sequence_Numbers__c FROM ASN_Teaching_Periods__mdt WHERE Location__c = NULL];
        Course_Attempt__c ca = [Select id from Course_Attempt__c limit 1];
        Contact con = [Select Id,LastName,FirstName,Email from Contact where Person_ID_unique__c='12345678' and LastName = 'TeachingPeriod'];
        Calendar__c cal = [Select id from Calendar__C where name ='TeachingPeriodCalendar'];
        List<Unit_Attempt__c> uaList = new List<Unit_Attempt__c>();
        Unit_Attempt__c ua1 = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
		ua1.Unit_Code__c = 'ATS2561';
        ua1.Academic_Year__c = '2020';
        ua1.Unit_Mode__c = 'ON CAMPUS';
		ua1.Calendar_Type__c = 'ADM-2';
        ua1.CI_Sequence_Number__c = mdt[0].Group_CI_Sequence_Numbers__c.split(',')[0];
        ua1.Teaching_Period__c = '2';
        ua1.Student__c = con.Id;
        ua1.Achieved_Credit_Points__c = 22;
        ua1.Title__c = 'Economy';
        ua1.Grade__c = 'WH';
        ua1.Teaching_Calendar__c  = cal.Id;

        uaList.add(ua1);

        insert uaList;
        User applicant = StudFirst_TestHelper.createCommunityUser();
        System.runAs(applicant)
        {
            List<TeachingPeriod> tpList = ASNController.retrieveStudentTeachingPeriods(con.Id);
            System.assert( tpList.size()>0);
            System.assertEquals(tpList[0].userFlowNumber, 'UserFlow3');
        }
    }

    
    
    @isTest
    public static void testRetrieveTPUserFlow4()
    {
        List<ASN_Teaching_Periods__mdt> mdt = [SELECT Teaching_Period__c,Academic_Year__c,Group_CI_Sequence_Numbers__c FROM ASN_Teaching_Periods__mdt WHERE Location__c = NULL];
        Course_Attempt__c ca = [Select id from Course_Attempt__c limit 1];
        Contact con = [Select Id,LastName,FirstName,Email from Contact where Person_ID_unique__c='12345678' and LastName = 'TeachingPeriod'];
        Calendar__c cal = [Select id from Calendar__C where name ='TeachingPeriodCalendar'];
        List<Unit_Attempt__c> uaList = new List<Unit_Attempt__c>();

        Unit_Attempt__c ua1 = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
		ua1.Unit_Code__c = 'ATS2561';
        ua1.Academic_Year__c = '2020';
        ua1.Unit_Mode__c = 'ON CAMPUS';
		ua1.Calendar_Type__c = 'ADM-2';
        ua1.CI_Sequence_Number__c = mdt[0].Group_CI_Sequence_Numbers__c.split(',')[0];
        ua1.Teaching_Period__c = '2';
        ua1.Student__c = con.Id;
        ua1.Achieved_Credit_Points__c = 22;
        ua1.Title__c = 'Economy';
        ua1.Grade__c = 'C';
        ua1.Teaching_Calendar__c  = cal.Id;
        ua1.ASN_Response_Date__c = Date.today();
        ua1.ASN_Response__c = 'SFR';
        uaList.add(ua1);

        insert uaList;
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        System.runAs(applicant)
        {
            List<TeachingPeriod> tpList = ASNController.retrieveStudentTeachingPeriods(con.Id);
            System.assert( tpList.size()>0);
            System.assertEquals(tpList[0].userFlowNumber, 'UserFlow4');
        }
    }

    @isTest
    public static void testRetrieveTPUserFlow1()
    {
        List<ASN_Teaching_Periods__mdt> mdt = [SELECT Teaching_Period__c,Academic_Year__c,Group_CI_Sequence_Numbers__c FROM ASN_Teaching_Periods__mdt WHERE Location__c = NULL];
        Course_Attempt__c ca = [Select id from Course_Attempt__c limit 1];
        Contact con = [Select Id,LastName,FirstName,Email from Contact where Person_ID_unique__c='12345678' and LastName = 'TeachingPeriod'];

        Calendar__c cal = [Select id from Calendar__C where name ='TeachingPeriodCalendar'];
        List<Unit_Attempt__c> uaList = new List<Unit_Attempt__c>();


        Unit_Attempt__c ua1 = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
		ua1.Unit_Code__c = 'ATS2561';
        ua1.Academic_Year__c = '2020';
        ua1.Unit_Mode__c = 'ON CAMPUS';
		ua1.Calendar_Type__c = 'ADM-2';
        ua1.CI_Sequence_Number__c = mdt[0].Group_CI_Sequence_Numbers__c.split(',')[0];
        ua1.Teaching_Period__c = '2';
        ua1.Student__c = con.Id;
        ua1.Achieved_Credit_Points__c = 22;
        ua1.Title__c = 'Economy';
        ua1.Grade__c = 'C';
        ua1.Teaching_Calendar__c  = cal.Id;
      
        uaList.add(ua1);

        insert uaList;
        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        System.runAs(applicant)
        {
            List<TeachingPeriod> tpList = ASNController.retrieveStudentTeachingPeriods(con.Id);
            System.assert( tpList.size()>0);
            System.assertEquals(tpList[0].userFlowNumber, 'UserFlow1');
        }
    }

    @isTest
    public static void testTeachingPeriod()
    {
        TeachingPeriod tp = new TeachingPeriod();
        System.assertEquals(tp.hasPassedRecords, false);
    }

    @isTest
    public static void testRetrieveTPUserFlow6() {
        List<ASN_Teaching_Periods__mdt> mdt = [SELECT Teaching_Period__c,Academic_Year__c,Group_CI_Sequence_Numbers__c FROM ASN_Teaching_Periods__mdt WHERE Location__c = NULL];

        // GIVEN A STUDENT
        Contact con = [Select Id,LastName,FirstName,Email from Contact where Person_ID_unique__c='12345678' and LastName = 'TeachingPeriod'];
        // IS ENROLLED IN A TEACHING CALENDAR
        Calendar__c cal = [Select id from Calendar__C where name ='TeachingPeriodCalendar'];

        // WITH A ONE-YEAR HONOURS COURSE
        Course__c testCourse = new Course__c();
        testCourse.Name = 'E007';
        testCourse.Sub_Level__c = '09-1';
        testCourse.Type__c = 'Course-All';
        insert testCourse;

        // WITH A COMPLETED ATTEMPT
        Course_Attempt__c testAttempt = new Course_Attempt__c();
        testAttempt.Course__c = testCourse.Id;
        testAttempt.Course_Attempt_Status__c = 'Completed';
        testAttempt.Contact__c = con.Id;
        testAttempt.Name = con.Id+'/'+testCourse.Name;
        insert testAttempt;

        // WITH ONE SUBJECT
        List<Unit_Attempt__c> uaList = new List<Unit_Attempt__c>();
        Unit_Attempt__c ua1 = TestHelper.createUnitAttempts(1, testAttempt.Id, con.Id)[0];
        ua1.Course_Attempt__c = testAttempt.Id;
        ua1.Unit_Code__c = 'ATS2561';
        ua1.Academic_Year__c = '2020';
        ua1.Unit_Mode__c = 'ON CAMPUS';
        ua1.Calendar_Type__c = 'ADM-2';
        ua1.CI_Sequence_Number__c = mdt[0].Group_CI_Sequence_Numbers__c.split(',')[0];
        ua1.Teaching_Period__c = '2';
        ua1.Student__c = con.Id;
        ua1.Achieved_Credit_Points__c = 22;
        ua1.Title__c = 'Economy';
        ua1.Grade__c = 'C';
        ua1.Teaching_Calendar__c  = cal.Id;
        uaList.add(ua1);
        insert uaList;

        // WHEN THE STUDENT LOGS INTO THE COMMUNITY ASK.MONASH UPDATE-RESULTS PAGE
        User applicant = StudFirst_TestHelper.createCommunityUser();

        List<TeachingPeriod> teachingPeriodResult;
        System.runAs(applicant){
            teachingPeriodResult = ASNController.retrieveStudentTeachingPeriods(con.Id);
        }

        // THEN THE STUDENT MUST BE REDIRECTED TO FLOW 6 - ONE YEAR COURSE
        System.assert(!teachingPeriodResult.isEmpty());
        System.assertEquals(teachingPeriodResult[0].userFlowNumber, 'UserFlow6');
    }
}