/*******************************************************************************
* @author       Ryan Wilson
* @date         07.Apr.2017         
* @description  controller class for CoursePreference.cmp lightning component
* @revision     Stefan Scheit (2018-09-15): Changed class to with sharing & added inner class (DeleteAppCoursePreference) to break out of sharing for deletion of ACP on application.
*******************************************************************************/
public with sharing class CoursePreferenceCC {
    public static final User userRecord = [SELECT Id, ContactId, ProfileId, App_Previously_Studied_at_Monash__c
                                           FROM User
                                           WHERE Id = :UserInfo.getUserId() LIMIT 1];
	
	public static final Contact applicant = [SELECT Id, Residency_Status__c FROM Contact WHERE Id =:userRecord.ContactId];

	public static final String POST_GRADUATE_FILTER = 'OPG';
    
    public static String QUERY_STRING = '';

    //Added by Hardeep Singh 20/05/2018
    // Method returns the Residency statusof applicant which drives Aura:if in the component
    @AuraEnabled
    public static string retrieveResidencyStatus(){
        return applicant.Residency_Status__c;
    }

    @AuraEnabled
    public static List<String> retrieveAttendanceType() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Course_Offering__c.Attendance_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }

        return options;
    }

    @AuraEnabled
    public static List<String> retrieveLocation(String searchStr) {
        List<String> options = new List<String>();

        String newSearchText = '%'+searchStr+'%';
        Map<String, String> mapLocations = new Map<String, String>();

        for(Course_Offering__c co : [SELECT Id, Location_Code__c, Course_Code__c, Course_Title__c
        							FROM Course_Offering__c
        							WHERE (Course_Code__c LIKE :newSearchText OR Course_Title__c LIKE :newSearchText)
        							ORDER BY Location_Code__c])
        {
            if(!mapLocations.containsKey(co.Location_Code__c)){
            	mapLocations.put(co.Location_Code__c, co.Location_Code__c);
            }
        }

        return mapLocations.values();
    }

    @AuraEnabled
    public static List<String> retrieveCommencementPeriod(String searchStr) {
        List<String> options = new List<String>();
        String newSearchText = '%'+searchStr+'%';
        Map<String, String> mapPeriods = new Map<String, String>();

        for(Course_Offering__c co : [SELECT Id, Admission_Calendar_Description__c, Course_Code__c, Course_Title__c
        							FROM Course_Offering__c
        							WHERE (Course_Code__c LIKE :newSearchText OR Course_Title__c LIKE :newSearchText)
        							ORDER BY Admission_Calendar_Description__c])
        {
            if(!mapPeriods.containsKey(co.Admission_Calendar_Description__c)){
            	mapPeriods.put(co.Admission_Calendar_Description__c, co.Admission_Calendar_Description__c);
            }
        }

        return mapPeriods.values();
    }


    private static List<Course_Offering__c> retrieveCourseOfferings(String searchStr, 
                                                                    String strCode,
                                                                    String strAttType,
                                                                    String strLocation,
                                                                    String strPeriod,
                                                                    Boolean hasUnitSets,
                                                                    String appCampusLocation) 
    {
		
		//Search filters;
		Integer maxSize = 2000;
		String newSearchText = '';
		String searchByCode = '';
		String searchByLocation = '';
		String searchByAttendanceType = '';
		String searchByCommencePeriod = '';

		List<Application_Course_Preference__c> appCoursePrefrences = new List<Application_Course_Preference__c>();
		Set<Id> appCourseOfferingIds = new Set<Id>();
        appCoursePrefrences = CoursePreferenceCC.retrieveAppCourses(strCode);
		for(Application_Course_Preference__c appCC: appCoursePrefrences){
        	appCourseOfferingIds.add(appCC.Course_Offering__c);
        }

        
        String citizenFilter = applicant.Residency_Status__c;
        
        System.Debug('CoursePreferenceCC:citizenFilter = ' + citizenFilter);

		String queryString = 'SELECT Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Academic_Year__c,Active__c,'
							+'Admission_Calendar_Description__c,Admission_Calendar_Type__c,Admission_Category__c,Admission_CI_Sequence_Number__c,'
							+'Attendance_Mode_Description__c,Attendance_Mode__c,Attendance_Type_Description__c,Attendance_Type__c,'
							+'Citizenship_Type__c,Course_Code__c,Course_Title__c,Course_Version_Number__c,Course_Type__c,'
							+'Course_Type_Group__c,Location_Description__c,Type_of_Place_Code__c,Type_of_Place_Description__c,'
							+'Faculty__c,Id,Location_Code__c,Name,Unit_Set_Code__c,Unit_Set_Description__c,Unit_Set_Version__c,Unique_Code__c '
							+'FROM Course_Offering__c '
							+'WHERE Active__c = True AND Citizenship_Type__c =:citizenFilter';

            				// OPG filter commented to allow both UG and PG
            				//AND Course_Type_Group__c = \''+POST_GRADUATE_FILTER+'\'';

		if(appCourseOfferingIds.size() >0){
			queryString += ' AND Id NOT IN:appCourseOfferingIds';
		}

		if(hasUnitSets){
			queryString += ' AND Unit_Set_Code__c != null';
		}

		if(searchStr != null && searchStr != ''){
			newSearchText = '%'+searchStr+'%';
			queryString += ' AND (Course_Code__c LIKE :newSearchText OR Course_Title__c LIKE :newSearchText)';
		}

		if(strAttType != null && strAttType != ''){
			queryString += ' AND Attendance_Type_Description__c =\''+strAttType+'\'';
		}

		if(strLocation != null && strLocation != ''){
			queryString += ' AND Location_Code__c =\''+strLocation+'\'';
		}
        
		else if(appCampusLocation != null && appCampusLocation != '')
		{
		    //queryString += ' AND Location_Code__c IN:arrLocations';
		    String queryCampus = makeCampusLocationClause(appCampusLocation);
            if(queryCampus != '')
            {
                queryString += ' AND ' + queryCampus;
            }
		}

		if(strPeriod != null && strPeriod != ''){
			searchByCommencePeriod = '%'+strPeriod+'%';
			queryString += ' AND Admission_Calendar_Description__c LIKE :searchByCommencePeriod';
		}

		queryString += ' ORDER BY Course_Code__c, Attendance_Type_Description__c, Admission_Calendar_Description__c,Unit_Set_Description__c';

		if(!hasUnitSets){
			queryString += ' LIMIT '+maxSize;
		}
        List<Course_Offering__c> courses = Database.query(queryString);
        QUERY_STRING = queryString;
        return courses;
        
    }

	@AuraEnabled
	public static Integer retrieveCoursesTotalRecord(String searchStr, String strCode, String strAttType, String strLocation, String strPeriod) {
		List<Course_Offering__c> courses = retrieveCourseOfferings(searchStr, strCode, strAttType, strLocation, strPeriod, false, null);

		Map<String, Course_Offering__c> mapCourse = new Map<String, Course_Offering__c>();
		for(Course_Offering__c course: courses){
			if(!mapCourse.containsKey(course.Unique_Code__c)){
				mapCourse.put(course.Unique_Code__c, course);
			}
		}

		return mapCourse.size();
	}

	@AuraEnabled
	public static List<Course_Offering__c> findCourses(String searchStr, String strCode, String strAttType, String strLocation, String strPeriod, Integer pagesize, Integer pagenumber) {
		//pagination variables
        Integer StartIndex, EndIndex ;
        StartIndex = (Integer.valueof(pagenumber) * Integer.valueof(pagesize)) + 1;
        EndIndex =  (Integer.valueof(pagesize) * (Integer.valueof(pagenumber) + 1));

		List<Course_Offering__c> courses = retrieveCourseOfferings(searchStr, strCode, strAttType, strLocation, strPeriod, false, null);

		Map<String, Course_Offering__c> mapCourse = new Map<String, Course_Offering__c>();
		for(Course_Offering__c course: courses){
			if(!mapCourse.containsKey(course.Unique_Code__c)){
				mapCourse.put(course.Unique_Code__c, course);
			}
		}

		List<Course_Offering__c> groupCourses = new List<Course_Offering__c>();
		if(courses != NULL && courses.size() > 0){
            Integer i = 1;
            for(Course_Offering__c temp : mapCourse.values()){
                if(i >= StartIndex && i <= EndIndex){
                    groupCourses.add(temp);
                    if(i==EndIndex){
                        break;
                    }
                }
                i++;
            }
        }

        System.debug('****COURSES: '+groupCourses);
		return groupCourses;
	}

	@AuraEnabled
	public static List<Course_Offering__c> retrieveCoursesWithUnitSets(String searchStr, String strCode, String strAttType, String strLocation, String strPeriod) {
		List<Course_Offering__c> courses = retrieveCourseOfferings(searchStr, strCode, strAttType, strLocation, strPeriod, true, null);

		System.debug('****COURSES WITH UNITS: '+courses);
		System.debug('****COURSES WITH UNITS: '+courses.size());
		return courses;
	}

	@AuraEnabled
	public static List<Application_Course_Preference__c> retrieveAppCourses(String appId) {
		List<Application_Course_Preference__c> appCourses = new List<Application_Course_Preference__c>();
		if(appId != null){
			appCourses = [SELECT Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Admission_Calendar_Type__c,
                        Admission_CI_Sequence_Number__c,Applicant__c,Application__c,Attendance_Type__c,Attendance_Mode_Description__c,
                        Commencement_Period__c,Attendance_Type_Description__c,Attendance_Mode__c,Type_of_Place_Description__c,
                        Course_Code__c,Course_Offering__c,Course_Title__c,Course_Version_Number__c,Course__c,CreatedDate,Id,
                        Location_Code__c,Name,Outcome_Status__c,Preference_Number__c,Status__c,Unit_Set_Code__c, Unit_Set_Description__c,
                        Offer_Response_Status__c,Offer_Condition__c, Offer_Date__c, Offer_Response_Date__c
                        FROM Application_Course_Preference__c
                        WHERE Application__c =:appId
                        ORDER BY Preference_Number__c ASC];
		}

		return appCourses;
	}

	@AuraEnabled
	public static List<Application_Course_Preference__c> reOrderAppCourses(String courseId, String direction) {
		List<Application_Course_Preference__c> appCourses = new List<Application_Course_Preference__c>();

		if(courseId != null){
			Application_Course_Preference__c appA = new Application_Course_Preference__c();
			appA = [SELECT Id, Preference_Number__c, Application__c FROM Application_Course_Preference__c WHERE Id=:courseId];
			Integer orderA = Integer.valueOf(appA.Preference_Number__c);
			Id appId = appA.Application__c;
			System.debug('****APP A: '+appA.Preference_Number__c);

			Application_Course_Preference__c appB = new Application_Course_Preference__c();
			Integer item = (direction == 'down')? orderA+1: orderA-1;
			appB = [SELECT Id, Preference_Number__c, Application__c FROM Application_Course_Preference__c WHERE Application__c=:appId AND Preference_Number__c=:String.valueof(item)];
			Integer orderB = Integer.valueOf(appB.Preference_Number__c);
			System.debug('****APP B: '+appB.Preference_Number__c);

			Integer updatedOrderA = (direction == 'down')? orderA+1: orderA-1;
			Integer updatedOrderB = (direction == 'down')? orderB-1: orderB+1;

			appA.Preference_Number__c = String.valueOf(updatedOrderA);
			appB.Preference_Number__c = String.valueOf(updatedOrderB);

			update appA;
			update appB;

			appCourses = CoursePreferenceCC.retrieveAppCourses(appId);
		}

		return appCourses;
	}

	@AuraEnabled
	public static List<Application_Course_Preference__c> addCourse(String jsonStr, String jsonStrUnitSets, String applicationId) {
		List<Application_Course_Preference__c> appCourses = new List<Application_Course_Preference__c>();

		//Deserialize to set of Ids
		Type idArrType = Type.forName('List<Id>');
    	List<Id> courseIds = (List<Id>) JSON.deserialize(jsonStr, idArrType);
    	System.debug('****SELECTED IDS: '+courseIds);

    	Type idArrType_UnitSets = Type.forName('List<Id>');
    	List<Id> courseIds_UnitSets = (List<Id>) JSON.deserialize(jsonStrUnitSets, idArrType_UnitSets);
    	System.debug('****SELECTED IDS WITH UNIT SETS: '+courseIds_UnitSets);

    	if(courseIds.size() >0 || courseIds_UnitSets.size() >0){
    		//List<Course_Offering__c> coursesToAdd = new List<Course_Offering__c>();

			//Map<String,Course_Offering__c> selectedCourses_NoUnitSets = new Map<String,Course_Offering__c>();
    		Map<String,List<Course_Offering__c>> selectedCourses_NoUnitSets = new Map<String,List<Course_Offering__c>>();

    		for(Course_Offering__c crs_NoSets: [SELECT Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Academic_Year__c,Active__c,
							Admission_Calendar_Description__c,Admission_Calendar_Type__c,Admission_Category__c,Admission_CI_Sequence_Number__c,
							Attendance_Mode_Description__c,Attendance_Mode__c,Attendance_Type_Description__c,Attendance_Type__c,
							Citizenship_Type__c,Commencement_Period__c,Course_Code__c,Course_Title__c,Course_Version_Number__c, Course_Type_Group__c,
							Location_Description__c,Type_of_Place_Code__c,Type_of_Place_Description__c,Unique_Code__c,
							Faculty__c,Id,Location_Code__c,Name,Unit_Set_Code__c,Unit_Set_Description__c,Unit_Set_Version__c
							FROM Course_Offering__c
							WHERE Id IN: courseIds]){

    			//selectedCourses_NoUnitSets.put(crs_NoSets.Unique_Code__c, crs_NoSets);
				List<Course_Offering__c> listOfCourseOfferingWithoutSets;
				if(selectedCourses_NoUnitSets.containsKey(crs_NoSets.Unique_Code__c))
					listOfCourseOfferingWithoutSets = selectedCourses_NoUnitSets.get(crs_NoSets.Unique_Code__c);
				else
					listOfCourseOfferingWithoutSets = new List<Course_Offering__c>();

				listOfCourseOfferingWithoutSets.add(crs_NoSets);
				selectedCourses_NoUnitSets.put(crs_NoSets.Unique_Code__c, listOfCourseOfferingWithoutSets);

    		}

    		Map<String,List<Course_Offering__c>> selectedCourses_WithUnitSets = new Map<String,List<Course_Offering__c>>();
    		for(Course_Offering__c crs_hasSets: [SELECT Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Academic_Year__c,Active__c,
							Admission_Calendar_Description__c,Admission_Calendar_Type__c,Admission_Category__c,Admission_CI_Sequence_Number__c,
							Attendance_Mode_Description__c,Attendance_Mode__c,Attendance_Type_Description__c,Attendance_Type__c,
							Citizenship_Type__c,Commencement_Period__c,Course_Code__c,Course_Title__c,Course_Version_Number__c, Course_Type_Group__c,
							Location_Description__c,Type_of_Place_Code__c,Type_of_Place_Description__c,Unique_Code__c,
							Faculty__c,Id,Location_Code__c,Name,Unit_Set_Code__c,Unit_Set_Description__c,Unit_Set_Version__c
							FROM Course_Offering__c
							WHERE Id IN: courseIds_UnitSets]){

    			//selectedCourses_WithUnitSets.put(crs_hasSets.Unique_Code__c, crs_hasSets);
				List<Course_Offering__c> listOfCourseOfferingWithSets;
				if(selectedCourses_WithUnitSets.containsKey(crs_hasSets.Unique_Code__c))
					listOfCourseOfferingWithSets = selectedCourses_WithUnitSets.get(crs_hasSets.Unique_Code__c);
				else
					listOfCourseOfferingWithSets = new List<Course_Offering__c>();

				//List<Course_Offering__c> listOfCourseOfferingWithSets = selectedCourses_WithUnitSets.get(crs_hasSets.Unique_Code__c);
				listOfCourseOfferingWithSets.add(crs_hasSets);
				selectedCourses_WithUnitSets.put(crs_hasSets.Unique_Code__c, listOfCourseOfferingWithSets);

    		}

    		//remove courses with no unit sets
	    	if(selectedCourses_WithUnitSets.size() >0){
	    		for(String crsKey: selectedCourses_WithUnitSets.keySet()){
	    			if(selectedCourses_NoUnitSets.containsKey(crsKey)){
	    				selectedCourses_NoUnitSets.remove(crsKey);
	    			}
	    		}

	    		for(String key: selectedCourses_NoUnitSets.keySet()){
	    			List<Course_Offering__c> courses = selectedCourses_NoUnitSets.get(key);
					for(Course_Offering__c course: courses){
	    				insertSelectedCourses(course, applicationId, false);
					}
	    		}

	    		for(String key: selectedCourses_WithUnitSets.keySet()){
	    			List<Course_Offering__c> courses = selectedCourses_WithUnitSets.get(key);
					for(Course_Offering__c course: courses){
	    				insertSelectedCourses(course, applicationId, true);
					}
	    		}

	    	}

	    	else{
	    		for(String key: selectedCourses_NoUnitSets.keySet()){
	    			List<Course_Offering__c> courses = selectedCourses_NoUnitSets.get(key);
					for(Course_Offering__c course: courses){
	    				insertSelectedCourses(course, applicationId, false);
					}
	    		}
	    	}



    	}

		appCourses = CoursePreferenceCC.retrieveAppCourses(applicationId);
		return appCourses;
	}

	private static void insertSelectedCourses(Course_Offering__c selectedCourse, String applicationId, Boolean hasUnitSet) {
		List<Application_Course_Preference__c> appCourses = new List<Application_Course_Preference__c>();

		Integer orderNumber = 1;
    	List<Application_Course_Preference__c> currentAppCourses = new List<Application_Course_Preference__c>();
    	currentAppCourses = CoursePreferenceCC.retrieveAppCourses(applicationId);
    	if(currentAppCourses.size() >0){
    		Integer listSize = currentAppCourses.size();
    		orderNumber = Integer.valueOf(currentAppCourses[listSize-1].Preference_Number__c)+1;
    	}

		Application_Course_Preference__c appCourse = new Application_Course_Preference__c();
		appCourse.Application__c = applicationId;
		appCourse.Applicant__c = userRecord.ContactId;
		appCourse.Status__c = 'Open';
		appCourse.Preference_Number__c = String.valueOf(orderNumber);
		appCourse.Academic_Calendar_Type__c = selectedCourse.Academic_Calendar_Type__c;
		appCourse.Academic_CI_Sequence_Number__c = selectedCourse.Academic_CI_Sequence_Number__c;
		appCourse.Admission_Calendar_Type__c = selectedCourse.Admission_Calendar_Type__c;
		appCourse.Admission_CI_Sequence_Number__c = selectedCourse.Admission_CI_Sequence_Number__c;
		appCourse.Attendance_Type__c = selectedCourse.Attendance_Type__c;
		appCourse.Attendance_Type_Description__c = selectedCourse.Attendance_Type_Description__c;
		appCourse.Commencement_Period__c = selectedCourse.Admission_Calendar_Description__c;
		appCourse.Course_Code__c = selectedCourse.Course_Code__c;
		appCourse.Course_Title__c = selectedCourse.Course_Title__c;
		appCourse.Course_Version_Number__c = selectedCourse.Course_Version_Number__c;
		appCourse.Location_Code__c = selectedCourse.Location_Code__c;
		appCourse.Location_Description__c = selectedCourse.Location_Description__c;
		appCourse.Attendance_Mode__c = selectedCourse.Attendance_Mode__c;
		appCourse.Attendance_Mode_Description__c = selectedCourse.Attendance_Mode_Description__c;
		appCourse.Type_of_Place_Code__c = selectedCourse.Type_of_Place_Code__c;
		appCourse.Type_of_Place_Description__c = selectedCourse.Type_of_Place_Description__c;

		appCourse.Course_Offering__c = selectedCourse.Id;
		appCourse.Unit_Set_Code__c = (hasUnitSet)? selectedCourse.Unit_Set_Code__c: '';
		appCourse.Unit_Set_Description__c = (hasUnitSet)? selectedCourse.Unit_Set_Description__c: '';
		appCourse.Unit_Set_Version__c = (hasUnitSet)? selectedCourse.Unit_Set_Version__c: 0.0;
        // Admission category and other status fields are set to default values for a2O POC. Design needs to be revisited
        // after the POC.
        // sf-2520 - changes made by nitin
        if (applicant.Residency_Status__c=='INTRNTNL'||applicant.Residency_Status__c=='INT-TEP'){
            appCourse.Admission_Category__c ='UG-IS';
           // appCourse.Outcome_Status__c = 'AP-PROGRES';
            appCourse.Outcome_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'AP-PROGRES' + Label.Application_Outcome_Status);
           // appCourse.Conditional_Offer_Status__c = 'NOT-APPLIC';
            appCourse.Conditional_Offer_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'NOT-APPLIC' + Label.Conditional_Offer_Status);
           // appCourse.Deferment_Status__c = 'NOT-APPLIC';
            appCourse.Deferment_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'NOT-APPLIC' + Label.Deferment_Status);
           // appCourse.Documentation_Status__c = 'PENDING';
            appCourse.Documentation_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'PENDING' + Label.Documentation_Status);
            //appCourse.Entry_Qualification_Status__c = 'PENDING';
            appCourse.Entry_Qualification_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'PENDING' + Label.Entry_Qualification_Status);
            appCourse.Fee_Category__c = 'AU_INT';
            //appCourse.Offer_Response_Status__c = 'NOT-APPLIC';
            appCourse.Offer_Response_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'NOT-APPLIC' + Label.Offer_Response_Status);
        }
		else
		{
            appCourse.Admission_Category__c = null;
                appCourse.Outcome_Status_LOV__r = null;
                appCourse.Conditional_Offer_Status_LOV__r = null;
                appCourse.Deferment_Status_LOV__r = null;
                appCourse.Documentation_Status_LOV__r = null;
                appCourse.Entry_Qualification_Status_LOV__r = null;
                appCourse.Fee_Category__c = null;
                appCourse.Offer_Response_Status_LOV__r=null;
		}
		//appCourses.add(appCourse);
		//orderNumber++;
		insert appCourse;
	}

	@AuraEnabled
    public static String deleteSelectedCourse (String deleteThisCourse, String applicationId) {
        String forDelete = '';
        if (String.isNotBlank(deleteThisCourse)) {
            List<Application_Course_Preference__c> courseToDelete = [SELECT Id FROM Application_Course_Preference__c
                                                                     WHERE Id =: deleteThisCourse
                                                                     AND applicant__c =: userRecord.ContactId
                                                                     LIMIT 1];
            if (!courseToDelete.isEmpty()) {
                //delete courseToDelete;
                // execute in delegated class (without sharing)
                DeleteAppCoursePreference deleteDelegate = new DeleteAppCoursePreference();
                deleteDelegate.run(courseToDelete);
            }
        }

        //Arrange the courses if 1 is deleted
        List<Application_Course_Preference__c> appCourses = new List<Application_Course_Preference__c>();
		if(applicationId != null){
			appCourses = [SELECT Id, Preference_Number__c
						FROM Application_Course_Preference__c
						WHERE Application__c =:applicationId
						ORDER BY Preference_Number__c ASC];
		}

		if(appCourses.size() >0){
			Integer orderNumber = 1;
			for(Application_Course_Preference__c appcrs: appCourses){
				appcrs.Preference_Number__c = String.valueOf(orderNumber);
				orderNumber++;
			}
			update appCourses;
		}

		return forDelete;
    }
   
    /*
     * @author       Stefan Scheit
     * @date         2018-09-15        
     * @description  Private inner class to break open without sharing for deletion of ACPs
     * @revision  	 1.0
     */
    private without sharing class DeleteAppCoursePreference {
        public void run(List<Application_Course_Preference__c> acpList) {
            delete acpList;
        }
    }

    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';
    public static String FIELD_USER = 'user';
    public static String FIELD_RESIDENCY_STATUS = 'residency_status';
    public static String FIELD_ACPS= 'acps';
    public static String FIELD_ATTENDANCE_TYPES = 'attendance_types';

    public static String FIELD_COURSE_LOCATIONS = 'course_locations';
    public static String FIELD_APPLICATION_CAMPUS_LOCATION = 'application_campus_location';
    
    private static String makeCampusLocationClause(String appCampusLocation)
    {
        String sQuery = '';
        if(appCampusLocation == 'Australia')
        {
            sQuery = ' Location_Code__c NOT IN (\'Malaysia\',\'SAfrica\') ';
        }
        else if(appCampusLocation == 'Malaysia')
        {
            sQuery = ' Location_Code__c IN (\'Malaysia\',\'Online\') ';
        }
        else if(appCampusLocation == 'South Africa')
        {
            sQuery = ' Location_Code__c IN (\'SAfrica\',\'Online\') ';
        }
        return sQuery;
    }

    @AuraEnabled public static Map<String, Object> getInitData(Id applicationId)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        // attendance types
        mapResults.put(FIELD_ATTENDANCE_TYPES, retrieveAttendanceType());

        // TODO - check security with current user access

        // get the Applicant
        mapResults.put(FIELD_USER, userRecord);

        //Contact conApplicant;
        if(userRecord.ContactId != NULL)
        {
            // residency status
            mapResults.put(FIELD_RESIDENCY_STATUS, applicant.Residency_Status__c);
        }


        
        if(applicationId != null)
        {
            UserRecordAccess ura = MyApplicationUtilities.getRecordAccessForUserByIds(applicationId, UserRecord.ContactId);
            //System.debug('appAddQualificationCC:: user access = ' + ura);
            if (ura == NULL || ura.HasReadAccess) {
                // get application
                List<Application__c> listApps = [SELECT Id, Campus_Location__c
                FROM Application__c
                WHERE Id =: applicationId
                ];
    
                Application__c app = listApps[0];
                String campusLocation = app.Campus_location__c;
                // course location map
                mapResults.put(FIELD_APPLICATION_CAMPUS_LOCATION, campusLocation);
            }
        }

        // ACPS
        List<Application_Course_Preference__c> acps = retrieveAppCourses(applicationId);
        mapResults.put(FIELD_ACPS, acps);



        return mapResults;
    }

    public static String FIELD_QUERY = 'query';
    public static String FIELD_COURSES = 'courses';
    public static String FIELD_TOTAL_COURSES = 'total_courses';
    public static String FIELD_COURSE_UNITS = 'course_units';
    public static String FIELD_COMMENCEMENT_PERIODS = 'commencement_periods';

    
    @AuraEnabled public static Map<String, Object> getCourseOfferings(String searchStr,
                                                                      String strCode,
                                                                      String strAttType,
                                                                      String strLocation,
                                                                      String strPeriod,
                                                                      Integer pagesize,
                                                                      Integer pagenumber,
                                                                      String appCampusLocation)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        List<Course_Offering__c> courses = retrieveCourseOfferings(searchStr, strCode, strAttType, strLocation, strPeriod, false, appCampusLocation);
        mapResults.put(FIELD_QUERY, QUERY_STRING);
        Map<String, Course_Offering__c> mapCourse = getUniqueCourses(courses);

        // retrieveLocation()
        mapResults.put(FIELD_COURSE_LOCATIONS, getUniqueCourseLocations(courses));

        // commencement periods
        mapResults.put(FIELD_COMMENCEMENT_PERIODS, getStartingDates(courses));

        // retrieveCoursesTotalRecord()
        mapResults.put(FIELD_TOTAL_COURSES, mapCourse.size());

        // findCourses()
        mapResults.put(FIELD_COURSES, getPageOfCourses(mapCourse, pagesize, pagenumber));

        // retrieveCoursesWithUnitSets()
        mapResults.put(FIELD_COURSE_UNITS, retrieveCoursesWithUnitSets(searchStr, strcode, strAttType, strLocation, strPeriod));

		Integer StartIndex = (Integer.valueof(pagenumber) * Integer.valueof(pagesize));
		Integer EndIndex =  (Integer.valueof(pagesize) * (Integer.valueof(pagenumber) + 1));
		mapResults.put('startIndex', StartIndex);
		mapResults.put('endIndex', EndIndex);

        return mapResults;
    }


    private static Map<String, Course_Offering__c> getUniqueCourses(List<Course_Offering__c> courses)
    {
        Map<String, Course_Offering__c> mapCourse = new Map<String, Course_Offering__c>();
		for(Course_Offering__c course: courses){
			if(!mapCourse.containsKey(course.Unique_Code__c)){
				mapCourse.put(course.Unique_Code__c, course);
			}
		}
		return mapCourse;
    }

    private static List<Course_Offering__c> getPageOfCourses(Map<String, Course_Offering__c> mapCourse,
    Integer pagesize,
    Integer pagenumber)
    {
        //pagination variables
        Integer StartIndex = (Integer.valueof(pagenumber) * Integer.valueof(pagesize));
        Integer EndIndex =  (Integer.valueof(pagesize) * (Integer.valueof(pagenumber) + 1));


        List<Course_Offering__c> courseValues = mapCourse.values();
		if(EndIndex > courseValues.size())
			EndIndex = courseValues.size();
		List<Course_Offering__c> groupCourses = new List<Course_Offering__c>();
        Integer i = 0;
        for(Course_Offering__c c:courseValues)
        {
            if(i >= StartIndex)
            {
                groupCourses.add(c);
            }
			++i;
			if(i == EndIndex)
				break;
        }
        return groupCourses;
    }


    private static List<String> getUniqueCourseLocations(List<Course_Offering__c> courses) {

        Set<String> courseLocations = new Set<String>();
        for(Course_Offering__c co : courses)
        {
            courseLocations.add(co.Location_Code__c);
        }

        List<String> sortedLocations = new List<String>(courseLocations);
        sortedLocations.sort();
        return sortedLocations;
    }


    public static List<String> getStartingDates(List<Course_Offering__c> courses)
    {
        Set<String> startingPeriods = new Set<String>();
        for(Course_Offering__c co : courses)
        {
            startingPeriods.add(co.Admission_Calendar_Description__c);
        }
        List<String> sortedPeriods = new List<String>(startingPeriods);
        sortedPeriods.sort();
        return sortedPeriods;
    }

}