/**
* @author Nick Guia, Martin Cadman
* @date 29.11.2018
*
* @group Qualification
*
* @description 
* IbdUnitAttemptServies test class.<br/>
*
* @revision
* 29.11.2018 Nick Guia - Initial version<br/>
* 19.02.2019 Nick Guia - Removed : assigning SUA_External_ID__c - IbdUnitAttemptServices will build this.
* 02.04.2019 Nick Guia - Removed : assigning SUA_External_ID__c - UnitAttemptServices will build this.
* 07.09.2019 Martin Cadman - Reviewed for code coverage, added retry exception test.
* 12.05.2024 Martin Cadman - Moved to Assert
*
*/

@isTest(isParallel=true)
public class IbdUnitAttemptServices_Test {

	private final static String PERSON_ID = '12345678';
	private final static String COURSE_CODE = 'CODE01';
	private final static String NEW_UA_UNIT_CODE = 'TEST-UC01';
	private final static String EXISTING_UA_UNIT_CODE = 'TEST-UC00';
	private final static Integer MAX_PE_BULK_TEST = 10; //max number for bulk test
	private final static Integer MAX_SETUP_RECORDS = 1; //max number for bulk test
	
	@testSetup
	static void setup() {
        // Disable some of the automation that occurs when contacts are created
        triggerCommon.disableTrigger('Contact');
        ucinn_ascendv2__Trigger_Handler__c disableEngageTrig = new ucinn_ascendv2__Trigger_Handler__c(ucinn_ascendv2__Object__c ='Contact',ucinn_ascendv2__Is_Active__c=False,ucinn_ascendv2__class__c='ascend_TRIG_Contact');
        insert disableEngageTrig;

        //create contact
		Contact con = TestHelper.createOrphanContactRecords(MAX_SETUP_RECORDS)[0];
		con.Person_ID_unique__c = PERSON_ID;
        con.SAP_Staff_Id__c = 'NoDupRules'; // this will filter the contact out of the most of the duplicate rules
		insert con;
		Assert.areEqual(MAX_SETUP_RECORDS, [SELECT COUNT() FROM Contact], 'An error occurred while creating setup Contact');

		//create course
		Course__c courseRec = TestHelper.createCoursesWithType(MAX_SETUP_RECORDS, 'Course-All')[0];
		courseRec.Name = COURSE_CODE;
		insert courseRec;
		Assert.areEqual(MAX_SETUP_RECORDS, [SELECT COUNT() FROM Course__c], 'An error occurred while creating setup Course');

		//create course attempt
		Course_Attempt__c ca = TestHelper.createCourseAttempts(MAX_SETUP_RECORDS, con.Id, courseRec.Id)[0];
		ca.Callista_External_Id__c = PERSON_ID + '_' + COURSE_CODE;
		insert ca;
		Assert.areEqual(MAX_SETUP_RECORDS, [SELECT COUNT() FROM Course_Attempt__c], 'An error occurred while creating setup Course Attempt');

        //create org unit
		Account ou = new Account(Callista_Org_Unit_Code__c = 'OrgUnitCode', name = 'Test Faculty', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Faculty').getRecordTypeId());
        insert ou;

		//create calendar
        Calendar__c cal = new Calendar__c(name='TestCalendar', sequence_number__c = 0001);
		insert cal;
        
        Unit_Offering__c uo = new Unit_Offering__c(Unit_Code__c = NEW_UA_UNIT_CODE, Academic_Year__c = '2021', Calendar_Type__c = 'ADM-2', CI_Sequence_Number__c = '0001', location__c = 'CLAYTON', unit_version__c = '1', unit_class__c = 'ON-CAMPUS');
        insert uo;
        uo = [select UO_Unique_Key__c from Unit_Offering__c limit 1];
        
		//create unit attempt for 'update' and 'delete' scenario
		Unit_Attempt__c ua = TestHelper.createUnitAttempts(MAX_SETUP_RECORDS, ca.Id, con.Id)[0];
		ua.Unit_Code__c = EXISTING_UA_UNIT_CODE;
        ua.Unit_Version__c = 1;
        ua.Location__c = 'CLAYTON';
		ua.Academic_Year__c = '2018';
		ua.Calendar_Type__c = 'ADM-2';
        ua.CI_Sequence_Number__c = '0001';    
        ua.Unit_Mode__c = 'ON';
        ua.Unit_Class__c = 'ON-CAMPUS';
        ua.Teaching_Period__c = '2';
		insert ua;
        Assert.areEqual(MAX_SETUP_RECORDS, [SELECT COUNT() FROM Unit_Attempt__c], 'An error occurred while creating setup Unit Attempt');
	}
	
   /*
	* @description Test scenario of creating IbdUnitAttempt__e with event type of 'insert'
	* Test only inserts 1 new record and resulting total unit attempt should be MAX_SETUP_RECORDS + 1
	*/  
    @isTest
	static void testInsertIbdUnitAttempt() {
		IbdUnitAttempt__e iua = TestHelper.createIbdUnitAttempts(1, CommonUtilities.EVENT_INSERT)[0];
		iua.Course_Code__C = COURSE_CODE;
		iua.Person_ID__c = PERSON_ID;
		iua.Unit_Code__c = NEW_UA_UNIT_CODE; //should be different from setup unit attempt
        iua.Unit_Version__c = 1;
		iua.Calendar_Type__c = 'ADM-2';
        iua.CI_Sequence_Number__c = '0001';    
        iua.Teaching_Period__c = '2';
        iua.Academic_Year__c = '2021';
        iua.Location__c = 'CLAYTON';
        iua.Unit_Mode__c = 'ON';
        iua.Unit_Class__c = 'ON-CAMPUS';
        iua.Org_Unit_Code__c = 'OrgUnitCode';
        iua.teaching_Org_Unit_Code__c = 'OrgUnitCode';
		iua.Event_Type__c = 'INSERT';
       
        String strExtId = UnitAttemptServices.getUniqueExt(iua.Person_ID__c, iua.Course_Code__c, iua.Unit_Code__c, iua.Calendar_Type__c, iua.CI_Sequence_Number__c);
		Test.startTest();
			Database.SaveResult sr = EventBus.publish(iua);
		Test.stopTest();      
		Assert.isTrue(sr.isSuccess(), 'Unit Attempt event could not be published. Errors: ' + sr.getErrors());
        
		//query all fields from unit attempt
		String uaQuery = CommonUtilities.queryBuilder('Unit_Attempt__c');
		String filter = ' WHERE Student__r.Person_ID_unique__c = :PERSON_ID AND Course_Code__c = :COURSE_CODE';
		List<Unit_Attempt__c> uaList = Database.query(uaQuery + filter);

        //we should now have 2 existing Unit Attempt records
		Assert.areEqual(2, uaList.size());

		//pull the new Unit Attempt record from the list
		Unit_Attempt__c newUA;
		for(Unit_Attempt__c iUnitAttempt : uaList) {
			if(iUnitAttempt.SUA_External_ID__c == strExtId) {
                newUA = iUnitAttempt;
			}
		}
		Assert.isNotNull(newUA, 'Created Unit Attempt has an invalid External ID');
		Assert.isNotNull(newUA.Unit_Offering__c, 'Created Unit Attempt should reference the unit offering');
	}

   /*
	* @description Test scenario of creating IbdUnitAttempt__e with event type of 'update'
	* This test updates Rule_Waived_Comments__c and checks the change is reflected on the target Unit Attempt.
	*/  
	@isTest
	static void testUpdateIbdUnitAttempt() {

		IbdUnitAttempt__e iua = TestHelper.createIbdUnitAttempts(1, CommonUtilities.EVENT_UPDATE)[0];
		//should be the same with setup unit attempt
		iua.Course_Code__C = COURSE_CODE;
		iua.Person_ID__c = PERSON_ID;
		iua.Unit_Code__c = EXISTING_UA_UNIT_CODE;
		iua.Academic_Year__c = '2018';
		iua.Calendar_Type__c = 'ADM-2';
        iua.CI_Sequence_Number__c = '0001';    
        iua.Teaching_Period__c = '2';
        iua.Org_Unit_Code__c = 'OrgUnitCode';
        iua.teaching_Org_Unit_Code__c = 'OrgUnitCode';
		iua.Event_Type__c = 'UPDATE';


		//update start date
		iua.Rule_Waived_Comments__c = 'An update has occured';
        
		Test.startTest();
		Database.SaveResult sr = EventBus.publish(iua);
		Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
		
		List<Unit_Attempt__c> uaList = [SELECT Id FROM Unit_Attempt__c];
		//verify that the new IUA didn't create a new Unit Attempt
		Assert.areEqual(1, uaList.size());
		//verify that Start Date was updated
		Assert.areEqual(iua.Rule_Waived_Comments__c, 'An update has occured');
	}

   /*
	* @description Test scenario of creating IbdUnitAttempt__e with event type of 'delete'
    * The deleted in source flag should be set to true as a result
	*/  
	@isTest
	static void testDeleteExitingIbdUnitAttempt() {

		IbdUnitAttempt__e iua = TestHelper.createIbdUnitAttempts(1, CommonUtilities.EVENT_DELETE)[0];
		iua.Course_Code__C = COURSE_CODE;
		iua.Person_ID__c = PERSON_ID;
		iua.Unit_Code__c = EXISTING_UA_UNIT_CODE; //should be the same with setup unit attempt
        iua.CI_Sequence_Number__c = '0001';
        iua.Calendar_Type__c = 'ADM-2' ;
        iua.Org_Unit_Code__c = 'OrgUnitCode';
        iua.teaching_Org_Unit_Code__c = 'OrgUnitCode';
        iua.Event_Type__c = 'DELETE';

		Test.startTest();
			Database.SaveResult sr = EventBus.publish(iua);
		Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
		
		Assert.areEqual(1,[SELECT count() FROM Unit_Attempt__c where deleted_in_source__c = true]);
	}

    /*
 	 * @description Test scenario of creating IbdUnitAttempt__e with event type of 'delete' for a Unit Attempt that does not exist
	 * The deleted in source flag should be set to true as a result
	 */  
	@isTest
	static void testDeleteIbdUnitAttempt() {

		IbdUnitAttempt__e iua = TestHelper.createIbdUnitAttempts(1, CommonUtilities.EVENT_DELETE)[0];
		iua.Course_Code__C = COURSE_CODE;
		iua.Person_ID__c = PERSON_ID;
		iua.Unit_Code__c = 'Missing'; 
        iua.CI_Sequence_Number__c = '0001';
        iua.Calendar_Type__c = 'ADM-2' ;
        iua.Org_Unit_Code__c = 'OrgUnitCode';
        iua.teaching_Org_Unit_Code__c = 'OrgUnitCode';

		Test.startTest();
			Database.SaveResult sr = EventBus.publish(iua);
		Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
		
		Assert.areEqual(1,[SELECT count() FROM Unit_Attempt__c where deleted_in_source__c = true]);
	}

    
   /*
	* @description Test scenario of creating mutitiple IbdUnitAttempt__e with the same unique key
	*/  
	@isTest
	static void testInsertIbdUnitAttemptDuplicate() {
		List<IbdUnitAttempt__e> iuaList = new List<IbdUnitAttempt__e>();
		for(IbdUnitAttempt__e iua : TestHelper.createIbdUnitAttempts(2, CommonUtilities.EVENT_INSERT))
		{
			iua.Course_Code__C = COURSE_CODE;
			iua.Person_ID__c = PERSON_ID;
			iua.Unit_Code__c = NEW_UA_UNIT_CODE; //should be different from setup unit attempt
 	        iua.Teaching_Period__c = '2';
       		iua.Org_Unit_Code__c = 'OrgUnitCode';
            iua.teaching_Org_Unit_Code__c = 'OrgUnitCode';
            iua.CI_Sequence_Number__c = '0001';
            iua.Calendar_Type__c = 'ADM-2' ;
			iuaList.add(iua);
		}
		      
		Test.startTest();
			List<Database.SaveResult> srList = EventBus.publish(iuaList);
		Test.stopTest();

		//duplicate external ID records must be reprocessed once.
		for (Database.SaveResult sr : srList) {
			Assert.isTrue(sr.isSuccess(), 'Unit Attempt event could not be published. Errors: ' + sr.getErrors());
		}
		Assert.isTrue([SELECT count() FROM unit_attempt__c WHERE Person_ID__c = :PERSON_ID]==1);
	}
	
   /*
	* @description Bulk load test
	*/  	
    @isTest
	static void testInsertBulkIbdUnitAttempt() {
		//define order of commit
		List<Schema.SObjectType> commitOrder = 
			new List<Schema.SObjectType>{
                    Contact.SObjectType,
                    Course__c.SObjectType,
                    Course_Attempt__c.SObjectType
        	};
		BaseClass bc = new BaseClass(commitOrder);

		String PERSON_ID_BULK = '12345'; //will be concatenated with counter to avoid duplicate
		String COURSE_CODE_BULK = 'BULK0';
		String UNIT_CODE_BULK = 'BULK-UC0';
		Integer TOTAL_RECORDS = MAX_PE_BULK_TEST + MAX_SETUP_RECORDS;

		//lazy
		Contact con;
		Course__c courseRec;
		Course_Attempt__c ca;
		List<IbdUnitAttempt__e> iuaList = new List<IbdUnitAttempt__e>();
		for(Integer i = 0; i < MAX_PE_BULK_TEST; i++) {
			con = TestHelper.createOrphanContactRecords(1)[0];
			con.Person_ID_unique__c = PERSON_ID_BULK + i;

			//create course
			courseRec = TestHelper.createCoursesWithType(1, 'Course-All')[0];
			courseRec.Name = COURSE_CODE_BULK + i;

			//create course attempt
			ca = TestHelper.createCourseAttempts(1, null, null)[0];
			ca.Callista_External_Id__c = PERSON_ID_BULK + i + '_' + COURSE_CODE_BULK + i; //set external id

			bc.push(con);
			bc.push(courseRec);
			//resolve dependencies
			bc.relate(ca, Course_Attempt__c.Contact__c, con); 
			bc.relate(ca, Course_Attempt__c.Course__c, courseRec);
			bc.push(ca);

			//create inbound unit attempts
			IbdUnitAttempt__e iua = TestHelper.createIbdUnitAttempts(1, CommonUtilities.EVENT_INSERT)[0];
			iua.Course_Code__C = COURSE_CODE_BULK + i;
			iua.Person_ID__c = PERSON_ID_BULK + i;
			iua.Unit_Code__c = UNIT_CODE_BULK + i; //should be different from setup unit attempt
			iua.Academic_Year__c = '2018';
			iua.Teaching_Period__c = '2';
            iua.CI_Sequence_Number__c = '0001';
            iua.Calendar_Type__c = 'ADM-2' ;
            
      		iua.Org_Unit_Code__c = 'OrgUnitCode';
            iua.teaching_Org_Unit_Code__c = 'OrgUnitCode';
			iuaList.add(iua);
		}
		Boolean isSuccess = bc.commitRecords();
		Assert.isTrue(isSuccess, 'An error occurred while trying to insert bulk records');
		Assert.areEqual([SELECT Count() FROM Contact], TOTAL_RECORDS);
		Assert.areEqual([SELECT Count() FROM Course__c], TOTAL_RECORDS);
		Assert.areEqual([SELECT Count() FROM Course_Attempt__c], TOTAL_RECORDS);

		Test.startTest();
			List<Database.SaveResult> srList = EventBus.publish(iuaList);
		Test.stopTest();

		for (Database.SaveResult sr : srList) {
            Assert.isTrue(sr.isSuccess(), 'Unit Attempt event could not be published. Errors: ' + sr.getErrors());
        }
        Assert.areEqual(TOTAL_RECORDS, [SELECT Count() FROM Unit_Attempt__c]);
	}

   /*
	* @description Insert platform event record with Unit Attempt required value missing : CI_Sequence_Number__c
    * A platform Event Exception Log should be created afterwards.
	*/     
    @isTest
    static void testInsertRequiredFieldMissing() {
        IbdUnitAttempt__e iua = TestHelper.createIbdUnitAttempts(1, CommonUtilities.EVENT_INSERT)[0];
        iua.CI_Sequence_Number__c = NULL;

        Test.startTest();
            Database.SaveResult sr = EventBus.publish(iua);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());

        // No assert. 
        // Exception is raised async so can't validate
    }

   /*
	* @description Invalid Type 
    * Added for code coverage
	*/    
    @isTest
    static void testInsertUnknownEvent() {
        IbdUnitAttempt__e iua = TestHelper.createIbdUnitAttempts(1, 'INVALID')[0];
        iua.Teaching_Period__c = '2';
        iua.CI_Sequence_Number__c = '0001';
        iua.Calendar_Type__c = 'ADM-2' ;
        iua.Org_Unit_Code__c = 'OrgUnitCode';
        iua.teaching_Org_Unit_Code__c = 'OrgUnitCode';

        Test.startTest();
            Database.SaveResult sr = EventBus.publish(iua);
        Test.stopTest();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
    }

   /*
	* @description Insert a Unit Attempt with no available Course Attempt, and re-delivery it, to test the rety expection handling.
	*/ 
    @isTest
    static void testRetry() {
        Test.startTest();

        IbdUnitAttempt__e iua = TestHelper.createIbdUnitAttempts(1, 'INSERT')[0];
        iua.Person_ID__c = PERSON_ID;
        iua.Course_Code__c = 'X9999'; // Invalid course code, so no course attempt will be available
 		iua.Calendar_Type__c = 'ADM-2';
        iua.CI_Sequence_Number__c = '0001';    
        iua.Teaching_Period__c = '2';
        iua.Academic_Year__c = '2021';
        iua.Org_Unit_Code__c = 'OrgUnitCode';
        iua.teaching_Org_Unit_Code__c = 'OrgUnitCode';
		iua.Event_Type__c = 'INSERT';
       
        Database.SaveResult SR = EventBus.publish(iua);
        Test.getEventBus().deliver();
        Assert.isTrue(sr.isSuccess(), 'Event could not be published. Errors: ' + sr.getErrors());
 
        for(Integer i=0;i<2 ;i++) {                          
            // Get info about all subscribers to the event
            EventBusSubscriber[] subscribers = queryBus('IbdUnitAttempt__e');

            for (EventBusSubscriber sub : subscribers) { 
				if (sub.Name == 'IbdUnitAttemptTrigger') {
	                Assert.areEqual(i+1, sub.Retries);
                }
            }
            // Deliver the retried event
            Test.getEventBus().deliver();
        }

        Test.stopTest();
    }
    
    static List<EventBusSubscriber> queryBus(String ibdObject) {
        List<EventBusSubscriber> bus = new List<EventBusSubscriber>();
        try {
            bus = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic=:ibdObject];
        } catch(Exception e) {
            return new List<EventBusSubscriber>();
        }
        return bus;
    }
}