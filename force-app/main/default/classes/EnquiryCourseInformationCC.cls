/**
 * @author          Angelo Rivera
 * @description     Controller class for Course Information Lightning component to retrieve, display and link Application and Course Attempts to enquiries
 * @group           Enquiry Management
 * @History         12.12.2018 - Created
 *                  23.01.2019 - APRivera - replace managing faculty by course id when searching for course
 *                  09.07.2019 - APRivera - moved course auto-linking from this component to case trigger - whenever contact is linked to case.
 *                  08.10.2019 - APRivera - MC-594: Added filter criteria on Case Origin before updating Managing Faculty
 *                  28.01.2020 - APRivera - Included Unit Enrolment on contact query
 *                  02.03.2020 - APRivera - Set Managing Faculty field for MonCon Record Type 0 Manual Linking
 *                  15.09.2020 - APRivera - Added auto-linking of Course Attempt and Application Course Preference to Enquiry
 *					02.02.2021 - APRivera - Replaced Unit Enrolment with Unit Attempts
 *					15.02.2021 - APRivera - Updated class security settings
 */

public with sharing class EnquiryCourseInformationCC {

	public static Contact contactRecord = new Contact();
	public static List<String> courseStatusList = new List<String>();
	public static String strLinkedCourseCode;

	//wrapper class that binds the data needed in lightning component
	public class ThisWrapperClass{
		@AuraEnabled public List<Course_Attempt__c> lstCourseAttempts { get; set; }
		@AuraEnabled public List<Application_Course_Preference__c> lstApplications { get; set; }
		@AuraEnabled public List<Unit_Attempt__c> lstUnitAttempts { get; set; }
		@AuraEnabled public Integer intCourseAttemptsCount { get; set; }
		@AuraEnabled public Integer intApplicationsCount { get; set; }
		@AuraEnabled public Integer intUnitAttemptsCount { get; set; }
		@AuraEnabled public String linkedCourse { get; set; }
	}

	//Collects data to be passed through the lightning component
	@AuraEnabled
	public static ThisWrapperClass retrieveStudentInformation(String strContactId) {
		ThisWrapperClass thisWrapper = new ThisWrapperClass();
		retrieveStudentsData(thisWrapper, strContactId);
		thisWrapper.linkedCourse = strLinkedCourseCode;
		return thisWrapper;
	}

	//Retrieve students data
	public static void retrieveStudentsData(ThisWrapperClass thisWrapper, String strContactId) {
		thisWrapper.lstCourseAttempts = new List<Course_Attempt__c>();
		thisWrapper.lstApplications = new List<Application_Course_Preference__c>();
		thisWrapper.lstUnitAttempts = new List<Unit_Attempt__c>();
		getContactDetails(strContactId);
		thisWrapper.lstCourseAttempts.addAll(contactRecord.Course_Attempts__r);
		thisWrapper.lstApplications.addAll(contactRecord.Application_Course_Preferences__r);
		thisWrapper.lstUnitAttempts.addAll(contactRecord.Unit_Attempts__r);
		thisWrapper.intCourseAttemptsCount = contactRecord.Course_Attempts__r.size();
		thisWrapper.intApplicationsCount = contactRecord.Application_Course_Preferences__r.size();
		thisWrapper.intUnitAttemptsCount = contactRecord.Unit_Attempts__r.size();
	}

	//Retrieve contact details
	public static void getContactDetails(String strContactId) {
		contactRecord = [
				SELECT Id, Name, (SELECT Id, Name, Course__c, Course_Code__c, Course_Attempt_Status__c, Attendance_Type__c, Attendance_Mode__c,
						Location__c, Course_Managing_Faculty__c, Course_Short_Title__c FROM Course_Attempts__r),
				(SELECT Id, Name, Managing_Faculty_Text__c, Course__c, Course_Title__c, Course_Code__c, Outcome_Status__c,
						Offer_Response_Status__c, Outcome_Status_Value__c, Offer_Response_Status_LOV__r.Value__c FROM Application_Course_Preferences__r),
				(SELECT Id, Title__c, Unit_Code__c, Status__c, Teaching_Period__c, Academic_Year__c, Teaching_Calendar__r.Description__c
					FROM Unit_Attempts__r ORDER BY Academic_Year__c DESC )
				FROM Contact
				WHERE Id = :strContactId
		];
	}

	//Retrieve case details
	public static Case retrieveCaseDetails(Id enquiryId) {
		Case caseRecord = new Case();
		caseRecord = [SELECT Id, Status, Managing_Faculty__c, Course_Linked__c, ContactId, Contact.Person_ID__c FROM Case WHERE Id = :enquiryId LIMIT 1];
		return caseRecord;
	}

	//Retrieve accepted course statuses
	public static void getCourseStatusList(List<String> courseStatusList) {
		String courseStatusLabel = Label.Console_CourseStatus;
		if (courseStatusLabel != '' && courseStatusLabel != null) {
			for (String cStatus : courseStatusLabel.split(',')) {
				courseStatusList.add(cStatus);
			}
		}
		if (Test.isRunningTest()) {
			courseStatusList.add('COMPLETED');
			courseStatusList.add('ENROLLED');
		}
	}

	//Build course attempts map by course attempts status
	public static Map<String, List<Course_Attempt__c>> buildMapCourseAttemptsByStatus(Contact con) {
		Map<String, List<Course_Attempt__c>> mapCourseAttemptsByStatus = new Map<String, List<Course_Attempt__c>>();
		for (Course_Attempt__c courseAttempt : con.Course_Attempts__r) {
			if (!mapCourseAttemptsByStatus.containsKey(courseAttempt.Course_Attempt_Status__c.touppercase()))
				mapCourseAttemptsByStatus.put(courseAttempt.Course_Attempt_Status__c.touppercase(), new List<Course_Attempt__c>());
			mapCourseAttemptsByStatus.get(courseAttempt.Course_Attempt_Status__c.touppercase()).add(courseAttempt);
		}
		return mapCourseAttemptsByStatus;
	}

	/**
     *  @description    Update Enquiry with the new linked Course
     *  @param          componentEnquiry - Case record, courseAttempt - course attempt record related to the case
	 *  @revision		20/10/2023 - Removed update DML statement 
     */
	public static void updateEnquiryWithCourseLink(Case componentEnquiry, Course_Attempt__c courseAttempt) {
		try {
			if (courseAttempt != null) {
				componentEnquiry.Course__c = courseAttempt.Course__c;
				componentEnquiry.Course_Code__c = courseAttempt.Course_Code__c;
				componentEnquiry.Location_Code__c = courseAttempt.Location__c;
				componentEnquiry.Attendance_Mode__c = courseAttempt.Attendance_Mode__c;
				componentEnquiry.Attendance_Type__c = courseAttempt.Attendance_Type__c;
				if(componentEnquiry.Origin != CaseUtilities.ORIGIN_WEB_MONPLAN
						&& componentEnquiry.RecordTypeId != MonConCaseServices.COMPLAINT_RECTYPEID
						&& componentEnquiry.Origin != 'Web - Monash Forms'
						&& componentEnquiry.Category_Level_1__c != 'Academic Integrity Breach'){
					// MC-594 - Added filter criteria on Case Origin before updating Managing Faculty
					componentEnquiry.Managing_Faculty__c = courseAttempt.Course_Managing_Faculty__c;
				}
				componentEnquiry.Home_Campus__c = courseAttempt.Location__c;
				componentEnquiry.Campus__c = courseAttempt.Location__c;
				componentEnquiry.Course_Linked__c = true; // APRivera - 03/05/2018 - DCXCRM-1690 - Fix on incorrect 'Last Modified by' value
				componentEnquiry.Course_Attempt__c = courseAttempt.Id;
				componentEnquiry.Course_Attempt_Status__c = courseAttempt.Course_Attempt_Status__c;
				
				System.debug(LoggingLevel.INFO, 'ENQUIRY UPDATED AND LINKED TO COURSE CODE ' + courseAttempt.Course_Code__c);
				strLinkedCourseCode = courseAttempt.Course_Code__c;
			}
		} catch (exception ex) {
			system.debug('>>>>>Exception Occurred::' + ex);
			LogUtilityException.logException(ex,'EnquiryCourseInformationCC updateEnquiryWithCourseLink update Course on Enquiry');
		}
	}

	//auto link the course to enquiry
	@AuraEnabled
	public static void autoLinkToCase(Id enquiryId) {
		//Initialize Variables
		Case componentEnquiry = new Case();
		Course_Attempt__c courseAttempt = new Course_Attempt__c();
		Map<String, List<Course_Attempt__c>> mapCourseAttemptsByStatus = new Map<String, List<Course_Attempt__c>>();

		getCourseStatusList(courseStatusList);
		componentEnquiry = retrieveCaseDetails(enquiryId);
		mapCourseAttemptsByStatus = buildMapCourseAttemptsByStatus(contactRecord);

		updateCaseLinkCourse(componentEnquiry, mapCourseAttemptsByStatus, courseAttempt);
	}

	//actual update on case where course is linked
	public static void updateCaseLinkCourse(Case componentEnquiry, Map<String, List<Course_Attempt__c>> mapCourseAttemptsByStatus, Course_Attempt__c courseAttempt){
		//Autolink the course if the criteria is satisfied
		if (componentEnquiry.Status == 'Open' && String.valueOf(componentEnquiry.Managing_Faculty__c) != '' && componentEnquiry.Course_Linked__c == false) {
			if (!mapCourseAttemptsByStatus.isEmpty() && !courseStatusList.isEmpty()){
				//Iterate through each accepted course status
				for (String courseStatus : courseStatusList) {
					if (mapCourseAttemptsByStatus.containsKey(courseStatus) && mapCourseAttemptsByStatus.get(courseStatus).size() > 0) {
						if(mapCourseAttemptsByStatus.get(courseStatus).size() == 1){
							courseAttempt = mapCourseAttemptsByStatus.get(courseStatus).get(0);
							//update the enquiry to link the course
							updateEnquiryWithCourseLink(componentEnquiry,courseAttempt);
							break;
						}
					}
				}
			}
		}
	}

	/**
	*  @author         Kristian Vegerano
	*  @description    links course to enquiry when LINK button is hit in lightning component
	*  @param          enquiryId - id of the enquiry to be updated
	*  @param          courseId - record id of the course
	*  @param          courseCode -Course code
	*  @param          courseAttemptId - id of the course attempt
	*  @param          courseAttemptStatus - Course Attempt Status
	*  @return         unlinkedCase - case to be updated
	*  @revision       15.09.20 - APRivera - added Course Attempt field
	*/
	@AuraEnabled
	public static Case linkCourse(Id enquiryId, String courseId, String courseCode, String courseAttemptId, String courseAttemptStatus) {
		//Initialize Variables
		System.debug('---------- linking Course');
		Course__c toLinkCourse = new Course__c();
		toLinkCourse = [SELECT Id, Name, Managing_Faculty__c, CreatedDate, Title__c FROM Course__c
		WHERE Id =: courseId AND Name = :courseCode
		AND Type__c != NULL
		ORDER BY CreatedDate ASC LIMIT 1];

		Case updateEnquiry = new Case(Id = enquiryId);
		//Update Enquiry with Course field values
		updateEnquiry.Course__c = toLinkCourse.Id;
		updateEnquiry.Course_Code__c = toLinkCourse.Name;
		updateEnquiry.Course_Linked__c = true;
		if(updateEnquiry.RecordTypeId == MonConCaseServices.MONCONSUPPORT_RECTYPEID) updateEnquiry.Managing_Faculty__c = toLinkCourse.Managing_Faculty__c;
		updateEnquiry.Course_Attempt_Status__c = courseAttemptStatus;
		updateEnquiry.Course_Attempt__c = courseAttemptId;
		
		update updateEnquiry;

		//Return updated enquiry
		return updateEnquiry;
	}

	/**
	 *  @author         Kristian Vegerano
	 *  @description    Method for unlinking the course record on the enquiry record
	 *  @param          enquiryId - id of the enquiry to be updated
	 *  @return         unlinkedCase - case to be updated
	 *  @revision       15.09.20 - APRivera - added Course Attempt field
	 */
	@AuraEnabled
	public static Case unlinkCourse(Id enquiryId) {
		//Initialize Variables
		Case unlinkedCase = new Case();
		unlinkedCase = [SELECT Id FROM Case WHERE Id = :enquiryId LIMIT 1];

		//Update Course fields
		unlinkedCase.Course__c = null;
		unlinkedCase.Course_Code__c = null;
		unlinkedCase.Course_Linked__c = false;
		unlinkedCase.Course_Attempt__c = null;
		unlinkedCase.Course_Attempt_Status__c = '';
		update unlinkedCase;

		//Return updated enquiry
		return unlinkedCase;
	}

	/**
	 *  @author         Kristian Vegerano
	 *  @description    Method for retrieving the course record based on the managing faculty and course code
	 *  @param          courseId - record Id of the course
	 *  @param          courseCode - course code of the selected course
	 *  @return         toLinkCourse - Course record
	 */
	@AuraEnabled
	public static Course__c goToCourse(String courseId, String courseCode) {
		//Initialize Variables
		Course__c toLinkCourse = new Course__c();
		toLinkCourse = [SELECT Id, Name, Managing_Faculty__c, CreatedDate FROM Course__c
		WHERE Id = :courseId AND Name = :courseCode
		AND Type__c != null
		ORDER BY CreatedDate ASC LIMIT 1];

		return toLinkCourse;
	}
}