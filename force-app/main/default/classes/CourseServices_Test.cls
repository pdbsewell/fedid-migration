/**
 * @author          Stefan Scheit
 * @description     Test class for CourseServices
 * @revision        14/08/2018 - Added Test for Capturing of Latest Active Course Version (DCXCRM-1986)
 * 					02/08/2018 - Nick Guia - Added test scenarios for LinkCourseMaster, and RollupLatestCourse
 *                  25/04/2018 - Stefan Scheit - Added setup record count 
 *                  24/04/2018 - PwC - Initial version
 */
@isTest(isParallel=true)
public class CourseServices_Test {
 
	private static final Integer SETUP_RECORD_COUNT = 500;
	
	@testSetup
	static void testSetup() {
		List<Course__c> courseList = new List<Course__c>();
		for (Integer i=0; i<SETUP_RECORD_COUNT; i++) {
			Course__c course = new Course__c();
			course.Name = 'CourseName-'+i;
			course.Version__c = String.valueOf(i);
			courseList.add(course);
		}
		try {
			insert courseList;
			courseList = [SELECT Id FROM Course__c];
			Assert.areEqual(SETUP_RECORD_COUNT, courseList.size(), 'Number of courses does not match the expected number');
		} catch (Exception ex) {
			Assert.isNotNull(ex, 'Courses could not be inserted as part of testSetup.');
		}
	}
	
	@isTest
	public static void testUpdateFields() {
		Test.startTest();
		final List<Course__c> courseList = [SELECT Id, Name, Course_Code__c, Version__c FROM Course__c];
		Test.stopTest();
		Assert.areEqual(SETUP_RECORD_COUNT, courseList.size(), 'Nubmer of courses does not match the expected number');
		for (Course__c iCourse : courseList) {
			Assert.isNotNull(iCourse.Name, 'Name is null');
			Assert.isNotNull(iCourse.Course_Code__c, 'Course_Code__c is null');
			Assert.isNotNull(iCourse.Version__c, 'Version__c is null');
			Assert.areEqual(CourseServices.getCourseCodeUnique(iCourse.Name, iCourse.Version__c), iCourse.Course_Code__c, 'Course_Code__c is not set as expected.');
		}
	}
	
	@isTest
	public static void testGetCourseCodeUnique() {
		final String courseName = 'A2000';
		final Decimal version = 1.0;
		Test.startTest();
		String courseCodeUnique = CourseServices.getCourseCodeUnique(courseName, version);
		Test.stopTest();
		Assert.areEqual(courseName+'_'+version, courseCodeUnique, 'CourseCodeUnique is not calculated as expected.');
	}
	
	@isTest
	public static void testGetCourseCodeUniqueInteger() {
		final String courseName = 'A2000';
		final Integer version = 1;
		Test.startTest();
		String courseCodeUnique = CourseServices.getCourseCodeUnique(courseName, version);
		Test.stopTest();
		Assert.areEqual(courseName+'_'+version, courseCodeUnique, 'CourseCodeUnique is not calculated as expected.');
	}

	/**
	 * @author Nick Guia
	 * @description test if getExistingCourseMaster can correctly retrieve
	 *				Course Master records based on Course list input.
	 */
	static void testGetExistingCourseMaster() {
		Map<String, Course_Master__c> courseMapByCode;
		//assuming all setup course records have unique course codes
		List<Course__c> courseList = [SELECT Id, Name, Course_Master__c
										FROM Course__c LIMIT 200];
		Test.startTest();
			courseMapByCode = CourseServices.getExistingCourseMaster(courseList);
		Test.stopTest();
		//check if method was able to retrieve the correct record count
		Assert.areEqual(200, courseMapByCode.size());
	}

	/**
	 * @author Nick Guia
	 * @description Insert new Courses with unique Course Codes. The expected behavior is for the trigger
	 * 				logic to generate a Course Master record for each code, and that Courses are linked
	 * 				to the corresponding Course Master (same code).
	 * 				Scenario: Create Courses whose Course Codes are unique for each. Course Master recods that will be created
	 * 					should be equal to the number of Courses + SETUP_RECORD_COUNT (setup records)
	 */
	@isTest
	static void testInsertLinkCourseMaster() {
		final Integer COURSE_COUNT = 10;
		List<Course__c> courseList = new List<Course__c>();
		for(Course__c iCourse : TestHelper.createCourses(COURSE_COUNT)) {
			iCourse.Type__c = Label.Course_Type_Course_All;
			courseList.add(iCourse);
		}

		Test.startTest();
			insert courseList;
		Test.stopTest();
		//check if number of course master created is same as Courses
		Assert.areEqual(COURSE_COUNT, //since currently, setup records doesn't have types
							[SELECT Id FROM Course_Master__c].size());
	}

	/**
	 * @author Nick Guia
	 * @description Test Scenario to update the course Name (Course Code).
	 * 				Scenario: Create Courses - first one's Course Code will be update to be the same as the
	 *				2nd Course in the list. The 3rd test Course record's Course Code
	 *				will be updated to a new and unique code, which should then create a new
	 *				Course Master record.
	 */
	@isTest
	static void testUpdateLinkCourseMaster() {
		//insert courses with different course codes : '1' & '2' & '3'
		List<Course__c> courseList = new List<Course__c>();
		for(Course__c iCourse : TestHelper.createCourses(3)) {
			iCourse.Type__c = Label.Course_Type_Course_All;
			courseList.add(iCourse);
		}
		insert courseList;

		List<Course__c> courseUpdateList = new List<Course__c>();

		//change course1's course to be the same as course2's
		Course__c course1 = courseList[0];
		Course__c course2 = courseList[1];
		//this will have a non-existing Course Code
		Course__c course3 = courseList[2];

		course1.Name = course2.Name;
		courseUpdateList.add(course1);

		//update course3's code to a random unique code
		course3.Name = 'testUpdateLinkCourseMaster-test';
		courseUpdateList.add(course3);

		Test.startTest();
			update courseUpdateList;
		Test.stopTest();
		
		/**
		 * Assumptions: 1. course1 will be linked to the same Course Master as course2
		 *              2. a new Course Master record will be created for course3
		 */
		Course_Master__c cm = [SELECT Id, Name
								FROM Course_Master__c
								WHERE Course_Code__c = :course3.Name
								LIMIT 1];
		Assert.isNotNull(cm);

		courseList = [SELECT Id, Name, Course_Master__c
						FROM Course__c
						WHERE Id IN (:course1.Id, :course2.Id)
						LIMIT 2];
		Assert.areEqual(courseList[0].Course_Master__c, courseList[1].Course_Master__c);
	}

	/**
	 * @author Nick Guia
	 * @description Insert new course records whose Versions are not null.
	 *				This method logic should pickup the new latest version of Courses
	 *				and roll it up to the corresponding Course Master.
	 */
	@isTest
	static void testInsertRollupLatestCourse() {
		//create a test Course that will serve as our 'existing' Course under the Course Master
		Course__c existing = new Course__c(Name = 'X', Version__c = '1', Type__c = Label.Course_Type_Course_All);
		insert existing;

		List<Course__c> courseList = new List<Course__c>();
		//create a new course with 'X' code, but with greater version
		Course__c existingV2 = new Course__c(Name = 'X', Version__c = '2', Type__c = Label.Course_Type_Course_All);
		//insert courses with same codes but different version in a single transaction
		//the logic should be able to pickup v2 as the latest version and roll it up to Course Master
		Course__c newV1 = new Course__c(Name = 'Y', Version__c = '1', Type__c = Label.Course_Type_Course_All);
		Course__c newV2 = new Course__c(Name = 'Y', Version__c = '2', Type__c = Label.Course_Type_Course_All);
		courseList.add(existingV2);
		courseList.add(newV1);
		courseList.add(newV2);

		Test.startTest();
 			insert courseList;
		Test.stopTest();

		for(Course_Master__c cm : [SELECT Id, Course_Code__c, Latest_Course_Version__c
									FROM Course_Master__c
									WHERE Course_Code__c = 'X'
									OR Course_Code__c = 'Y'
									LIMIT 2])
		{
			if(cm.Course_Code__c == 'X') {
				Assert.areEqual(existingV2.Id, cm.Latest_Course_Version__c);
			} else {
				Assert.areEqual(cm.Latest_Course_Version__c, newV2.Id);
			}
		}
	}

	/**
	 * @author Nick Guia
	 * @description if Course Master lookup in Course or Version field is updated,
	 *				the corresponding Course Master record should re-evaluate it's new
	 *				Lastest Course Version. Course Master records to be evaluated includes
	 *				both the Course Master of the Course and the old value (if not null)
	 */
	@isTest
	static void testUpdateRollupLatestCourse() {
		List<Course__c> courseList = TestHelper.createCourses(4);
		//setup records for version update
		Course__c courseX1 = courseList[0];
		courseX1.Name = 'X';
		courseX1.Version__c = '1';
		courseX1.Type__c = Label.Course_Type_Course_All;
		courseX1.Status__c = Label.Course_Status_Active;

		Course__c courseX2 = courseList[1];
		courseX2.Name = 'X';
		courseX2.Version__c = '2';
		courseX2.Type__c = Label.Course_Type_Course_All;
		courseX2.Status__c = Label.Course_Status_Active;

		Course__c courseX3 = courseList[2];
		courseX3.Name = 'X';
		courseX3.Version__c = '3';
		courseX3.Type__c = Label.Course_Type_Course_All;
		courseX3.Status__c = Label.Course_Status_Active;

		//setup record for course code update
		Course__c courseY = courseList[3];
		courseY.Name = 'Y';
		courseY.Version__c = '1';
		courseY.Type__c = Label.Course_Type_Course_All;
		courseY.Status__c = Label.Course_Status_Active;
		insert courseList;

		Test.startTest();
 			List<Course__c> courseUpdateList = new List<Course__c>();
 			courseY.Name = 'X'; //update code-Course Master should be updated
 			courseY.Version__c = '4';
 			courseX2.Version__c = '5'; //update version to latest
 			courseUpdateList.add(courseX2);
 			courseUpdateList.add(courseY);
 			update courseUpdateList;
		Test.stopTest();

		for(Course_Master__c cm : [SELECT Id, Course_Code__c, Latest_Course_Version__c,
									Latest_Active_Course_Version__c
									FROM Course_Master__c
									WHERE Course_Code__c = 'X'
									OR Course_Code__c = 'Y'
									LIMIT 2])
		{
			if(cm.Course_Code__c == 'Y') {
				//Latest_Course_Version__c should now be null
				Assert.isNull(cm.Latest_Course_Version__c);
				Assert.isNull(cm.Latest_Active_Course_Version__c);
			} else {
				Assert.areEqual(courseX2.Id, cm.Latest_Course_Version__c);
				Assert.areEqual(courseX2.Id, cm.Latest_Active_Course_Version__c);
			}
		}
	}

	/**
	 * @author Nick Guia
	 * @description if Course Record's status changes from something else to 'Active', The
	 *				associated Course Master's Latest Active Course Version should be re-evaluated
	 */
	@isTest
	static void testUpdateRollupLatestCourseVersion() {
		List<Course__c> courseList = TestHelper.createCourses(4);
		//setup records for version update
		Course__c courseX1 = courseList[0];
		courseX1.Name = 'X';
		courseX1.Version__c = '1';
		courseX1.Type__c = Label.Course_Type_Course_All;

		Course__c courseX2 = courseList[1];
		courseX2.Name = 'X';
		courseX2.Version__c = '2';
		courseX2.Type__c = Label.Course_Type_Course_All;
		insert courseList;

		Test.startTest();
			Course_Master__c cm = [SELECT Id, Course_Code__c, Latest_Course_Version__c,
									Latest_Active_Course_Version__c
									FROM Course_Master__c
									WHERE Course_Code__c = 'X'
									LIMIT 1];
			//at this stage, course master's Latest_Active_Course_Version__c should still
			//be null, since the Course status isn't active yet
			Assert.isNull(cm.Latest_Active_Course_Version__c);
 			courseX2.Status__c = Label.Course_Status_Active; //update status to active
 			update courseX2;
		Test.stopTest();

		cm = [SELECT Id, Course_Code__c, Latest_Course_Version__c,
				Latest_Active_Course_Version__c
				FROM Course_Master__c
				WHERE Course_Code__c = 'X'
				LIMIT 1];
		//since courseX2 has been activated, this should now be the latest avtive course version
		Assert.areEqual(courseX2.Id, cm.Latest_Active_Course_Version__c);

	}
}