/*******************************************************************************
* @author       Davey Yu
* @date
* @description  Controller class for myGRAppAddCourse LWC
* @revision
* 20.Sep.2024 - Davey Yu - MGROI-281 - Application Details
*******************************************************************************/
public without sharing class StudyPreferenceServiceGR  {

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

    //Campus locations
    public static String malaysia = 'Malaysia';
    public static String SAfrica = 'SAfrica';
    public static String indonesia = 'Indonesia';
    public static String MCJAKARTA = 'MC-JAKARTA';
    public static String online = 'ONLINE';
    public static String PRATO = 'PRATO';
    public static String ONLINEA = 'ONLINE-A'; 
    public static String china = 'China'; 
    public static String msri = 'MSRI';

     
    //Course types
    public static String mufy = 'MUFY-%';
    public static String os = 'OS-%';
    
 
    //Faculty & AOU Values
    public static String FACULTY_AUST = 'RSRCH-AUST';
    public static String FACULTY_MI = 'RSRCH-MI';
    public static String FACULTY_MLAY = 'RSRCH-MLAY';
    public static String FACULTY_MSRI = 'RSRCH-MSRI';
    public static String AOU_AUST = 'RSRCH-AUST_AOU';
    public static String AOU_MI = 'RSRCH-MI_AOU';
    public static String AOU_MLAY = 'RSRCH-MLAY_AOU'; 
    public static String AOU_MSRI = 'RSRCH-MSRI_AOU'; 
	
    //Course Code and Course Titles
    public static String COURSE_CODE = 'CourseCode';
    public static String COURSE_TITLE = 'CourseTitle';

    public static Set<String> locations = new Set<String>();
    
    /**
     * @author Davey Yu
     * @description get current user
     * @date 23-SEP-2024
     * @param N/A
     * @return List<User>     
	*/
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

        return listUsers[0];
    }
	
    /**
     * @author Davey Yu
     * @description get application details initial load
     * @date 23-SEP-2024
     * @param appId application Id
     * @return Map<String, Object>   
	*/
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
            if (ura == NULL || ura.HasReadAccess) {
                // get application
                appApplicationWrapper appwrap = new appApplicationWrapper().getApplication(appId);
                // course location map
                mapResults.put(FIELD_APPLICATION, appwrap.app);
                mapResults.put(FIELD_APPLICATION_CREATEDBY, appwrap.strCreatedBy);

                List<Application_Course_Preference__c> acps = getACPs(appId);
                mapResults.put(FIELD_ACPS, acps);

                if(appwrap.app.Residency_Status__c != null  && appwrap.app.Graduate_Research_Application_Type__c != null){
                	String scholarshipDisabledResults = checkScholarshipRounds(appwrap.app.Residency_Status__c, appwrap.app.Graduate_Research_Application_Type__c);
                	mapResults.put('CheckRounds', scholarshipDisabledResults);
                }

            }
        }

        return mapResults;
    }

    /**
     * @author Davey Yu
     * @description get current user
     * @date 23-SEP-2024
     * @param N/A
     * @return List<User>     
	*/
    private static List<Application_Course_Preference__c> getACPs(Id appId) {
        List<Application_Course_Preference__c> appCourses = new List<Application_Course_Preference__c>();
        if (appId != null) {
            appCourses = [
                             SELECT
                             Id, Preference_Number__c, Unit_Set_Description__c,Course_Offering__r.Location_Code__c,
                             Course_Title__c, Course_Code__c, Attendance_Type_Description__c, Attendance_Mode__c,
                             Attendance_Mode_Description__c, Type_of_Place_Description__c,Course_Offering__r.Start_Date__c,
                             Location_Code__c, Commencement_Period__c, Course_Offering__c, Course_Offering__r.Active__c,
                             Calendar_Code__r.Type__c, Calendar_Code__r.Year__c, Application__r.Campus_Location__c, Application__r.Graduate_Research_Application_Type__c,
                             Application__r.Scholarship_Round_Description__c, Proposed_Commencement_Date__c, Managing_Faculty__c, Academic_Org_Unit__r.Name,
                             Application__r.Residency_Status__c
                             FROM Application_Course_Preference__c
                             WHERE Application__c = :appId
                             ORDER BY Preference_Number__c ASC
                         ];
        }

        return appCourses;
    }

     /**
     * @author Davey Yu
     * @description get scholarship round values for admission and scholarship application
     * @date 23-SEP-2024
     * @param citizenship Citizenship Type
     * @return List<Map<String, String>>    
	*/
    public static String checkScholarshipRounds(String citizenship, String appType){//NOPMD
        try {

            List<String> internationalCalendarDates = new List<String>();
            List<String> domesticCalendarDates = new List<String>();
            List<String> calendarTypes = new List<String>();
            String result = '';
            Boolean isDomestic = false;
            Boolean isInternational = false;
            Date todaysDateInAus;
            
            if(!appType.contains('Scholarship')){
                return '';
            }
            
            DateTime todaysDateInAusTimeZone = convertToTimezone(DateTime.now(),'Australia/Sydney');
                
            if (todaysDateInAusTimeZone != null){
               todaysDateInAus = todaysDateInAusTimeZone.date();
            }
            
            // Query the records from the specified object
            String strWhereClause ='';
            calendarTypes.add('ADM-RES1');
            calendarTypes.add('ADM-RES2');

            strWhereClause += ' CalendarId__r.Type__c IN :calendarTypes';
            
            
            //international or domestic application
            if(citizenship == 'DOM-AUS' || citizenship == 'DOM-PR'
            || citizenship == 'DOM-NZ'){//Domestic
                domesticCalendarDates.add('HDR-SCH-OP');
                domesticCalendarDates.add('HDR-SCH-CL');
                strWhereClause += ' AND Name IN :domesticCalendarDates ';
                isDomestic = true;
            }else{//international
                internationalCalendarDates.add('HDR-SCI-OP');
                internationalCalendarDates.add('HDR-SCI-CL');
                strWhereClause += ' AND Name IN :internationalCalendarDates ';
                isInternational = true;
            }
            
            strWhereClause += ' AND Date_Value__c >= TODAY';
            strWhereClause += ' ORDER BY Date_Value__c ASC LIMIT 1';

            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Calendar_Dates__c')
            .queryFields(new Set<String> {'Id', 'Name', 'CalendarId__r.id', 'Date_Value__c', 'Date_Type_Description__c', 'CalendarId__r.Type__c', 'CalendarId__r.Name', 'CalendarId__r.Disable_Domestic_Scholarship_Round__c', 'CalendarId__r.Disable_International_Scholarship_Round__c'})
            .getQuery(strWhereClause);
            List<Calendar_Dates__c> calendarDates = Database.query(dynamicSearchQuery);
            if(calendarDates.size()  > 0){
                for (Calendar_Dates__c cd : calendarDates) {
                    if(isDomestic && cd.CalendarId__r.Disable_Domestic_Scholarship_Round__c){
                        result = 'DisableDomestic';
                    }
                    if(isInternational && cd.CalendarId__r.Disable_International_Scholarship_Round__c){
                        result = 'DisableInternational';
                    }
                }
            }else{
                result = 'WithScholarshipGaps';
            }
            if(result == ''){
                Date earliestDateCheck;
                Date latestDateCheck;
                
                if(todaysDateInAus!=null){
                    earliestDateCheck = todaysDateInAus;
                    latestDateCheck = todaysDateInAus;       
                }
                
                Boolean withoutScholarshipGaps = false;
                
                for (Calendar_Dates__c cd : [SELECT Id, Date_Value__c, Name FROM Calendar_Dates__c WHERE 
                                                Name IN ('HDR-SCH-OP', 'HDR-SCH-CL', 'HDR-SCI-OP', 'HDR-SCI-CL') 
                                                AND CalendarId__c =: calendarDates[0].CalendarId__r.id
                                                LIMIT 4]) {
                    if(isDomestic){
                        if(cd.Name == 'HDR-SCH-OP'){
                            earliestDateCheck = cd.Date_Value__c;
                        }
                        if(cd.Name == 'HDR-SCH-CL'){
                            latestDateCheck = cd.Date_Value__c;
                        }
                    }
                    if(isInternational){
                        if(cd.Name == 'HDR-SCI-OP'){
                            earliestDateCheck = cd.Date_Value__c;
                        }
                        if(cd.Name == 'HDR-SCI-CL'){
                            latestDateCheck = cd.Date_Value__c;

                        }
                    }
                                                    
                }
               
                if(todaysDateInAus !=null && todaysDateInAus >= earliestDateCheck &&  todaysDateInAus <= latestDateCheck){ 
                    withoutScholarshipGaps = true;
                }else{
                    result = 'WithScholarshipGaps';
                }
            }
            return result;
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Check Scholarship Rounds', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
	
     /**
     * @author Davey Yu
     * @description get scholarship round values for admission and scholarship application
     * @date 23-SEP-2024
     * @param citizenship Citizenship Type
     * @return List<Map<String, String>>    
	*/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getScholarshipRoundsValues(String citizenship, Boolean withScholarship, Boolean disableScholarshipRounds){//NOPMD
        try {

            List<String> internationalCalendarDates = new List<String>();
            List<String> domesticCalendarDates = new List<String>();
            List<String> calendarTypes = new List<String>();
            List<Map<String, String>> values = new List<Map<String, String>>();
            Boolean isDomestic = false;
            Boolean isInternational = false;
            if(disableScholarshipRounds){
                return null;
            }
            if(!withScholarship){
                return null;
            }
               
            // Query the records from the specified object
            String strWhereClause ='';
            calendarTypes.add('ADM-RES1');
            calendarTypes.add('ADM-RES2');

            strWhereClause += ' CalendarId__r.Type__c IN :calendarTypes';
          
            //international or domestic application
            if(citizenship == 'DOM-AUS' || citizenship == 'DOM-PR'
            || citizenship == 'DOM-NZ'){//Domestic
                domesticCalendarDates.add('HDR-SCH-OP');
                domesticCalendarDates.add('HDR-SCH-CL');
                strWhereClause += ' AND Name IN :domesticCalendarDates ';
                isDomestic = true;
            }else{//international
                internationalCalendarDates.add('HDR-SCI-OP');
                internationalCalendarDates.add('HDR-SCI-CL');
                strWhereClause += ' AND Name IN :internationalCalendarDates ';
                isInternational = true;
            }
            
            strWhereClause += ' AND Date_Value__c >= TODAY';
            strWhereClause += ' ORDER BY Date_Value__c ASC LIMIT 2';

            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Calendar_Dates__c')
            .queryFields(new Set<String> {'Id', 'Name', 'CalendarId__r.id', 'Date_Value__c', 'Date_Type_Description__c', 'CalendarId__r.Type__c', 'CalendarId__r.Name', 'CalendarId__r.Disable_Domestic_Scholarship_Round__c', 'CalendarId__r.Disable_International_Scholarship_Round__c'})
            .getQuery(strWhereClause);
            List<Calendar_Dates__c> searchAggregate = Database.query(dynamicSearchQuery);
            List<String> calendarIds = new List<String>();
            String closingDate = '';
            String closingMonthYear = '';
            for (Calendar_Dates__c ag : searchAggregate) {
                if(ag.Name == 'HDR-SCH-CL' || ag.Name == 'HDR-SCI-CL') {
                    calendarIds.add(String.valueOf(ag.CalendarId__r.id));
                    closingDate = formatDate(ag.Date_Value__c);
                    closingMonthYear = Datetime.newInstance(ag.Date_Value__c, Time.newInstance(0, 0, 0, 0))?.format('MMMM yyyy');
                    break;
                }
            }

            //get commencement date from calander
            String earliestCommencementDate = '';
            String latestCommencementDate = '';
            String earliestPossibleDateText = '';
            Date earlyDate = Date.today();
            Date latestDate = Date.today();
            Date earliestPossibleDate= Date.today();
            
            //Retrieved the earliest commencement dates
            List<Calendar_Dates__c> calendarCommencementDates = new List<Calendar_Dates__c>();
            calendarCommencementDates = [SELECT CalendarId__c, CalendarId__r.Disable_Domestic_Scholarship_Round__c, CalendarId__r.Disable_International_Scholarship_Round__c, 
                                        Date_Value__c, Name FROM Calendar_Dates__c WHERE Name in ('HDR-SCM-ET', 'HDR-SCM-LT', 'HDR-SCM-EP') AND CalendarId__c IN : calendarIds Limit 3];
            
            for(Calendar_Dates__c cd: calendarCommencementDates){
                if(cd.Name == 'HDR-SCM-ET'){
                    earliestCommencementDate =formatDate(cd.Date_Value__c);
                    earlyDate = cd.Date_Value__c;
                }else if(cd.Name == 'HDR-SCM-LT'){
                    latestCommencementDate = formatDate(cd.Date_Value__c);
                    latestDate = cd.Date_Value__c;
                }else{
                    earliestPossibleDate = cd.Date_Value__c;
                    earliestPossibleDateText = formatDate(cd.Date_Value__c);
                }
            }
            
            //build scholarship round value in a picklist
            if(calendarCommencementDates.size() > 0){
                String scholarshipRounds = 'Round Closing '+closingDate+' for commencement between '+earliestCommencementDate+' and '+latestCommencementDate;
                Map<String, String> valueMap = new Map<String, String>();
                valueMap.put('label', scholarshipRounds);
                valueMap.put('value', calendarCommencementDates[0].CalendarId__c+'='+earlyDate+'='+earliestCommencementDate+'='+latestDate+'='+latestCommencementDate+'='+earliestPossibleDate+'='+earliestPossibleDateText+'='+closingMonthYear);
                values.add(valueMap);
            }else{
                return null;
            }
            
            
            return values;
            
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Get Scholarship Rounds', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getCalendarIdBasedOnCommencementDate(Date proposedDate){
        try{
            List<String> calendarTypes = new List<String>();
            String calId = '';
            String earlyCommDate = 'HDR-SCM-ET'; //NOPMD
               
            // Query the records from the specified object
            String strWhereClause ='';
            calendarTypes.add('ADM-RES1');
            calendarTypes.add('ADM-RES2');

            strWhereClause += ' CalendarId__r.Type__c IN :calendarTypes';

            strWhereClause += ' AND Name =: earlyCommDate';
        
            
            strWhereClause += ' AND Date_Value__c <= :proposedDate';
            strWhereClause += ' ORDER BY Date_Value__c DESC LIMIT 1';

            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Calendar_Dates__c')
            .queryFields(new Set<String> {'Id', 'Name', 'CalendarId__r.id', 'Date_Value__c', 'Date_Type_Description__c', 'CalendarId__r.Type__c', 'CalendarId__r.Name', 'CalendarId__r.Disable_Domestic_Scholarship_Round__c', 'CalendarId__r.Disable_International_Scholarship_Round__c'})
            .getQuery(strWhereClause);
            List<Calendar_Dates__c> searchAggregate = Database.query(dynamicSearchQuery);
            List<String> calendarIds = new List<String>();
            for (Calendar_Dates__c ag : searchAggregate) {
               calendarIds.add(String.valueOf(ag.CalendarId__r.id));
            }

            //get commencement date from calander
            String earliestCommencementDate = '';
            String latestCommencementDate = '';
            Date earlyDate = Date.today();
            Date latestDate = Date.today();
            
            //Retrieved the earliest commencement dates
            if(calendarIds.size() > 0){
                List<Calendar_Dates__c> calendarCommencementDates = new List<Calendar_Dates__c>();
                calendarCommencementDates = [SELECT CalendarId__c, CalendarId__r.Disable_Domestic_Scholarship_Round__c, CalendarId__r.Disable_International_Scholarship_Round__c, 
                                            Date_Value__c, Name FROM Calendar_Dates__c WHERE Name in ('HDR-SCM-ET', 'HDR-SCM-LT') AND CalendarId__c IN : calendarIds Limit 2];
                
                for(Calendar_Dates__c cd: calendarCommencementDates){
                    if(cd.Name == 'HDR-SCM-ET'){
                        earliestCommencementDate =formatDate(cd.Date_Value__c);
                        earlyDate = cd.Date_Value__c;
                    }else{
                        latestCommencementDate = formatDate(cd.Date_Value__c);
                        latestDate = cd.Date_Value__c;
                    }
                }

                if(earlyDate <= proposedDate && latestDate >= proposedDate){
                    calId = calendarIds[0];
                }
            }
            return calId;
                        
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Get Scholarship Rounds', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
	
     /**
     * @author Davey Yu
     * @description get calendar id for admission application only
     * @date 23-SEP-2024
     * @param citizenship citizenship type
     * @param pcDate	  proposed commencement date
     * @return Id    
	*/
    @AuraEnabled(cacheable=true)
    public static Id getCalendarIdCandidature(String citizenship, Date pcDate){
        try {
            if(citizenship == '' || pcDate == null){
                return null;
            }
            List<String> domesticCalendarDates = new List<String>();
            List<String> calendarTypes = new List<String>();
            Id calId = null;

            // Query the records from the specified object
            String strWhereClause ='';
            calendarTypes.add('ADM-RES1');
            calendarTypes.add('ADM-RES2');

            strWhereClause += ' CalendarId__r.Type__c IN :calendarTypes';
                     
            domesticCalendarDates.add('HDR-CCM-ET');
            domesticCalendarDates.add('HDR-CCM-LT');
             
            strWhereClause += ' AND Name IN :domesticCalendarDates ';
            
            //date is based on proposed commencement date
            strWhereClause += ' AND Date_Value__c >= :pcDate';
            strWhereClause += ' ORDER BY Date_Value__c ASC LIMIT 1';

            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Calendar_Dates__c')
            .queryFields(new Set<String> {'Id', 'Name', 'CalendarId__r.id', 'Date_Value__c', 'Date_Type_Description__c', 'CalendarId__r.Type__c', 'CalendarId__r.Name'})
            .getQuery(strWhereClause);

            //return calendar id
            List<Calendar_Dates__c> calendarDates = Database.query(dynamicSearchQuery);
            if(calendarDates.size() > 0){
               calId = calendarDates[0].CalendarId__c;
            }
            return calId;

        } catch (Exception e) {
            Nebula.Logger.error('Application Details Get Scholarship Rounds For Candidature', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
	
     /**
     * @author Davey Yu
     * @description get HDR courses
     * @date 23-SEP-2024
     * @param facultyId Faculty Id
     * @param calendarId Scholarship round calendar id
     * @param citizenshipType Citizenship Type
     * @param campusLocation Campus location
     * @return List<Map<String, String>>      
	*/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getHDRCourses(String facultyId, String calendarId, String citizenshipType, String campusLocation){
        try {

            //get facultyCode and aouCode
            String courseTypeHDR = CONSTANTS.COURSETYPE_GROUP_HDR; //NOPMD
            List<Map<String, String>> searchResults = new List<Map<String, String>>();

            //Return null if any of the parameters is empty
            if(String.isEmpty(facultyId) || String.isEmpty(calendarId) || String.isEmpty(citizenshipType)){
                return null;
            }

            

            // Query the records from the specified object
            String strWhereClause ='';
            if(!Test.isRunningTest()){
                strWhereClause += ' Course_Type_Group__c = :courseTypeHDR AND Course__r.Faculty__c =: facultyId AND Calendar__c =: calendarId ' ;
            }else{
                strWhereClause += ' Course_Type_Group__c = :courseTypeHDR AND Calendar__c =: calendarId ' ;
            }

            strWhereClause += ' AND Portal_Available__c=true AND Default_Admission_Category_Ind__c= true AND Active__c = TRUE';

            strWhereClause += makeCampusLocationClause(campusLocation);

            strWhereClause += ' GROUP BY Course_Code__c, Course_Title__c';
            strWhereClause += ' ORDER BY Course_Title__c';
            
            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Course_Offering__c')
            .queryFields(new Set<String> { 'Course_Code__c' ,'Course_Title__c'})
            .getQuery(strWhereClause);
            
            
            List<AggregateResult> searchAggregate = Database.query(dynamicSearchQuery);
            Set<String> uniqueCodes = new Set<String>();
            
            //Group the hdr courses based on course code and course title
                for (AggregateResult ag : searchAggregate) {
                    String courseCode = (String) ag.get(FIELD_COURSE_CODE);//Course_Code__c
                    String courseTitle = (String) ag.get(FIELD_COURSE_TITLE);//Course_Title__c
            
                    if (!uniqueCodes.contains(courseCode)) {
                        // add to the list of results, if new
                        Map<String, String> objCourse = new Map<String, String>();
                        String courseLabel = courseCode+' - '+courseTitle;
                        String courseLabelValue = courseCode+'='+courseTitle;
                        objCourse.put('label', courseLabel);
                        objCourse.put('value', courseLabelValue);
                        searchResults.add(objCourse);
                    }
                    uniqueCodes.add(courseCode);
            }

            return searchResults;
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Get Graduate Research Courses', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
	
    /**
     * @author Davey Yu
     * @description get Campus Locations
     * @date 23-SEP-2024
     * @param facultyId Faculty Id
     * @param calendarId Scholarship round calendar id
     * @param citizenshipType Citizenship Type
     * @param campusLocation Campus location
     * @param courseLabel course code and course title
     * @return List<Map<String, String>>      
	*/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCampusLocations(String facultyId, String calendarId, String citizenshipType, String courseLabel, String campusLocation){
        try {

            //get facultyCode and aouCode
            String courseTypeHDR = CONSTANTS.COURSETYPE_GROUP_HDR;//NOPMD
            List<Map<String, String>> searchResults = new List<Map<String, String>>();
            
            //Return null if any of the parameters is empty
            if(String.isEmpty(facultyId) || String.isEmpty(calendarId) || String.isEmpty(courseLabel) ||  String.isEmpty(campusLocation))
            {
                return null;
            }

            //Retrieved course code and course title from the selected hdr courses
            String courseCode = getCourseDetails(COURSE_CODE, courseLabel); //NOPMD
            String courseTitle = getCourseDetails(COURSE_TITLE, courseLabel); //NOPMD
           
            String strWhereClause ='';
            if(!Test.isRunningTest()){
                strWhereClause += ' Course_Type_Group__c = :courseTypeHDR AND Course__r.Faculty__c =: facultyId AND Calendar__c =: calendarId ' ;
            }else{
                strWhereClause += ' Course_Type_Group__c = :courseTypeHDR AND Calendar__c =: calendarId ' ;
            }
            // if the application campus location is online, ignore the citizenship type of the applicant (Application__c.Residency_Status__c)
            strWhereClause += ' AND Course_Code__c =: courseCode AND Course_Title__c =: courseTitle';
            
            strWhereClause += ' AND Portal_Available__c=true AND Default_Admission_Category_Ind__c= true AND Active__c = TRUE';

            strWhereClause += makeCampusLocationClause(campusLocation);


            strWhereClause += ' GROUP BY Location_Code__c';
            

            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Course_Offering__c')
            .queryFields(new Set<String> {'Location_Code__c'})
            .getQuery(strWhereClause);

            List<AggregateResult> searchAggregate = Database.query(dynamicSearchQuery);
            Set<String> uniqueLocationCodes = new Set<String>();
            for (AggregateResult ag : searchAggregate) {
                
                String locationCode = (String) ag.get('Location_Code__c');
                if (!uniqueLocationCodes.contains(locationCode)) {
                    // add to the list of results, if new
                    Map<String, String> locCodes = new Map<String, String>();
                    locCodes.put('label', locationCode);
                    locCodes.put('value', locationCode);
                    searchResults.add(locCodes);
                }
                uniqueLocationCodes.add(locationCode);
            }
           
            return searchResults;
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Get Campus Locations', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
	
    /**
     * @author Davey Yu
     * @description get HDR Attendance Types
     * @date 23-SEP-2024
     * @param facultyId Faculty Id
     * @param calendarId Scholarship round calendar id
     * @param citizenshipType Citizenship Type
     * @param campusLocation Campus location
     * @param courseLabel Course code and course title
     * @param locationCode Location code
     * @return List<Map<String, String>>      
	*/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAttendanceTypes(String facultyId, String calendarId, String citizenshipType, String courseLabel, String locationCode){
        try {

            //get facultyCode and aouCode
            String courseTypeHDR = CONSTANTS.COURSETYPE_GROUP_HDR; //NOPMD

            List<Map<String, String>> searchResults = new List<Map<String, String>>();

            //return null if any of the parameters is empty
            if(String.isEmpty(facultyId) || String.isEmpty(calendarId) || String.isEmpty(citizenshipType) 
                || String.isEmpty(courseLabel) || String.isEmpty(locationCode))
            {
                return null;
            }
            

            //Retrieved course code and course title from the selected hdr courses
            String courseCode = getCourseDetails(COURSE_CODE, courseLabel); //NOPMD
            String courseTitle = getCourseDetails(COURSE_TITLE, courseLabel); //NOPMD

            // Query the records from the specified object
            String strWhereClause ='';
            if(!Test.isRunningTest()){
                strWhereClause += ' Course_Type_Group__c = :courseTypeHDR AND Course__r.Faculty__c =: facultyId AND Calendar__c =: calendarId ' ;
            }else{
                strWhereClause += ' Course_Type_Group__c = :courseTypeHDR AND Calendar__c =: calendarId ' ;
            }
            // if the application campus location is online, ignore the citizenship type of the applicant (Application__c.Residency_Status__c)
            strWhereClause += ' AND Course_Code__c =: courseCode AND Course_Title__c =: courseTitle AND Location_Code__c = :locationCode';
            
            strWhereClause += ' AND Portal_Available__c=true AND Default_Admission_Category_Ind__c= true AND Active__c = TRUE';

            strWhereClause += ' GROUP BY Attendance_Type__c';
            
            
            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Course_Offering__c')
            .queryFields(new Set<String> {'Attendance_Type__c'})
            .getQuery(strWhereClause);
        

            List<AggregateResult> searchAggregate = Database.query(dynamicSearchQuery);
            Set<String> uniqueAttendanceTypes = new Set<String>();
            for (AggregateResult ag : searchAggregate) {
                
                String attendanceType = (String) ag.get('Attendance_Type__c');
                if (!uniqueAttendanceTypes.contains(attendanceType)) {
                    // add to the list of results, if new
                    Map<String, String> attendanceTypes = new Map<String, String>();
                    String attendanceTypeDesc = '';
                    if(attendanceType == 'FT'){
                        attendanceTypeDesc = 'Full-time';
                    }else{
                        attendanceTypeDesc = 'Part-time';
                    }
                    attendanceTypes.put('label', attendanceTypeDesc);
                    attendanceTypes.put('value', attendanceType);
                    searchResults.add(attendanceTypes);
                }
                uniqueAttendanceTypes.add(attendanceType);
            }
            
        	return searchResults;
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Get Attendance Types', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
	
    /**
     * @author Davey Yu
     * @description get Attendance Modes 
     * @date 23-SEP-2024
     * @param facultyId Faculty Id
     * @param calendarId Scholarship round calendar id
     * @param citizenshipType Citizenship Type
     * @param campusLocation Campus location
     * @param courseLabel Course code and course title
     * @param locationCode Location code
     * @param attendanceType Attendance Type
     * @return List<Map<String, String>>      
	*/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAttendanceModes(String facultyId, String calendarId, String citizenshipType, String courseLabel, String locationCode, String attendanceType){
        try {
	
            //get facultyCode and aouCode
            String courseTypeHDR = CONSTANTS.COURSETYPE_GROUP_HDR; //NOPMD

            List<Map<String, String>> searchResults = new List<Map<String, String>>();
            
            //return null if any of the parameters is empty
            if(String.isEmpty(facultyId) || String.isEmpty(calendarId)  || String.isEmpty(citizenshipType) 
             || String.isEmpty(courseLabel) || String.isEmpty(locationCode) || String.isEmpty(attendanceType))
            {
                return null;
            }
            
            //Retrieved course code and course title from the selected hdr courses
            String courseCode = getCourseDetails(COURSE_CODE, courseLabel); //NOPMD
            String courseTitle = getCourseDetails(COURSE_TITLE, courseLabel); //NOPMD

            // Query the records from the specified object
            String strWhereClause ='';
            if(!Test.isRunningTest()){
                strWhereClause += ' Course_Type_Group__c = :courseTypeHDR AND Course__r.Faculty__c =: facultyId AND Calendar__c =: calendarId ' ;
            }else{
                strWhereClause += ' Course_Type_Group__c = :courseTypeHDR AND Calendar__c =: calendarId ' ;
            }

            // if the application campus location is online, ignore the citizenship type of the applicant (Application__c.Residency_Status__c)
            strWhereClause += ' AND Course_Code__c =: courseCode AND Course_Title__c =: courseTitle AND Location_Code__c = :locationCode AND Attendance_Type__c = :attendanceType';
            
            strWhereClause += ' AND Portal_Available__c=true AND Default_Admission_Category_Ind__c= true AND Active__c = TRUE';

            strWhereClause += ' GROUP BY Attendance_Mode__c';
                
            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Course_Offering__c')
            .queryFields(new Set<String> {'Attendance_Mode__c'})
            .getQuery(strWhereClause);
            

            List<AggregateResult> searchAggregate = Database.query(dynamicSearchQuery);
            Set<String> uniqueAttendanceModes = new Set<String>();
            for (AggregateResult ag : searchAggregate) {
                
                String attendanceMode = (String) ag.get('Attendance_Mode__c');
                if (!uniqueAttendanceModes.contains(attendanceMode)) {
                    // add to the list of results, if new
                    Map<String, String> attendanceModes = new Map<String, String>();
                    String attendanceModeDesc = '';
                    if(attendanceMode == 'EX'){
                        attendanceModeDesc = 'External (off-campus)';
                    }
                    
                    if(attendanceMode == 'IN'){
                        attendanceModeDesc = 'Internal (on-campus)';
                    }
                    attendanceModes.put('label', attendanceModeDesc);
                    attendanceModes.put('value', attendanceMode);
                    searchResults.add(attendanceModes);
                }
                uniqueAttendanceModes.add(attendanceMode);
            }
            return searchResults;
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Get Attendance Modes', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

	 /**
     * @author Davey Yu
     * @description get Academic Org Unit Values
     * @date 23-SEP-2024
     * @param facultyId Faculty Id
     * @param appCountry Application Country
     * @return List<Map<String, String>>      
	*/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAcademicUnitValues(String facultyId, String appCountry){
        try {
            //get facultyCode and aouCode
            String facultyCode;
            String aouCode;
            switch on (appCountry) {
                when 'Australia' {
                    facultyCode = FACULTY_AUST;
                    aouCode = AOU_AUST;
                }
                when 'Indonesia' {
                    facultyCode = FACULTY_MI ;
                    aouCode = AOU_MI;
                }
                when 'Malaysia' {
                    facultyCode = FACULTY_MLAY ;
                    aouCode = AOU_MLAY;
                }
                when 'China' {
                    facultyCode = FACULTY_MSRI ;
                    aouCode = AOU_MSRI;
                }
            }

            List<Map<String, String>> values = new List<Map<String, String>>();

           // Query the records from the specified object
            String strWhereClause ='';
            String strWhereClauseAdd = '';

            strWhereClause += '(';
            strWhereClause += 'Graduate_Research_Available_Country__c INCLUDES (\'' + aouCode + '\') AND Parent_Account_Override__r.Id = \'' + facultyId + '\'';
            strWhereClause += ') OR (';
            strWhereClause += 'Graduate_Research_Available_Country__c INCLUDES (\'' + aouCode + '\') AND (';
            strWhereClause += '(Parent.Id = \'' + facultyId + '\' AND Parent.Graduate_Research_Available_Country__c INCLUDES (\'' + facultyCode + '\')) OR ';
            strWhereClause += '(Parent.Parent.Id = \'' + facultyId + '\' AND Parent.Parent.Graduate_Research_Available_Country__c INCLUDES (\'' + facultyCode + '\')) OR ';
            strWhereClause += '(Parent.Parent.Parent.Id = \'' + facultyId + '\' AND Parent.Parent.Parent.Graduate_Research_Available_Country__c INCLUDES (\'' + facultyCode + '\'))';
            strWhereClause += ')';
            strWhereClause += ') ORDER BY Name';

            //separate query build to check if faculty is also an academic org unit
            strWhereClauseAdd += '(';
            strWhereClauseAdd += 'Graduate_Research_Available_Country__c INCLUDES (\'' + aouCode + ';' + facultyCode + '\') AND Id = \'' + facultyId + '\'';
            strWhereClauseAdd += ')';
            strWhereClauseAdd += ' ORDER BY Name';
      
            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Account')
            .queryFields(new Set<String> {'Id', 'Name'})
            .getQuery(strWhereClause);

            List<Account> searchAccounts = Database.query(dynamicSearchQuery);
            if(searchAccounts.size() > 0){
                for (Account ag : searchAccounts) {
                    Map<String, String> valueMap = new Map<String, String>();
                    valueMap.put('label', ag.Name);
                    valueMap.put('value', ag.id);
                    values.add(valueMap);
                }
            }
            //separate query run to check if faculty is also an academic org unit
            if(strWhereClauseADD != ''){
                String dynamicSearchQueryAdd = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(false)
                .querySObject('Account')
                .queryFields(new Set<String> {'Id', 'Name'})
                .getQuery(strWhereClauseAdd);
                List<Account> searchAccountsAdd = Database.query(dynamicSearchQueryAdd);
                if(searchAccountsAdd.size() > 0){
                    for (Account ag : searchAccountsAdd) {
                        Map<String, String> valueMapAdd = new Map<String, String>();
                        valueMapAdd.put('label', ag.Name);
                        valueMapAdd.put('value', ag.id);
                        values.add(valueMapAdd);
                    }
                }
            }
            return values;
            
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Get Academic Unit Values', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
	
     /**
     * @author Davey Yu
     * @description get Faculty Values
     * @date 23-SEP-2024
     * @param appCountry Application Country
     * @return List<Map<String, String>>      
	*/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getFacultyValues(String appCountry){
        try {
            //get facultyCode
            String facultyCode;
            switch on (appCountry) {
                when 'Australia' {
                    facultyCode = FACULTY_AUST;
                }
                when 'Indonesia' {
                    facultyCode = FACULTY_MI ;
                }
                when 'Malaysia' {
                    facultyCode = FACULTY_MLAY ;
                }
                when 'China' {
                    facultyCode = FACULTY_MSRI ;
                }
            }
           
            List<Map<String, String>> values = new List<Map<String, String>>();

            // Query the records from the specified object
            String strWhereClause ='';
            strWhereClause += ' Graduate_Research_Available_Country__c INCLUDES (\'' +facultyCode+ '\')';
            strWhereClause += ' ORDER BY Name';

            //Build SOQL using DynamicSoqlBuilder
            String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject('Account')
            .queryFields(new Set<String> {'Name', 'Id'})
            .getQuery(strWhereClause);

            List<Account> searchAccounts = Database.query(dynamicSearchQuery);
            searchAccounts.sort();
            for (Account ag : searchAccounts) {
               Map<String, String> valueMap = new Map<String, String>();
               valueMap.put('label', ag.Name);
               valueMap.put('value', ag.id);
               values.add(valueMap);
            }

            return values;
            
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Get Faculty Values', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @author Davey Yu
     * @description Add Application Course Preference
     * @date 23-SEP-2024
     * @param courseOfferingIds course offering ids
     * @param appId	Application Id
     * @param calendarId Scholarship round calendar id
     * @param pcDate proposed commencement date
     * @param orgUnit Academic unit
     * @param externalAttendanceText
     * @param equityScholarship
     * @param indigenousScholarship
     * @param lastAppliedDate
     * @param lastAppliedDateDesc
     * @param courseLabel Course code and course title
     * @param locationCode Location code
     * @param attendanceType Attendance Type
     * @param attendanceMode Attendance Mode
     * @param facultyId Faculty Id
     * @param citizenshipType Citizenship Type
     * @param scholarshipRound Scholarship round value text
     * @return Map<String, Object>     
	*/
    @AuraEnabled
    public static Map<String, Object> addGRTACPs(//NOPMD
        List<Id> courseOfferingIds, 
        Id appId, 
        Id calendarId, 
        Id schCalendarId, 
        Date pcDate, 
        Id orgUnit, 
        String externalAttendanceText, 
        Boolean equityScholarship, 
        Boolean indigenousScholarship, 
        Date lastAppliedDate,
        String lastAppliedDateDesc, 
        String courseLabel, 
        String locationCode, 
        String attendanceType, 
        String attendanceMode, 
        String facultyId, 
        String citizenshipType, 
        String scholarshipRound,
        Boolean acceptPriorScholarshipFlag,
        String parentAppId,
        Boolean changeToFullTime,
        Boolean masterUpgrade,
        Boolean changeToInternal,
        String schClosingMonthYear
    )
    {
        try{
        Map<String, Object> mapResults = new Map<String, Object>();
 
         //get facultyCode and aouCode
         String courseTypeHDR = CONSTANTS.COURSETYPE_GROUP_HDR;

        // calculate the offset
        Integer orderNumber = 1;
      
        // User/contact Id
        User currUser = getCurrentUser();//NOPMD
        
        String courseCode = '';
        String courseTitle = '';
        if(courseLabel != ''){
            List<String> courses = courseLabel.split('=');
                if(courses.size() > 1){
                courseCode = courses[0];
                courseTitle = courses[1];
            }

        }

        // get the reference course offerings
        List<Course_Offering__c> offerings = new List<Course_Offering__c>();
        if(!test.isRunningTest()){
        	offerings = [SELECT Id, Academic_Calendar_Type__c, Academic_CI_Sequence_Number__c,
                         Admission_Calendar_Type__c, Admission_CI_Sequence_Number__c, Attendance_Type__c, Attendance_Type_Description__c,
                         Admission_Calendar_Description__c, Course_Code__c, Course_Title__c, Course_Version_Number__c, Location_Code__c,
                         Location_Description__c, Attendance_Mode__c, Attendance_Mode_Description__c, Type_of_Place_Code__c,
                         Type_of_Place_Description__c, Unit_Set_Code__c, Unit_Set_Description__c, Unit_Set_Version__c, Course__r.Faculty__r.Name, Calendar__c
                         FROM Course_Offering__c
                         WHERE Course_Code__c =: courseCode AND Course_Title__c =: courseTitle AND Location_Code__c =: locationCode AND Attendance_Type__c = :attendanceType
                         AND Attendance_Mode__c = :attendanceMode AND Course_Type_Group__c = :courseTypeHDR AND Course__r.Faculty__c =: facultyId
                         AND Portal_Available__c=true AND Default_Admission_Category_Ind__c= true AND Active__c = TRUE
                         AND Calendar__c =: calendarId LIMIT 1];
        }else{
            			offerings = [SELECT Id, Academic_Calendar_Type__c, Academic_CI_Sequence_Number__c,
                         Admission_Calendar_Type__c, Admission_CI_Sequence_Number__c, Attendance_Type__c, Attendance_Type_Description__c,
                         Admission_Calendar_Description__c, Course_Code__c, Course_Title__c, Course_Version_Number__c, Location_Code__c,
                         Location_Description__c, Attendance_Mode__c, Attendance_Mode_Description__c, Type_of_Place_Code__c,
                         Type_of_Place_Description__c, Unit_Set_Code__c, Unit_Set_Description__c, Unit_Set_Version__c, Course__r.Faculty__r.Name, Calendar__c
                         FROM Course_Offering__c
                         WHERE Course_Code__c =: courseCode AND Course_Title__c =: courseTitle AND Location_Code__c =: locationCode
                         AND Course_Type_Group__c = :courseTypeHDR
                         AND Portal_Available__c=true AND Default_Admission_Category_Ind__c= true AND Active__c = TRUE
                         AND Calendar__c =: calendarId];
        }
                                                 
        Application__c applicationRecord = [SELECT Id, Applicant__c, Type_of_Study__c, Graduate_Research_Application_Type__c, 
                                                Apply_for_Equity_Scholarship__c, Callista_Application_Id__c, Parent_Application__c FROM Application__c WHERE Id = :appId AND Status__c = 'Draft'];

        if(!isRecordOwnedByTheUser(applicationRecord)) {
            throw new AuraHandledException('Invalid application');
        }

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
            appCourse.Scholarship_Round_Closing__c = schClosingMonthYear;
            appCourse.Course_Offering__c = selectedCourse.Id;

            if(applicationRecord.Type_of_Study__c == 'Graduate Research'){
                applicationRecord.Scholarship_Round_Description__c = scholarshipRound;
                appCourse.Proposed_Commencement_Date__c = pcDate;
                if(applicationRecord.Graduate_Research_Application_Type__c == 'Admission and Scholarship'){
                    appCourse.Calendar_Code__c = selectedCourse.Calendar__c;
                    appCourse.Scholarship_Calendar__c = schCalendarId;
                    appCourse.Academic_Org_Unit__c = orgUnit;
                    if(lastAppliedDate != null){    
                        appCourse.Has_Previous_Res_Degree_or_Scholarship__c = true;                        
                        appCourse.Previous_GRT_Application_Date__c = lastAppliedDate;
                    }
                    appCourse.Difference_of_Previous_Application__c = lastAppliedDateDesc;
                    appCourse.Justify_External_Attendance__c = externalAttendanceText;
                    appCourse.Apply_for_Indigenous_Scholarship__c = indigenousScholarship;
                    appCourse.Apply_for_Equity_Scholarship__c = equityScholarship;
                    appCourse.Graduate_Research_Application_Type__c = 'Admission and Scholarship';
                    if(checkDuplicateApplication(applicationRecord.Applicant__c, appCourse.Calendar_Code__c, appCourse.Scholarship_Calendar__c, 'Admission and Scholarship')) {
                        mapResults.put('error', 'duplicate');
                        return mapResults;
                    }
                    
                }else if(applicationRecord.Graduate_Research_Application_Type__c == 'Admission application only'){
                    appCourse.Calendar_Code__c = selectedCourse.Calendar__c;
                    appCourse.Scholarship_Calendar__c = selectedCourse.Calendar__c;
                    appCourse.Academic_Org_Unit__c = orgUnit;
                    if(lastAppliedDate != null){                   
                        appCourse.Has_Previous_Res_Degree_or_Scholarship__c = true;       
                        appCourse.Previous_GRT_Application_Date__c = lastAppliedDate;
                    }
                    appCourse.Difference_of_Previous_Application__c = lastAppliedDateDesc;
                    appCourse.Justify_External_Attendance__c = externalAttendanceText;
                    appCourse.Graduate_Research_Application_Type__c = 'Admission';
                    if(checkDuplicateApplication(applicationRecord.Applicant__c, appCourse.Calendar_Code__c, appCourse.Scholarship_Calendar__c, 'Admission')) {
                        mapResults.put('error', 'duplicate');
                        return mapResults;
                    }

                }else if(applicationRecord.Graduate_Research_Application_Type__c == 'Scholarship application only'){
                    appCourse.Calendar_Code__c = selectedCourse.Calendar__c;
                    appCourse.Scholarship_Calendar__c = selectedCourse.Calendar__c;
                    if(lastAppliedDate != null){        
                        appCourse.Has_Previous_Res_Degree_or_Scholarship__c = true;                       
                        appCourse.Previous_GRT_Application_Date__c = lastAppliedDate;
                    }
                    appCourse.Difference_of_Previous_Application__c = lastAppliedDateDesc;
                    appCourse.Apply_for_Equity_Scholarship__c = equityScholarship;
                    appCourse.Apply_for_Indigenous_Scholarship__c = indigenousScholarship;
                    appCourse.Graduate_Research_Application_Type__c = 'Scholarship';
                    appCourse.Academic_Org_Unit__c = orgUnit;
                    appCourse.Change_to_Fulltime_Flag__c = changeToFullTime;
                    appCourse.Master_Upgrade_Flag__c = masterUpgrade;
                    appCourse.Change_to_Internal_Flag__c = changeToInternal;
                    if(checkDuplicateApplication(applicationRecord.Applicant__c, appCourse.Calendar_Code__c, appCourse.Scholarship_Calendar__c, 'Scholarship')) {
                        mapResults.put('error', 'duplicate');
                        return mapResults;
                    }
                }
                
                if(acceptPriorScholarshipFlag){
                    appCourse.Accept_Fees_Prior_To_Scholarship_Flag__c = true;
                    appCourse.Accept_Fees_Prior_To_Scholarship_Date__c = Date.today();
                }
            }
                acpsToAdd.add(appCourse);
            orderNumber++;
        }
        if(acpsToAdd.size() > 0) {
            insert acpsToAdd;
        }

        if(applicationRecord.Type_of_Study__c == 'Graduate Research'){
            applicationRecord.Apply_for_Equity_Scholarship__c = equityScholarship;
                if(applicationRecord.Graduate_Research_Application_Type__c == 'Scholarship application only'){
                    if(parentAppId !=  null){
                    Application__c parentApplication = [SELECT id, Callista_Application_Id__c, Callista_Applicant_Id__c
                                                        FROM Application__C WHERE id =: parentAppId];
                        applicationRecord.Parent_Callista_Application_Id__c = parentApplication.Callista_Application_Id__c;
                        applicationRecord.Parent_Application__c = parentApplication.Id;
                        applicationRecord.Callista_Applicant_Id__c = parentApplication.Callista_Applicant_Id__c;
                    }
                }

            update applicationRecord;
        }

        // refresh the ACPS list
        List<Application_Course_Preference__c> acps = getACPs(appId);
        mapResults.put(FIELD_ACPS, acps);

        return mapResults;

        } catch (Exception e) {
            Nebula.Logger.error('Application Details Add Application Course Preference', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
	
     /**
     * @author Vishal GUpta
     * @description check duplicate application for same calendar
     * @date 7-Mar-2025
     * @param applicantId
     * @param calendarId
     * @param schCalendarId
     * @return Boolean  
	*/
    public static Boolean checkDuplicateApplication(Id applicantId, Id calendarId, Id schCalendarId, String gradResApplicationTypeOfCurrentApplication) {
        //dont check the duplicate applications if Turn_off_GR_Duplicate_Application_Check__c is checked
        if(Feature_Switch__c.getInstance().Turn_off_GR_Duplicate_Application_Check__c) {
            return false;
        }
        // Query the records from the specified object
        String strWhereClause ='';
        Set<String> acpStatusWithNoSuccess = new Set<String>{'REJECTED','VOIDED','WITHDRAWN'}; //NOPMD
        Set<String> scholOutcomesIgnore = new Set<String>{'CANCELLED', 'REJECTED'}; //NOPMD
        strWhereClause += ' Applicant__c = :applicantId AND Application__r.Status__c != \'Cancelled\' AND Outcome_Status_LOV__r.System_Code__c NOT IN :acpStatusWithNoSuccess ';        
        
        //Build SOQL using DynamicSoqlBuilder
        String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
        .showSOQLStatement(true)
        .setEnforced(false)
        .querySObject('Application_Course_Preference__c')
        .queryFields(new Set<String> {'Id', 'Graduate_Research_Application_Type__c', 'Calendar_Code__c', 'Scholarship_Calendar__c', 'Scholarship_Outcome_Status__c'})
        .getQuery(strWhereClause);

        List<Application_Course_Preference__c> lstExistingACPs = Database.query(dynamicSearchQuery);
        
        for(Application_Course_Preference__c previousACP : lstExistingACPs) {
            //*** Scholarship Only Application **/
            // compares the SCHOL to a previous Application’s Scholarship Calendar
            if(gradResApplicationTypeOfCurrentApplication == 'Scholarship') {
                if(previousACP.Scholarship_Calendar__c == schCalendarId && !scholOutcomesIgnore.contains(previousACP.Scholarship_Outcome_Status__c) && 
                    (previousACP.Graduate_Research_Application_Type__c == 'Admission and Scholarship' || previousACP.Graduate_Research_Application_Type__c == 'Scholarship')) {
                    return true;
                }
            }
            
            //***  ADM + SCHOL Application **/
            // compares the ADM to a previous Application’s Admissions Calendar
            // compares the SCHOL to a previous Application’s Scholarship Calendar
            // IF any of the 2 is matching, the new application will be blocked
            else if(gradResApplicationTypeOfCurrentApplication == 'Admission and Scholarship') {
                if(((previousACP.Graduate_Research_Application_Type__c == 'Admission' || previousACP.Graduate_Research_Application_Type__c == 'Admission and Scholarship') && previousACP.Calendar_Code__c == calendarId) || 
                        ((previousACP.Graduate_Research_Application_Type__c == 'Admission and Scholarship' || previousACP.Graduate_Research_Application_Type__c == 'Scholarship') && previousACP.Scholarship_Calendar__c == schCalendarId && !scholOutcomesIgnore.contains(previousACP.Scholarship_Outcome_Status__c))) {
                    return true;    
                }
            }

            //***  Admissions Only Application **/
            // compares to a previous Application’s Admissions Calendar
            else if(gradResApplicationTypeOfCurrentApplication == 'Admission') {
                if(previousACP.Calendar_Code__c == calendarId && (previousACP.Graduate_Research_Application_Type__c == 'Admission and Scholarship' || previousACP.Graduate_Research_Application_Type__c == 'Admission')) {
                    return true;
                }
            }
        } 
        return false;
    }
	
     /**
     * @author Davey Yu
     * @description Cancel Application Course Preference
     * @date 23-SEP-2024
     * @param acpId Application Course Preference Id
     * @param appId Application Id
     * @return Map<String, String>  
	*/
    @AuraEnabled
    public static Map<String, Object> removeACP(Id acpId, Id appId)
    {
        try{
        Map<String, Object> mapResults = new Map<String, Object>();

        //authentication for the applicant
        Application__c app = [SELECT Applicant__c FROM Application__c WHERE Id=:appId AND Status__c = 'Draft'];
        if(!isRecordOwnedByTheUser(app)) {
            throw new AuraHandledException('Invalid application');
        }

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
        } catch (Exception e) {
            Nebula.Logger.error('Application Details Remove Application Course Preference', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
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
                                 SELECT Id, Campus_Location__c, createdby.Profile.name, Residency_Status__c, Type_of_Study__c,Source_System__c, Duration_of_Study__c, Graduate_Research_Application_Type__c
                                 FROM Application__c
                                 WHERE Id = :appId
                             ][0];
            appWrapper.strCreatedBy = appWrapper.app.createdby.Profile.name;
            return appWrapper;
        }
    }
	
     /**
     * @author Davey Yu
     * @description Format Date for Scholarship Rounds
     * @date 23-SEP-2024
     * @param inputDate commencement dates
     * @return String    
	*/
   	private static String formatDate(Date inputDate) {
        // Create a list of month names
        List<String> monthNames = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June', 
            'July', 'August', 'September', 'October', 'November', 'December'
        };
        
        // Extract the day, month, and year from the date
        Integer day = inputDate.day();
        Integer month = inputDate.month();
        Integer year = inputDate.year();
        
        // Determine the suffix for the day
        String suffix;
        if (day >= 11 && day <= 13) {
            suffix = 'th';
        } else {
            Integer mod = math.mod(day, 10);
            if(mod == 1){
                suffix = 'st';
            }else if(mod == 2){
                suffix = 'nd';
            }else if(mod==3){
                suffix = 'rd';
            }else{
                suffix = 'th';
            }
        }
        // Format the date as "Month DaySuffix, Year"
        String formattedDate = monthNames[month - 1] + ' ' + day + suffix + ', ' + year;
        return formattedDate;
    }

    /**
     * @author Davey Yu
     * @description Split course code and course title to be used in the query
     * @date 02-OCT-2024
     * @param courseLabel course code or course title
     * @param courseDetail course code and course title
     * @return String    
	*/
    private static string getCourseDetails(String courseLabel, String courseDetail){
        String courseVal = '';
        if(courseLabel != '' || courseLabel != null){
            List<String> courses = courseDetail.split('=');
            if(courses.size() > 0){
                if(courseLabel == COURSE_CODE){
                    courseVal = courses[0];
                }
                if(courseLabel == COURSE_TITLE){
                    courseVal =  courses[1];
                }
            }

        }
        return courseVal;
    }

    //START OF V2 UPDATES
    /**
     * @author Davey Yu
     * @description get HDR courses
     * @date 1-OCT-2024
     * @param contactId Contact Id
     * @return List<Map<String, String>>      
	*/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCourseAttempts(String contactId){
        try {
            
            //get facultyCode and aouCode
            String courseTypeHDR = CONSTANTS.COURSETYPE_GROUP_HDR;

            List<Map<String, String>> searchResults = new List<Map<String, String>>();
            List<String> courseAttemptStatus = new List<String>();
            courseAttemptStatus.add('Enrolled');
            courseAttemptStatus.add('Inactive');
            if(contactId != null){
                List<Course_Attempt__c> courseAttempts = [SELECT id, Contact__c, Course__c, course__r.Level__c, Course__r.Faculty__c, Application_Course_Preference__c, Application_Course_Preference__r.Application__c , Course__r.Short_Title__c, 
                                                            Application_Course_Preference__r.Course_Offering__r.Course_Type_Group__c, Application_Course_Preference__r.Course_Offering__r.Faculty__c, 
                                                            Application_Course_Preference__r.Attendance_Mode__c, Application_Course_Preference__r.Attendance_Type__c, Application_Course_Preference__r.Location_Code__c, 
                                                            Application_Course_Preference__r.Academic_Org_Unit__c, Course__r.Course_Full_Description__c
                                                            FROM Course_Attempt__c
                                                            WHERE  Course_Attempt_Status__c IN :courseAttemptStatus AND Contact__c =: contactId AND course__r.Level__c =: courseTypeHDR AND Campus_Country__c = 'AUSTRALIA' 
                                                            ORDER BY createdDate DESC];
                                                            

                for(Course_Attempt__c attempts: courseAttempts){
                    Map<String, String> objCourse = new Map<String, String>();
                    objCourse.put('label', attempts.course__r.Course_Full_Description__c);
                    objCourse.put('value', attempts.id);
                    searchResults.add(objCourse);
                }
            }
            return searchResults;
        } catch (Exception e) {
            Nebula.Logger.error('Application Details get course attempts picklist values', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @author Davey Yu
     * @description get HDR courses
     * @date 2-OCT-2024
     * @param attemptId course attempt id
     * @return Map<String, Object>>      
	*/
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCourseAttemptsDetails(String attemptId){
        try {
            Map<String, Object> mapResults = new Map<String, Object>();
            if(attemptId != null){
                List<Course_Attempt__c> courseAttempts = [SELECT id, Contact__c, Course__c, Course__r.Level__c, Course__r.Faculty__c, Course__r.Faculty__r.Name, 
                                                            Application_Course_Preference__r.Course_Code__c, 
                                                            Application_Course_Preference__r.Course_Title__c, Application_Course_Preference__c, 
                                                            Application_Course_Preference__r.Application__c , Course__r.Short_Title__c, 
                                                            Application_Course_Preference__r.Course_Offering__r.Course_Type_Group__c, 
                                                            Application_Course_Preference__r.Course_Offering__r.Faculty__c, 
                                                            Application_Course_Preference__r.Attendance_Mode__c, 
                                                            Application_Course_Preference__r.Attendance_Type__c, 
                                                            Application_Course_Preference__r.Attendance_Mode_Description__c, 
                                                            Application_Course_Preference__r.Attendance_Type_Description__c,
                                                            Application_Course_Preference__r.Location_Code__c, 
                                                            Application_Course_Preference__r.Academic_Org_Unit__c,
                                                            Application_Course_Preference__r.Course_Offering__r.Course_Type__c 
                                                            FROM Course_Attempt__c
                                                            WHERE  Id =: attemptId                                                            
                                                            ORDER BY createdDate DESC];
                mapResults.put('CourseAttempts', courseAttempts[0]);
            }
            return mapResults;
        } catch (Exception e) {
            Nebula.Logger.error('Application Details get course attempt selected details', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static String makeCampusLocationClause(String appCampusLocation) {
        String sQuery = '';
        //Populate locations 
        locations.add(malaysia);
        locations.add(indonesia);
        locations.add(MCJAKARTA);
        locations.add(PRATO);
        locations.add(ONLINEA);
        locations.add(china);
        locations.add(msri);
        if (appCampusLocation == 'Australia') {
            sQuery = ' AND (NOT Location_Code__c IN :locations) AND (NOT Location_Code__c LIKE :mufy) AND (NOT Location_Code__c LIKE :os) ';
        } else if (appCampusLocation == malaysia) {
            sQuery = ' AND Location_Code__c = :malaysia ';
        } else if (appCampusLocation == indonesia) { 
            sQuery = ' AND Location_Code__c = :indonesia ';
        } else if (appCampusLocation ==  china){
            sQuery = ' AND Location_Code__c = :msri ';
        }
        return sQuery;
    }

    /**
     * @author      Vishal Gupta
     * @description method to check if the application is related to the logged in user
     * @revision    31/3/2025 - Initial Version
    */
    private static boolean isRecordOwnedByTheUser(Application__c app){
        MyAppApplicationAuthenticator checker = new MyAppApplicationAuthenticator(app);
        if (checker.isRecordRelatedToCurrentUser()) {
            return true;
        } else {
            return false;
        }
    }
    
    /**
     * @author       Neeraj
     * @description  method to convert a given DateTime to the specified timezone
     * @param        inputDateTime The DateTime to convert.
 	 * @param        timezoneId The target timezone ID (e.g. 'Australia/Sydney').
     * @return       DateTime converted to the target timezone.
    */
    
    public static DateTime convertToTimezone(DateTime inputDateTime, String timezoneId){
        
    	if (inputDateTime == null || String.isBlank(timezoneId)) {
        	return null;
    	}

    	TimeZone tz = TimeZone.getTimeZone(timezoneId);

    	DateTime convertedDateTime = inputDateTime.addSeconds(tz.getOffset(inputDateTime)/ 1000);

    	return convertedDateTime;
	}
}