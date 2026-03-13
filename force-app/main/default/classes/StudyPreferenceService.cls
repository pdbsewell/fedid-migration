/*******************************************************************************
* @author       Shalini Mendu
* @date
* @description  Handles the search criteria for the course offering which is used on my.app
* @revision
* 12.Aug.2019 - Shalini Mendu - SFTN-148 updates and code comments
* 01.Apr.2021 - Vinothraja - SFTG-1898 - added wrapper class to fetch application
* 21.Apr.2021 - Vinothraja - SFTG-1945 - Added logic to restrict coursework search results
* 30.Nov.2021 - Kristian Vegerano - SFTG-2326 - excluded location codes for australia campus location
* 23.Jul.2024 - Davey Yu - MGROI-322 - Exclude HDR course type group in course offerings
*******************************************************************************/
public with sharing class StudyPreferenceService  {

    public static String FIELD_CONTACT_ID = 'contactId';
    public static String FIELD_CONTACT = 'contact';
    public static String FIELD_USER = 'user';
    public static String FIELD_APPLICATION = 'application';
    public static String FIELD_APPLICATION_CREATEDBY = 'appCreatedBy';

    public static String FIELD_ACPS = 'acps';

    public static String FIELD_ATTENDANCE_TYPES = 'attendanceTypes';
    public static String FIELD_LOCATIONS = 'locations';
    public static String FIELD_COURSE_STARTS = 'courseStarts';
    public static String FIELD_COURSE_TYPES = 'courseTypes';
    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';

    public static String FIELD_COURSE_CODE = 'Course_Code__c';
    public static String FIELD_COURSE_TITLE = 'Course_Title__c';

    // used in the unit set search
    public static String FIELD_OFFERINGS_BY_COURSE_CODE = 'offeringsByCourseCode';
    public static String FIELD_MAP_COURSE_CODE = 'courseCode';
    //public static String FIELD_UNIT_SET_CODE = 'unitSetCode';
    public static String FIELD_HAS_UNIT_SETS = 'hasUnitSets';
    //public static String FIELD_OFFERINGS_BY_UNIT_SET = 'offeringsByUnitSet';
    public static String FIELD_OFFERINGS = 'offerings';
    public static String UNIT_OFFERINGS_METADATA = 'Unit Offerings Mapping';
    public static String ADM_1 = 'ADM-1';
    public static String ADM_2 = 'ADM-2';
    //Campus locations
    public static String malaysia = 'Malaysia';
    public static String SAfrica = 'SAfrica';
    public static String indonesia = 'Indonesia';
    public static String MCJAKARTA = 'MC-JAKARTA';
    public static String online = 'ONLINE';
    public static String PRATO = 'PRATO';
    public static String ONLINEA = 'ONLINE-A'; 
    //Course types
    public static String mufy = 'MUFY-%';
    public static String os = 'OS-%';
    public static Set<String> locations = new Set<String>();
    //allow ON/COMPOSITE as the unit modes 
    public static Set<String>  unitMode = new Set<String>{'ON','COMPOSITE'};

    
    private static User getCurrentUser() {
        List<User> listUsers = [
                                   SELECT
                                   ProfileId,
                                   ContactId,
                                   App_Previously_Studied_at_Monash__c,
                                   App_Residency_Status__c
                                   FROM User
                                   WHERE Id = :UserInfo.getUserId()
                               ];

        //System.Debug('StudyPreferenceService::getCurrentUser:' + listUsers);
        return listUsers[0];
    }

    @AuraEnabled
    public static Map<String, Object> getCourseSearchInitLoad(Id appId) {
        Map<String, Object> mapResults = new Map<String, Object>();

        // user
        User currUser = getCurrentUser();
        mapResults.put(FIELD_USER, currUser);

        // contact
        Id contactId = currUser.ContactId;
        mapResults.put(FIELD_CONTACT_ID, contactId);


        if (contactId != null) {
            List<Contact> contacts = [
                                         SELECT Id, Residency_Status__c
                                         FROM Contact
                                         WHERE Id = :contactId
                                     ];
            mapResults.put(FIELD_CONTACT, contacts[0]);
        }

        // application
        if (appId != null) {
            UserRecordAccess ura = MyApplicationUtilities.getRecordAccessForUserByIds(appId, contactId);
            //System.debug('appAddQualificationCC:: user access = ' + ura);
            if (ura == NULL || ura.HasReadAccess) {
                // get application
                appApplicationWrapper aaw = new appApplicationWrapper().getApplication(appId);
                // course location map
                mapResults.put(FIELD_APPLICATION, aaw.app);
                mapResults.put(FIELD_APPLICATION_CREATEDBY, aaw.strCreatedBy);

                List<Application_Course_Preference__c> acps = getACPs(appId);
                mapResults.put(FIELD_ACPS, acps);
            }
        }

        return mapResults;
    }

    private static List<Application_Course_Preference__c> getACPs(Id appId) {
        List<Application_Course_Preference__c> appCourses = new List<Application_Course_Preference__c>();
        if (appId != null) {
            appCourses = [
                             SELECT
                             Id, Preference_Number__c, Unit_Set_Description__c,Course_Offering__r.Location_Code__c,
                             Course_Title__c, Course_Code__c, Attendance_Type_Description__c,
                             Attendance_Mode_Description__c, Type_of_Place_Description__c,Course_Offering__r.Start_Date__c,
                             Location_Code__c, Commencement_Period__c, Course_Offering__c, Course_Offering__r.Active__c,
                             Calendar_Code__r.Type__c, Calendar_Code__r.Year__c, Application__r.Campus_Location__c 
                             /*Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Admission_Calendar_Type__c,
                             Admission_CI_Sequence_Number__c,Applicant__c,Application__c,Attendance_Type__c,Attendance_Mode_Description__c,
                             Commencement_Period__c,Attendance_Type_Description__c,Attendance_Mode__c,Type_of_Place_Description__c,
                             Course_Code__c,Course_Offering__c,Course_Title__c,Course_Version_Number__c,Course__c,CreatedDate,Id,
                             Location_Code__c,Name,Outcome_Status__c,Preference_Number__c,Status__c,Unit_Set_Code__c, Unit_Set_Description__c,
                             Offer_Response_Status__c,Offer_Condition__c, Offer_Date__c, Offer_Response_Date__c
                             */
                             FROM Application_Course_Preference__c
                             WHERE Application__c = :appId
                                                    ORDER BY Preference_Number__c ASC
                         ];
        }

        return appCourses;
    }
    /*******************************************************************************
    * @author       Shalini Mendu
    * @date
    * @description  The server method which gets called from the aura component that searches for the courses
    * @revision  12.Aug.2019 - Shalini Mendu - SFTN-148 updates
    *******************************************************************************/
    @AuraEnabled
    public static List<Map<String, String>> searchCourses(String searchString, String campusLocation, String citizenshipType, String studyType) {
       
        List<String> listTokens = String.escapeSingleQuotes(searchString).trim().split(' ');
        //SA Course titles
        String saTitle = CONSTANTS.MONASH_ABROAD_SA_COURSE_TITLE+'%';
        String saUGCourseCode = CONSTANTS.MONASH_ABROAD_SA_COURSE_UG_CODE+'%';
        String exchgTitle = CONSTANTS.MONASH_ABROAD_EX_COURSE_TITLE+'%';
        String exchgUGCourseCode = CONSTANTS.MONASH_ABROAD_EX_COURSE_UG_CODE+'%';
        String courseTypeHDR = CONSTANTS.COURSETYPE_GROUP_HDR;
    
      
        //Excluded admission categories for the oes courses - SFTD-517 - temporarily hard coded exclusion of the admission categories to hit the timeframe, would be revisited for a better solution
        Set<String> excludedAdmissionCategories = new Set<String>();
        excludedAdmissionCategories.add('OES-PG-DOM');
        excludedAdmissionCategories.add('OES-PG-IS');
        excludedAdmissionCategories.add('OES-SSPG-D');
        excludedAdmissionCategories.add('OES-SSPG-I');
        List<String> studyAbroadCourseCodes = new List<String>();
        List<String> exchangeCourseCodes = new List<String>();
        String strWhereClause ='';
        // the order of results
        List<Map<String, String>> searchResults = new List<Map<String, String>>();
        
        // construct the search string
        // Updated by DYU 22/07/24 MGROI-322 Exclude HDR course offering in My App Coursework
        strWhereClause += '  Portal_Available__c=true AND Default_Admission_Category_Ind__c= true AND Active__c = TRUE AND Course_Type_Group__c != :courseTypeHDR ';
        // if the application campus location is online, ignore the citizenship type of the applicant (Application__c.Residency_Status__c)
        if(campusLocation != 'Online'){
            strWhereClause += ' AND Citizenship_Type__c = :citizenshipType';
        }
        strWhereClause += makeCampusLocationClause(campusLocation);
    
        String tokenFormatted = '';
        for (String sToken : listTokens) {
            tokenFormatted += '%' + sToken;
        }
        // append a trailing % if tokens are available
        if (tokenFormatted != '') {
            tokenFormatted =  tokenFormatted + '%';
            strWhereClause += ' AND(Course_Code__c LIKE :tokenFormatted';
            //sQuery += ' OR Unit_Set_Description__c LIKE tokenFormatted;
            strWhereClause += ' OR Course_Title__c LIKE :tokenFormatted )';
        }
     
        if (studyType == CONSTANTS.MONASH_ABROAD_SA_STUDY_TYPE) {//Study Abroad
            strWhereClause += ' AND  (Course_Title__c LIKE :saTitle OR Course_Code__c LIKE :saUGCourseCode )' ;
            // show only relevant study abroad course codes
            if(campusLocation != online){
                studyAbroadCourseCodes.add('7001');
                studyAbroadCourseCodes.add('7002');
            }else{
                studyAbroadCourseCodes.add('7003');
                studyAbroadCourseCodes.add('7004');
            }
            System.debug('studyAbroadCourseCodes=='+studyAbroadCourseCodes);
            strWhereClause += ' AND (Course_Code__c IN :studyAbroadCourseCodes)' ;
        } else if (studyType == CONSTANTS.MONASH_ABROAD_EX_STUDY_TYPE) {//Exchange
            strWhereClause += '  AND (Course_Title__c LIKE :exchgTitle OR Course_Code__c LIKE :exchgUGCourseCode )' ;
            // show only relevant exchange course codes
            if(campusLocation != online){
                exchangeCourseCodes.add('8001');
                exchangeCourseCodes.add('8002');
            }else{
                exchangeCourseCodes.add('8003');
                exchangeCourseCodes.add('8004');
            }
            strWhereClause += ' AND (Course_Code__c IN :exchangeCourseCodes)' ;
        } else { // SFTG-1945 - Restricts Coursework results from displaying Study Abroad or Exchange Courses
            strWhereClause += ' AND (NOT Course_Title__c LIKE :saTitle) AND (NOT Course_Code__c LIKE  :saUGCourseCode ) ' ;
            strWhereClause += ' AND (NOT Course_Title__c LIKE :exchgTitle) AND (NOT Course_Code__c LIKE  :exchgUGCourseCode ) ' ;            
        }
        strWhereClause += ' GROUP BY Course_Code__c, Course_Title__c';
        //Build SOQL using DynamicSoqlBuilder
        String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
        .showSOQLStatement(true)
        .setEnforced(false)
        .querySObject('Course_Offering__c')
        .queryFields(new Set<String> { 'Course_Code__c' ,'Course_Title__c'})
        .getQuery(strWhereClause);
        system.debug('NS*** '+dynamicSearchQuery);
        List<AggregateResult> searchAggregate = Database.query(dynamicSearchQuery);
        Set<String> uniqueCodes = new Set<String>();
        for (AggregateResult ag : searchAggregate) {
            String courseCode = (String) ag.get(FIELD_COURSE_CODE);
            String courseTitle = (String) ag.get(FIELD_COURSE_TITLE);
    
            if (!uniqueCodes.contains(courseCode)) {
                // add to the list of results, if new
                Map<String, String> objCourse = new Map<String, String>();
                objCourse.put(FIELD_COURSE_CODE, courseCode);
                objCourse.put(FIELD_COURSE_TITLE, courseTitle);
                searchResults.add(objCourse);
            }
            uniqueCodes.add(courseCode);
        }
		
        return searchResults;
       
    }

    public static String makeCampusLocationClause(String appCampusLocation) {
        String sQuery = '';
        //Populate locations 
        locations.add(malaysia);
        locations.add(SAfrica);
        locations.add(indonesia);
        locations.add(MCJAKARTA);
        locations.add(online);
        locations.add(PRATO);
        locations.add(ONLINEA);
        if (appCampusLocation == 'Australia') {
            //SFTG-2326 - exclude the following course offering location codes from australian campus location
            //INDONESIA, MC-JAKARTA, ONLINE, PRATO
            //All course offerings with location code starting with OS- and MUFY-
            sQuery = ' AND (NOT Location_Code__c IN :locations) AND (NOT Location_Code__c LIKE :mufy) AND (NOT Location_Code__c LIKE :os) ';
        } else if (appCampusLocation == malaysia) {
            sQuery = ' AND Location_Code__c = :malaysia ';
        } else if (appCampusLocation == SAfrica) {
            sQuery = ' AND Location_Code__c IN (:SAfrica,:online) ';
        } else if (appCampusLocation == online) {
            sQuery = ' AND Location_Code__c IN (:online) ';
        } else if (appCampusLocation == indonesia) { //SFTG-2824 Included Indonesia Location
            sQuery = ' AND Location_Code__c IN (:indonesia) ';
        }
        return sQuery;
    }


    private static List<Course_Offering__c> queryCourseOfferings(List<String> courseCodes, String campusLocation, String citizenshipType, Boolean hasUnitSets)
    {
        String sQuery = 'SELECT Id,';
        sQuery += 'Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Academic_Year__c,Active__c,Admission_Calendar_Description__c, Start_Date__c,';
        sQuery += 'Admission_Calendar_Type__c,Admission_Category__c,Admission_CI_Sequence_Number__c,';
        sQuery += 'Attendance_Mode_Description__c,Attendance_Mode__c,Attendance_Type_Description__c,Attendance_Type__c,';
        sQuery += 'Citizenship_Type__c,Course_Code__c,Course_Title__c,Course_Version_Number__c,Course_Type__c,';
        sQuery += 'Course_Type_Group__c,Location_Description__c,Type_of_Place_Code__c,Type_of_Place_Description__c,';
        sQuery += 'Faculty__c, Location_Code__c,Name,Unit_Set_Code__c,Unit_Set_Description__c,Unit_Set_Version__c,Unique_Code__c';
        sQuery += ' FROM Course_Offering__c';

        sQuery += ' WHERE Active__c = TRUE AND Portal_Available__c=true AND Default_Admission_Category_Ind__c= true';
        sQuery += ' AND Course_Code__c IN: courseCodes';
        // if the application campus location is online, ignore the citizenship type of the applicant (Application__c.Residency_Status__c)
        if(campusLocation != 'Online'){
            sQuery += ' AND Citizenship_Type__c = :citizenshipType';
        }
        if(hasUnitSets)
        {
            sQuery += ' AND Unit_Set_Code__c != null';
        }
        else
        {
            sQuery += ' AND Unit_Set_Code__c = null';
        }
        sQuery += makeCampusLocationClause(campusLocation);
        sQuery += ' ORDER BY Course_Code__c, Type_of_Place_Description__c, Unit_Set_Code__c, Admission_Calendar_Description__c';

        // all course offerings
        List<Course_Offering__c> searchResults = Database.query(sQuery);
        return searchResults;

    }

    @AuraEnabled
    public static Map<String, Object> searchCourseOfferingsByCourseCode(List<String> courseCodes, String campusLocation, String citizenshipType)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        // standalone offerings
        List<Course_Offering__c> offeringsStandalone = queryCourseOfferings(courseCodes, campusLocation, citizenshipType, false);


        // unit sets
        List<Course_Offering__c> offeringsUnitSets = queryCourseOfferings(courseCodes, campusLocation, citizenshipType, true);

        // concatenate to get the distincts
        List<Course_Offering__c> offeringsAll = new List<Course_Offering__c>();
        offeringsAll.addAll(offeringsStandalone);
        offeringsAll.addAll(offeringsUnitSets);

        // course start options
        List<Map<String, String>> courseStartOptions = distinctCourseStarts(offeringsAll);
        mapResults.put(FIELD_COURSE_STARTS, courseStartOptions);

        // return a list in the following format
        /*
        [
            { 'courseCode': '1234',
                'hasUnitSets' :true/false,
                'offerings': []
            }
        ]
         */
        List<Map<String, Object>> offeringsResult = new List<Map<String, Object>> ();

        // use a map to group by CourseCode_UnitSet, this map is not returned
        Map<String, List<Course_Offering__c>> uniqueOfferingGroups = new Map<String, List<Course_Offering__c>>();
        // add all the stand alones
        for(Course_Offering__c co:offeringsStandalone)
        {
            List<Course_Offering__c> offerings = uniqueOfferingGroups.get(co.Course_Code__c);
            if(null == offerings)
            {
                offerings = new List<Course_Offering__c>();
                uniqueOfferingGroups.put(co.Course_Code__c, offerings);

                // map for Course Code
                Map<String, Object> mapForCourseCode = new Map<String, Object> ();
                mapForCourseCode.put(FIELD_MAP_COURSE_CODE, co.Course_Code__c);
                mapForCourseCode.put(FIELD_HAS_UNIT_SETS, false);
                mapForCourseCode.put(FIELD_OFFERINGS, offerings);

                offeringsResult.add(mapForCourseCode);
            }
            offerings.add(co);
        }

        // add all the unit set ones
        for(Course_Offering__c co:offeringsUnitSets)
        {
            List<Course_Offering__c> offerings = uniqueOfferingGroups.get(co.Course_Code__c);

            if(offerings == null)
            {
                offerings = new List<Course_Offering__c>();
                uniqueOfferingGroups.put(co.Course_Code__c, offerings);

                // map for Course Code
                Map<String, Object> mapForCourseCode = new Map<String, Object> ();
                mapForCourseCode.put(FIELD_MAP_COURSE_CODE, co.Course_Code__c);
                mapForCourseCode.put(FIELD_HAS_UNIT_SETS, true);
                mapForCourseCode.put(FIELD_OFFERINGS, offerings);

                offeringsResult.add(mapForCourseCode);
            }
            offerings.add(co);
        }

        mapResults.put(FIELD_OFFERINGS_BY_COURSE_CODE, offeringsResult);

        return mapResults;
    }




    private static Map<String, String> makeOption(String value, String label)
    {
        Map<String, String> option = new Map<String, String>();
        option.put(FIELD_VALUE, value);
        option.put(FIELD_LABEL, label);

        return option;
    }

    /* - unused
    public static List<Map<String, String>> distinctAttendanceOptions(List<Course_Offering__c> courseOfferings)
    {
        Set<String> setDistinct = new Set<String> ();
        for(Course_Offering__c co: courseOfferings)
        {
            setDistinct.add(co.Attendance_Type__c);
        }
        List<String> listDistinct = new List<String>(setDistinct);
        listDistinct.sort();

        List<Map<String, String>> options = new List<Map<String, String>>();

        for(String distinctVal:listDistinct)
        {
            options.add(makeOption(distinctVal, distinctVal));
        }
        return options;
    }


    private static List<Map<String, String>> distinctLocations(List<Course_Offering__c> courseOfferings)
    {
        Set<String> setDistinct = new Set<String> ();
        for(Course_Offering__c co: courseOfferings)
        {
            setDistinct.add(co.Location_Code__c);
        }

        List<String> listDistinct = new List<String>(setDistinct);
        listDistinct.sort();

        List<Map<String, String>> options = new List<Map<String, String>>();

        for(String distinctVal:listDistinct)
        {
            options.add(makeOption(distinctVal, distinctVal));
        }
        return options;
    }
    */

    private static List<Map<String, String>> distinctCourseStarts(List<Course_Offering__c> courseOfferings)
    {
        Set<String> setDistinct = new Set<String> ();
        for(Course_Offering__c co: courseOfferings)
        {
            setDistinct.add(co.Admission_Calendar_Description__c);
        }
        List<String> listDistinct = new List<String>(setDistinct);
        listDistinct.sort();

        List<Map<String, String>> options = new List<Map<String, String>>();

        for(String distinctVal:listDistinct)
        {
            options.add(makeOption(distinctVal, distinctVal));
        }
        return options;
    }


    @AuraEnabled
    public static Map<String, Object> addACPs(List<Id> courseOfferingIds, Id appId)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        // calculate the offset
        List<Application_Course_Preference__c> existingACPs = getACPs(appId);
        Integer orderNumber = 1;
        if(existingACPs.size() > 0)
        {
            orderNumber = existingACPs.size() + 1;
        }


        // User/contact Id
        User currUser = getCurrentUser();
        Id contactId = currUser.ContactId;
        Contact applicant = [SELECT Id, Residency_Status__c FROM Contact WHERE Id =: contactId];

        // get the reference course offerings
        List<Course_Offering__c> offerings = [SELECT Id, Academic_Calendar_Type__c, Academic_CI_Sequence_Number__c,
                                                     Admission_Calendar_Type__c, Admission_CI_Sequence_Number__c, Attendance_Type__c, Attendance_Type_Description__c,
                                                     Admission_Calendar_Description__c, Course_Code__c, Course_Title__c, Course_Version_Number__c, Location_Code__c,
                                                     Location_Description__c, Attendance_Mode__c, Attendance_Mode_Description__c, Type_of_Place_Code__c,
                                                     Type_of_Place_Description__c, Unit_Set_Code__c, Unit_Set_Description__c, Unit_Set_Version__c
                                                     FROM Course_Offering__c
                                                     WHERE Id IN : courseOfferingIds];

        Application__c applicationRecord = [SELECT Id, Applicant__c FROM Application__c WHERE Id = :appId];

        List<Application_Course_Preference__c> acpsToAdd = new List<Application_Course_Preference__c>();
        for(Course_Offering__c selectedCourse:offerings)
        {
            Application_Course_Preference__c appCourse = new Application_Course_Preference__c();
            appCourse.Application__c = appId;
            appCourse.Applicant__c = applicationRecord.Applicant__c;
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

            Boolean hasUnitSet = false;
            if(selectedCourse.Unit_Set_Code__c != null)
            {
                hasUnitSet = true;
            }

            appCourse.Unit_Set_Code__c = (hasUnitSet)? selectedCourse.Unit_Set_Code__c: '';
            appCourse.Unit_Set_Description__c = (hasUnitSet)? selectedCourse.Unit_Set_Description__c: '';
            appCourse.Unit_Set_Version__c = (hasUnitSet)? selectedCourse.Unit_Set_Version__c: null;
            // Admission category and other status fields are set to default values for a2O POC. Design needs to be revisited
            // after the POC.
            //  sf-2520 - changes made by nitin
            if (applicant.Residency_Status__c=='INTRNTNL'||applicant.Residency_Status__c=='INT-TEP') {
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

            acpsToAdd.add(appCourse);

            orderNumber++;
        }


        if(acpsToAdd.size() > 0) {
            insert acpsToAdd;
        }

        // refresh the ACPS list
        List<Application_Course_Preference__c> acps = getACPs(appId);
        mapResults.put(FIELD_ACPS, acps);

        return mapResults;
    }

    @AuraEnabled
    public static Map<String, Object> removeACP(Id acpId, Id appId)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        List<Application_Course_Preference__c> toDelete = [SELECT Id FROM Application_Course_Preference__c
                       WHERE Id =: acpId];
        delete toDelete;

        // refresh the ACPS list and preference numbers
        List<Application_Course_Preference__c> acps = getACPs(appId);
        Integer index = 1;
        for(Application_Course_Preference__c acp:acps)
        {
            acp.Preference_Number__c = String.valueOf(index);
            index++;
        }
        if(acps.size() > 0)
        {
            update acps;
        }
        mapResults.put(FIELD_ACPS, acps);

        return mapResults;
    }

    @AuraEnabled
    public static Map<String, Object> updateACPOrder(Id acpId, Boolean moveUp, Id appId)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        // refresh the ACPS list and preference numbers
        List<Application_Course_Preference__c> acps = getACPs(appId);
        for(Integer i = 0; i < acps.size(); ++i)
        {
            Application_Course_Preference__c acpToMove = acps[i];
            if(acpToMove.Id == acpId)
            {
                Application_Course_Preference__c acpToSwap;
                if(moveUp)
                {
                    // swap with PREVIOUS
                    acpToSwap = acps[i - 1];
                }
                else
                {
                    // swap with the NEXT one
                    acpToSwap = acps[i + 1];
                }

                Integer iToMove = Integer.valueOf(acpToMove.Preference_Number__c);
                Integer iToSwap = Integer.valueOf(acpToSwap.Preference_Number__c);

                acpToSwap.Preference_Number__c = String.valueOf(iToMove);
                acpToMove.Preference_Number__c = String.valueOf(iToSwap);
                break;
            }
        }
        if(acps.size() > 0)
        {
            update acps;
        }

        // get the new ordered options
        acps = getACPs(appId);
        mapResults.put(FIELD_ACPS, acps);

        return mapResults;
    }


    @AuraEnabled
    public static Map<String, Object> PauseForScroll()
    {
        Map<String, Object> mapResults = new Map<String, Object>();
        return mapResults;
    }
    /**
    * @date March 2021
    * @description -update study duration on Application record
    */
    @AuraEnabled
    public static void updateStudyDuration(String duration, String appId)
    {
        List<Application__c> appList = [Select Id,Duration_of_Study__c from Application__c where id=:appId];
        if(!appList.isEmpty())
        {
            appList[0].Duration_of_Study__c = duration;
        }

        update appList;
    }

   /**
    * @date March 2021
    * @description - search Unit offerings with the keyword
    */
    @AuraEnabled(cacheable=false)
    public static Map<String,Object> searchUnitOfferings(Integer offsetRange, Id appId, String unitCodeorTitle, String faculty, Integer numSemesters, List<String> excludedIds)
    {  //UG/PG - Unit levels for filtering
        Set<String> UG_UNIT_LEVELS = new Set<String>{'1','2','3','4'};
        Set<String> PG_UNIT_LEVELS = new Set<String>{'4','5','9'};
        String selectedUnitCodeorTitle = '%'+String.escapeSingleQuotes(unitCodeorTitle)+'%';
        String caulfieldCampus = 'CAULFIELD';
        String claytonCampus = 'CLAYTON';
  
        Map<String,Object> retMap = new Map<String, Object>();
        try {
            List<Application_Course_Preference__c> acps = getACPs(appId);
            List<Id> acpIds = new List<Id>();
            for(Application_Course_Preference__c acp:acps )
            {
                acpIds.add(acp.Id);
            }

            List<Application_Course_Preference__c> acpList = [SELECT Application__r.Campus_Location__c,Calendar_Code__r.Type__c, Calendar_Code__r.Year__c,Course_Offering__r.Start_Date__c, Course_Offering__r.Location_Code__c, 
                                                                     Course_Offering__r.Course_Code__c,Application__r.Duration_of_Study__c
                                                              FROM Application_Course_Preference__c
                                                              WHERE Id IN :acpIds];
            String admCalType =  acpList[0].Calendar_Code__r.Type__c;
            List<String> tpList = retrieveUnitOfferingsTP(admCalType,  acpList[0].Calendar_Code__r.Year__c, acpList[0].Application__r.Duration_of_Study__c);
            String courseCampusLoc = acpList[0].Course_Offering__r.Location_Code__c;
            String applicationCampusLocation = acpList[0].Application__r.Campus_Location__c;
            
            // retrieve all virtual available unit offerings for online applications
            Set<String> unitOfferingCodes = new Set<String>();
            if(applicationCampusLocation == 'Online'){
                unitOfferingCodes = retrieveCourseToUnitOfferingMap(acpList[0].Course_Offering__r.Course_Code__c);
            }
            String strWhereClause = ' Unit_Mode__c IN :unitMode' + ' AND Id NOT IN :excludedIds AND Offered_Ind__c=TRUE AND Active_Ind__c=TRUE AND SSF_Avail_Ind__c=TRUE';
            if(applicationCampusLocation != 'Online')
               strWhereClause += ' AND  Calendar__r.Name =:tpList ';
            if(applicationCampusLocation == 'Online' && unitCodeorTitle.equalsIgnoreCase('virtual')){
                strWhereClause += ' AND Unit_Code__c IN :unitOfferingCodes ';
            }else{
                strWhereClause += ' AND ( Title__C like :selectedUnitCodeorTitle  OR Unit_Code__c like :selectedUnitCodeorTitle )';
            }

            // filter the unit codes based off the course offering course code
            // based from the Available Virtual Course Units
            if(applicationCampusLocation == 'Online'){
                if(unitOfferingCodes != null){
                    strWhereClause += ' AND Unit_Code__c IN :unitOfferingCodes';
                }
            }else{
                //For UG courses, filter to show only UG and similarly for PG courses
                if(acpList[0].Course_Offering__r.Course_Code__c ==  Constants.MONASH_ABROAD_SA_COURSE_UG_CODE ||
                acpList[0].Course_Offering__r.Course_Code__c == Constants.MONASH_ABROAD_EX_COURSE_UG_CODE)
                {
                    strWhereClause+= ' AND Unit_Level__c = :UG_UNIT_LEVELS';
                }else{
                    strWhereClause+= ' AND Unit_Level__c = :PG_UNIT_LEVELS';
               } 

                if(courseCampusLoc == 'CLAYTON' || courseCampusLoc =='CAULFIELD')
                {
                    strWhereClause+= ' AND (Location__c=:claytonCampus OR Location__c=:caulfieldCampus)';
                } else {
                    strWhereClause+= ' AND Location__c=:courseCampusLoc';
                }
            }

            if(faculty!=null && faculty.length()>0)
            {
                strWhereClause+= ' AND Managing_Faculty_Name__c=:faculty';
            }
            //Build SOQL using DynamicSoqlBuilder
            String dynamicTotSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Unit_offering__c')
            .queryFields(new Set<String> {'Id', 'Unit_Code__c', 'MA_Status__c' , 'Unit_Level__c' ,'title__C', 'Managing_Faculty_Name__c', 'Start_Date__c', 'Location__c', 'Academic_Year__c', 'Calendar_year__c', 'Calendar_Name__c', 'Studyabroad_Exchange_Ind__c'})
            .getQuery(strWhereClause);

            List<unit_offering__c> totalSearchResults = Database.query(dynamicTotSearchQuery);


            strWhereClause +=' order by  Title__c  LIMIT 10 OFFSET :offsetRange ';

            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Unit_offering__c')
            .queryFields(new Set<String> {'Id', 'Unit_Code__c', 'MA_Status__c' , 'Unit_Level__c' ,'title__C', 'Managing_Faculty_Name__c', 'Start_Date__c', 'Location__c', 'Academic_Year__c', 'Calendar_year__c', 'Calendar_Name__c', 'Studyabroad_Exchange_Ind__c'})
            .getQuery(strWhereClause);
            List<unit_offering__c> searchResults = Database.query(dynamicSearchQuery);


            // if the application's campus location is online, then enable the units to be selected by the applicants
            if(applicationCampusLocation == 'Online'){
                for(Unit_Offering__c loopOffering : searchResults){
                    loopOffering.Studyabroad_Exchange_Ind__c = true;
                }
            }
            System.debug(' dynamicQuery=='+dynamicTotSearchQuery);
            retMap.put('TotRes',totalSearchResults);
            retMap.put('results',searchResults);

        } catch(Exception e)
        {
            LogUtilityException.logException(e,'StudyPreferenceService.searchUnitOfferings');
            throw e;
        }
        return retMap;
    }
    /**
     * @date March 2021
     * @description - populate Faculty picklist
    */
    @AuraEnabled
    public static Map<String, Object> searchUnitOfferingsForPicklist(Id appId, String unitCodeorTitle, Integer numSemesters, List<String> excludedIds)
    {
        //UG/PG - Unit levels for filtering
        Set<String> UG_UNIT_LEVELS = new Set<String>{'1','2','3','4'};
        Set<String> PG_UNIT_LEVELS = new Set<String>{'4','5','9'};
        List<Application_Course_Preference__c> acps = getACPs(appId);
        Map<String, Object> retMap = new Map<String, Object>();
        List<Id> acpIds = new List<Id>();
        String caulfieldCampus = 'CAULFIELD';
        String claytonCampus = 'CLAYTON';
        String selectedUnitCodeorTitle = '%'+String.escapeSingleQuotes(unitCodeorTitle)+'%';

        for(Application_Course_Preference__c acp:acps )
        {
            acpIds.add(acp.Id);
        }
        
        if(acpIds.size()==0) 
            return retMap;

        List<Application_Course_Preference__c> acpList = [SELECT Calendar_Code__r.Type__c, Calendar_Code__r.Year__c, Application__r.Campus_Location__c,Academic_Calendar_Type__c, Course_Offering__r.Location_Code__c, 
                                                                 Course_Offering__r.Course_Code__c, Application__r.Duration_of_Study__c
                                                          FROM Application_Course_Preference__c 
                                                          WHERE Id IN :acpIds];
        String admCalType =  acpList[0].Calendar_Code__r.Type__c;
      
        System.debug('acpList[0].Calendar_Code__r.Year__c=='+acpList[0].Calendar_Code__r.Year__c);
        List<String> tpList = retrieveUnitOfferingsTP(admCalType,  acpList[0].Calendar_Code__r.Year__c, acpList[0].Application__r.Duration_of_Study__c);
        String courseCampusLoc = acpList[0].Course_Offering__r.Location_Code__c;
        String applicationCampusLocation = acpList[0].Application__r.Campus_Location__c;
       
        String strWhereClause = ' Unit_Mode__c IN :unitMode  AND Id NOT IN :excludedIds AND Offered_Ind__c=TRUE AND Active_Ind__c=TRUE AND SSF_Avail_Ind__c=TRUE AND ( Title__C  like :selectedUnitCodeorTitle  OR Unit_Code__c like  :selectedUnitCodeorTitle)';
        
        if(applicationCampusLocation != 'Online')
        strWhereClause += ' AND  Calendar__r.Name =:tpList ';
        
            
        // filter the unit codes based off the course offering course code
        // based from the Available Virtual Course Units
        if(applicationCampusLocation == 'Online'){
            Set<String> unitOfferingCodes = retrieveCourseToUnitOfferingMap(acpList[0].Course_Offering__r.Course_Code__c);
            if(unitOfferingCodes != null){
                strWhereClause+= ' AND Unit_Code__c = :unitOfferingCodes';
            }
        }else{
            //For UG courses, filter to show only UG and similarly for PG courses
            if(acpList[0].Course_Offering__r.Course_Code__c ==  Constants.MONASH_ABROAD_SA_COURSE_UG_CODE ||
            acpList[0].Course_Offering__r.Course_Code__c == Constants.MONASH_ABROAD_EX_COURSE_UG_CODE)
            {
                strWhereClause+= ' AND Unit_Level__c = :UG_UNIT_LEVELS';
            }else {  
                strWhereClause+= ' AND Unit_Level__c = :PG_UNIT_LEVELS';
            }
            //Offered_Ind__c=TRUE ANDAND Start_Date__c<= :endDt
            if(courseCampusLoc == 'CLAYTON' || courseCampusLoc =='CAULFIELD')
            {
                strWhereClause+= ' AND (Location__c=:claytonCampus OR Location__c=:caulfieldCampus)';
            } else {
                strWhereClause+= ' AND Location__c=:courseCampusLoc';
            }
        }
        //Build SOQL using DynamicSoqlBuilder
        String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
        .showSOQLStatement(true)
        .setEnforced(false)
        .querySObject('Unit_offering__c')
        .queryFields(new Set<String> {'Id', 'Unit_Code__c', 'title__C' , 'Unit_Level__c' ,'Managing_Faculty_Name__c', 'Start_Date__c', 'Location__c', 'Academic_Year__c', 'Calendar_year__c', 'Calendar_Name__c', 'Calendar__r.Type__c'})
        .getQuery(strWhereClause);

        System.debug('query=='+strWhereClause);
        Set<String> facultyName = new Set<String>();
        List<unit_offering__c> searchResults = Database.query(dynamicSearchQuery);
        Integer totCnt = 0;
        for(unit_offering__c uo:searchResults)
        {
            facultyName.add(uo.Managing_Faculty_Name__c);
            totCnt++;
        }
        retMap.put('FacultyOptions', facultyName);
        retMap.put('Totalcount',totCnt);

        return retMap;
    }
    /**
     * @date March 2021
     * @description creating  unit preferences given ApplicationId and the associated UnitofferingId
    */
    @AuraEnabled
    public static Map<String,Object> createUnitPreference(Id appId, Id uoId)
    {
        try {
            List<Application_Course_Preference__c> acps = getACPs(appId);
            Integer order = fetchMaxOrder(acps[0].Id);
            
            Unit_Preference__c up =new Unit_Preference__c(Application__c = appId, Application_Course_Preference__c=acps[0].Id, Unit_Offering__c= uoId, Preference_Number__c = (++order));
            Database.insert(up);
            Integer sem = identifyUPSem(up.Id);
            System.debug('sem=='+sem);
            Unit_Preference__c up1 = new Unit_Preference__c(Semester__c = sem, Id=up.Id);
            update up1;

            return fetchUnitPreferences(appId);
        } catch(Exception e)
        {
            LogUtilityException.logException(e,'StudyPreferenceService.createUnitPreference');
            throw e;
        }
    }
     /**
    * @date April 2021 by Shalini Mendu
    * @description - Fetch maximum Preference order for Unit preference
    */
    public static Integer fetchMaxOrder(Id acpId)
    {   
        List<unit_preference__C> upList = [select Preference_Number__c from unit_preference__C where Application_Course_Preference__c=:acpId order by Preference_Number__c  desc limit 1];
        if(upList.size()>0 &&  upList[0].Preference_Number__c!=null)
            return upList[0].Preference_Number__c.intValue();
        else 
            return 1;
    }
    /**
     * @date March 2021
     * @description Remove  unit preferences given ApplicationId and the associated UnitofferingId
    */
    @AuraEnabled
    public static Map<String,Object>  removeUnitPreference(Id appId, Id uoId)
    {
        try {
          
            new appApplicationWrapper().removeUnitPreference(appId, uoId);
            return fetchUnitPreferences(appId);
        } catch(Exception e)
        {
            LogUtilityException.logException(e,'StudyPreferenceService.removeUnitPreference');
            throw e;
        }
    }
    /**
     * @date March 2021
     * @description Fetch unit preferences given ApplicationId
    */
    @AuraEnabled
    public static Map<String,Object> fetchUnitPreferences(Id appId)
    {
        Map<String,Object> retMap = new  Map<String,Object>();
        List<Application_Course_Preference__c> acps = getACPs(appId);

        if(!acps.isEmpty()) {
            List<Unit_Preference__c> retUP = [SELECT  UO_ID__c,Unit_Code__c, Start_Date__c,title__C,MA_Status__c,Managing_Faculty_Name__c, Location__c,Academic_Year__c,Calendar_Name__c,Preference_Number__c,Semester__c from unit_preference__C where Application_Course_Preference__c=:acps[0].Id order by Semester__c,Preference_Number__c];
            retMap.put('ACPAdmType', acps[0].Calendar_Code__r.Type__c );
            retMap.put('ACPAdmYr', acps[0].Calendar_Code__r.Year__c );
            retMap.put('UPList', retUP );
            if (acps[0].Application__r.Campus_Location__c == 'Online') {
                retMap.put('minimumUnits', Constants.MIN_UNITS_ONLINE);
                retMap.put('maximumUnits', Constants.MAX_UNITS_ONLINE);
            } else {
                retMap.put('minimumUnits', Constants.MIN_UNITS_MA);
                retMap.put('maximumUnits', Constants.MAX_UNITS_MA);
            }
        }
        return retMap;
    }

    /**
    * @date April 2021 by Shalini Mendu
    * @description -Identify semester for the Unit preference
    */
    public static Integer identifyUPSem(Id upId)
    {
        //List<String> adm1String = new List<String>{'T2-58','T1-58','S1-01','T2-57','T1-57'};
       // List<String> adm2String =  new List<String>{'S2-01','T3-58','T4-57','T3-57'};
        List<String> adm1String = retrieveCustomMetadata(UNIT_OFFERINGS_METADATA).get(ADM_1);
        System.debug('adm1String=='+adm1String);
        Unit_Preference__c up = [Select Unit_Offering__r.Calendar_Type__c  from Unit_Preference__c where id=:upId]; 
        System.debug('up.Unit_Offering__r.Calendar_Type__c=='+up.Unit_Offering__r.Calendar_Type__c);
 
        if(adm1String.contains(up.Unit_Offering__r.Calendar_Type__c))
            return 1;
        else 
            return 2;
    }
     /**
    * @date April 2021 by Shalini Mendu
    * @description - sort Unit Preferences from the Ui selection
    */
    @AuraEnabled
    public static Boolean sortUPOrder(String records) {
        List<Unit_Preference__c> upList = new List<Unit_Preference__c>();
        Map<String,Integer> orderUP = new Map<String,Integer>();
        Integer i= records.indexOf('\"Id\":\"');
        Integer incr = 0;
        try{
            while (i>0)
            {	
                String idd = records.substring(i+6, i+24);
                orderUP.put(idd, ++incr);
                Unit_Preference__c up = new Unit_Preference__c(Id= idd , Preference_Number__c = incr);
                upList.add(up);
                records = records.substring(i+24);
                i= records.indexOf('\"Id\":\"');
            }
            update upList;
            return true;
        }catch(Exception e){
            LogUtilityException.logException(e,'StudyPreferenceService.sortUPOrder');
            throw e;
        }
       
    }

    /**
     * @author     Shalini Mendu
     * @description Returns a list of the mapped Unit offering Teaching period calendar for an ACP Admission calendar
     * @revision    29/06/2021 - Shalini Mendu - Created
     */
    public static List<String> retrieveUnitOfferingsTP( String acpAdmPeriod ,String acpYear, String durStudy)
    {
        List<String> tpCalendars = new List<String>();
        List<String> admCalYear = new List<String>();
        Map<String, List<String>> tpMap = new Map<String, List<String>>();
        List<String> admCal = new List<String>();
        if(acpAdmPeriod == ADM_2)
        {
            tpMap.put(acpYear, new List<String>{ADM_2});
        }else if(acpAdmPeriod == ADM_1)
        {
           tpMap.put(acpYear, new List<String>{ADM_1});
        }

        Map<String, List<String>> uoMap = retrieveCustomMetadata(UNIT_OFFERINGS_METADATA);
        for(String tp: tpMap.keySet())
        {   List<String> admCals = tpMap.get(tp);
            for(String cal : admCals)
            {
                for(String uo:uoMap.get(cal))
                {
                    tpCalendars.add('TEACH_'+tp+'_'+uo);
                    System.debug('tpCalendars=='+tpCalendars);
                }
            }
           
        }
        return tpCalendars;
    }

    /**
     * @author     Shalini Mendu
     * @description Returns Unit offerings metadata
     * @revision    5/07/2021 - Shalini Mendu - Created
    */
    private static Map<String, List<String>>  retrieveCustomMetadata(String uoMetadata)
    {
        Map<String, List<String>> uoMap = new Map<String, List<String>>();
        for(Admissions_Settings__mdt adm:[select Admission_Calendar__c,Teaching_Period_Calendar__c from Admissions_Settings__mdt where Type__c=:uoMetadata])
        {
           if(uoMap.containsKey(adm.Admission_Calendar__c))
           {
            uoMap.get(adm.Admission_Calendar__c).add(adm.Teaching_Period_Calendar__c);
           }else {
            uoMap.put(adm.Admission_Calendar__c, new List<String>{adm.Teaching_Period_Calendar__c});
           }
        }
        System.debug('uoMap=='+uoMap);
        return uoMap;
    }
      
    
    /*******************************************************************************
    * @author       Vinothraja
    * @date
    * @description  Wrapper class for fetching the Application on Without sharing basis
    *               to facilitate accessing user & profile fields from Partner Portal
    * @revision
    * 01.Apr.2021 - Vinothraja - SFTG-1898 - wrapper class to fetch application
    *******************************************************************************/
    public without sharing class appApplicationWrapper {
        public Application__c app;
        public String strCreatedBy;

        public appApplicationWrapper getApplication(String appId) {
            appApplicationWrapper appWrapper = new appApplicationWrapper();
            appWrapper.app = [
                                 SELECT Id, Campus_Location__c, createdby.Profile.name, Residency_Status__c, Type_of_Study__c,Source_System__c, Duration_of_Study__c
                                 FROM Application__c
                                 WHERE Id = :appId
                             ][0];
            appWrapper.strCreatedBy = appWrapper.app.createdby.Profile.name;
            return appWrapper;
        }

        /**
         * @author Shalini Mendu
         * @date 3-August- 2021
         * @description Remove  unit preferences given ApplicationId and the associated UnitofferingId
        */
        public void removeUnitPreference(Id appId, Id uoId)
        {
            try {
                List<Application_Course_Preference__c> acps = getACPs(appId);
                List<Unit_Preference__c> upList = [Select id,name from  Unit_Preference__c  where Application_Course_Preference__c=:acps[0].id AND Unit_Offering__c=:uoId limit 1];
                if(upList.size()>0)
                    Database.delete(upList[0]);
            } catch(Exception e)
            {
                LogUtilityException.logException(e,'StudyPreferenceService.removeUnitPreference');
                throw e;
            }
        }

        
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves the unit offering codes that are available to the course code
     * @revision    12/05/2021 - Kristian Vegerano - Created
     */
    public static Set<String> retrieveCourseToUnitOfferingMap(String courseCode){
        //Retrieve available course - unit offering links (for virtual)
        Map<String, Set<String>> courseCodeMap = new Map<String, Set<String>>();
        for(Available_Virtual_Course_Unit__mdt loopCourseUnit : [SELECT Id, Course_Code__c, Unit_Code__c FROM Available_Virtual_Course_Unit__mdt]){
            if(!courseCodeMap.containsKey(loopCourseUnit.Course_Code__c)){
                courseCodeMap.put(loopCourseUnit.Course_Code__c, new Set<String>());
            }
            courseCodeMap.get(loopCourseUnit.Course_Code__c).add(loopCourseUnit.Unit_Code__c);
        }

        return courseCodeMap.get(courseCode);
    }
}