/**
 * @author Nick Guia
 * @description Test class for UnitAttemptServices
 * @revision
 * 	DEC.06.2018 	Nick Guia 	- Initial version
 */
@isTest(isParallel=true)
private class UnitAttemptServices_Test {

	private final static String PERSON_ID = '12345678';
	private final static String COURSE_CODE = 'CODE01';
	private final static Integer MAX_SETUP_RECORDS = 1; //max number for bulk test
	private final static Integer MAX_BULK_TEST = 200; //max number for bulk test

	@testSetup
	static void setup() {
		//create contact
		Contact con = TestHelper.createOrphanContactRecords(MAX_SETUP_RECORDS)[0];
		con.Person_ID_unique__c = PERSON_ID;
		insert con;
		Assert.areEqual(MAX_SETUP_RECORDS, [SELECT COUNT() FROM Contact], 'An error occurred while creating setup Contact');

		//create course
		Course__c courseRec = TestHelper.createCoursesWithType(MAX_SETUP_RECORDS, 'Course-All')[0];
		courseRec.Name = COURSE_CODE;
		insert courseRec;
		Assert.areEqual(MAX_SETUP_RECORDS, [SELECT COUNT() FROM Course__c], 'An error occurred while creating setup Course');

		//create course attempt
		Course_Attempt__c ca = TestHelper.createCourseAttempts(MAX_SETUP_RECORDS, con.Id, courseRec.Id)[0];
		//set external id
		ca.Callista_External_Id__c = PERSON_ID + '_' + COURSE_CODE;
		insert ca;
		Assert.areEqual(MAX_SETUP_RECORDS, [SELECT COUNT() FROM Course_Attempt__c], 'An error occurred while creating setup Course Attempt');      
        
        Unit_Offering__c uo = new Unit_Offering__c(Academic_Year__c = '2021'
                                                  , Active_Ind__c = true
                                                  , Location__c = 'Clayton'
                                                  , Unit_Version__c = '1'
                                                  , Unit_Code__c = 'UnitXYZ'
                                                  , Calendar_Type__c = 'S0-1' 
                                                  , Teaching_Period__c = 'S0-1'
                                                  , CI_Sequence_Number__c = '10001'
                                                  , Unit_Class__c = 'ON-CAMPUS');
		
        insert uo;
	}

	/**
	 * Test Scenario:
     *  Insert new Unit Attempt. Name should be pre-populated with format as follows:
     *  PERSON_ID/COURSE_CD/UNIT_CD/CAL_TYPE/ACADEMIC_YEAR
	 */
	@isTest
	static void test_populateUnitAttemptName() {
		Contact con = [SELECT Id FROM Contact LIMIT 1];
		Course_Attempt__c ca = [SELECT Id FROM Course_Attempt__c LIMIT 1];

		//create test unit attempt
		Unit_Attempt__c ua = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
		
		Test.startTest();
		insert ua;
		Test.stopTest();

        ua = [SELECT Id, Name, Student_Person_ID__c, Course_Code__c, Unit_Code__c, Teaching_Period__c, Academic_Year__c, deleted_in_source__c
                FROM Unit_Attempt__c
                WHERE Id = :ua.Id
                LIMIT 1];
        
        String uniqueName = UnitAttemptServices.getUniqueName(ua);
        Assert.areEqual(uniqueName, ua.Name);
	}

    /**
     * Test Scenario:
     *  Insert new Unit Attempt. SUA_External_ID__c should be pre-populated with format as follows:
     *  PERSON_ID-COURSE_CD-UNIT_CD-CAL_TYPE-CI_SEQUENCE_NUMBER
     */
    @isTest
    static void test_populateUnitAttemptExt() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Course_Attempt__c ca = [SELECT Id FROM Course_Attempt__c LIMIT 1];

        //create test unit attempt
        Unit_Attempt__c ua = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
        
        Test.startTest();
            insert ua;
        Test.stopTest();

        ua = [SELECT Id, Student_Person_ID__c, Course_Code__c, Unit_Code__c, 
                Calendar_Type__c, CI_Sequence_Number__c, SUA_External_ID__c
                FROM Unit_Attempt__c
                WHERE Id = :ua.Id
                LIMIT 1];
        String uniqueExt = UnitAttemptServices.getUniqueExt(ua);
        Assert.areEqual(uniqueExt, ua.SUA_External_ID__c);
    }

    /**
     * Test Scenario:
     *  getUniqueName() method should return the following name format:
     *  PERSON_ID/COURSE_CD/UNIT_CD/CAL_TYPE/ACADEMIC_YEAR
     */
    @isTest
    static void test_getUniqueName() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Course_Attempt__c ca = [SELECT Id FROM Course_Attempt__c LIMIT 1];

        //create test unit attempt
        Unit_Attempt__c ua = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
        
        Test.startTest();
            insert ua;
            ua = [SELECT Id, Name, Student_Person_ID__c, Course_Code__c, Unit_Code__c, Teaching_Period__c, Academic_Year__c, deleted_in_source__c
                    FROM Unit_Attempt__c
                   WHERE Id = :ua.Id
                   LIMIT 1];
            String uniqueName = UnitAttemptServices.getUniqueName(ua);
        Test.stopTest();

        String expected = ua.Student_Person_ID__c + '/' + 
                        ua.Course_Code__c + '/' + 
                        ua.Unit_Code__c + '/' + 
                        ua.Academic_Year__c + '-' + ua.Teaching_Period__c  ;
        Assert.areEqual(expected, uniqueName);
    }

     /**
     * Test Scenario:
     *  getUniqueExt() method should return the following name format:
     *  PERSON_ID-COURSE_CD-UNIT_CD-CAL_TYPE-CI_SEQUENCE_NUMBER
     */
    @isTest
    static void test_getUniqueExt() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Course_Attempt__c ca = [SELECT Id FROM Course_Attempt__c LIMIT 1];

        //create test unit attempt
        Unit_Attempt__c ua = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
        
        Test.startTest();
            insert ua;
            String uniqueExt = UnitAttemptServices.getUniqueExt(ua);
        Test.stopTest();

        ua = [SELECT Id, Student_Person_ID__c, Course_Code__c, Unit_Code__c, 
                Calendar_Type__c, CI_Sequence_Number__c, SUA_External_ID__c
                FROM Unit_Attempt__c
                WHERE Id = :ua.Id
                LIMIT 1];

        String expected = ua.Student_Person_ID__c + '-' + 
                        ua.Course_Code__c + '-' + 
                        ua.Unit_Code__c + '-' + 
                        ua.Calendar_Type__c + '-' + 
                        ua.CI_Sequence_Number__c;
        Assert.areEqual(expected, ua.SUA_External_ID__c);
    }

	/**
	 * For testing bulkified logic. Should be capable of inserting at least
	 * 200 records at a time.
	 */
	@isTest
	static void test_bulk_insert() {
		Contact con = [SELECT Id FROM Contact LIMIT 1];
		Course_Attempt__c ca = [SELECT Id FROM Course_Attempt__c LIMIT 1];

		//create unit attempt for 'update' and 'delete' scenario
		List<Unit_Attempt__c> uaList = TestHelper.createUnitAttempts(MAX_BULK_TEST, ca.Id, con.Id);
		Test.startTest();
			insert uaList;
		Test.stopTest();
		Assert.areEqual(MAX_BULK_TEST, 
							[SELECT COUNT() FROM Unit_Attempt__c], 
							'An error occurred while creating bulk Unit Attempts. size : ' + MAX_BULK_TEST);
	}

    
    /**
     * 
     * If a SUA is received from Callista before the unit offering is received, the field remains empty unless it's reimported.
     * We can now simply update to SUA to attach it with the correct UO
     * 
     * GIVEN
     * An existing unit attempt with a null unit_offering__c field
     * WHEN
     * Its updated and has the correct data to match a unit offering
     * THEN
     * The unit offering field is populated
     **/
  	@isTest
	static void test_assignUnitOffering() {
		Contact con = [SELECT Id FROM Contact LIMIT 1];
		Course_Attempt__c ca = [SELECT Id FROM Course_Attempt__c LIMIT 1];

		//create unit attempt for 'update' and 'delete' scenario
		Unit_Attempt__c ua = TestHelper.createUnitAttempts(1, ca.Id, con.Id)[0];
		ua.Academic_Year__c = '2021';
        ua.Location__c = 'Clayton';
        ua.Unit_Version__c = 1;
        ua.Unit_Code__c = 'UnitXYZ';
        ua.Calendar_Type__c = 'S0-1' ;
        ua.Teaching_Period__c = 'S0-1';
        ua.CI_Sequence_Number__c = '10001';
		insert ua;
        
        Test.startTest();
        ua.Unit_Class__c = 'ON-CAMPUS';
        update ua;
		Test.stopTest();

        ua = [select unit_offering__c from unit_attempt__c where id = :ua.id];
		Assert.isNotNull(ua.unit_offering__c);        
	}

}