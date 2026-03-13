/**
 * @author Trent De Laney
 * @date 27 Aug 2019 at 2:58:55 pm
 * @group Controller
 * @description Used for searching and accessing the course offering objects within Salesforce and creating/updating these as ACP records attached to an application
 * @Revision    Shalini Mendu - Fixing SFTN-285,275,286,296,300,299, 310
 * @Revision    31/Oct/2019 - Shalini Mendu - SFTN-342(Unit Set Description is not passed on ACP)
 *              06/11/2019 - Kristian Vegerano - addACPs(Id, String) - updated preference rank calculation - ordering by preference rank bugs out because the field is a text field
 *              21/07/2022 - Vinothraja - SFTG-2797 - Used DynamicSoqlBuilder for query generation
 */
public with sharing class CourseOfferingCC {

    //Concrete Class
    @TestVisible
    private class SearchCriteria {
        public String courseCode;
        public String courseName;
        public String intakePeriod;
        public String attendanceMode;
        public String location;
    }


    @AuraEnabled
    public static Map<String, List<String>> seedComponent() {
        Map<String, List<String>> searchComponents = new Map<String, List<String>>();

        searchComponents.put('Course_Code__c', getValues('Course_Code__c', 'Course_Offering__c'));
        searchComponents.put('Course_Title__c', getValues('Course_Title__c', 'Course_Offering__c'));
        searchComponents.put('Attendance_Mode__c', getValues('Attendance_Mode__c', 'Course_Offering__c'));
        searchComponents.put('Location_Description__c', getValues('Location_Description__c', 'Course_Offering__c'));

        return searchComponents;
    }

    /**
    * @author Trent De Laney
    * @description Searches for active course offering records and returns these to the front end for selection
    * @date 27 Aug 2019 at 3:00:42 pm
    * @return List<Course_Offering__c> courseOfferings
    */
    @AuraEnabled
    public static List<Course_Offering__c> searchCourseOffering(String newSearch) {
        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();
        try {

            CourseOfferingCC.SearchCriteria search = (CourseOfferingCC.SearchCriteria) JSON.deserialize(newSearch, CourseOfferingCC.SearchCriteria.class);
            ExLog.add('', '', '', search.toString());
            String strWHERE = ' Active__c = TRUE AND ';
                        
            if(String.isNotBlank(search.courseName) && String.isNotBlank(search.courseCode)) {
                String courseName = String.escapeSingleQuotes(search.courseName);
                String courseCode = String.escapeSingleQuotes(search.courseCode);
                strWHERE +='(Course_Title__c = :courseName AND Course_Code__c = :courseCode)';
            } else if(String.isBlank(search.courseName) && String.isNotBlank(search.courseCode)) {
                String courseCode = String.escapeSingleQuotes(search.courseCode);
                strWHERE +='(Course_Code__c = :courseCode)';
            } else if(String.isNotBlank(search.courseName) && String.isBlank(search.courseCode)) {
                String courseName = String.escapeSingleQuotes(search.courseName);
                strWHERE +='(Course_Title__c = :courseName)';
            }

            if(String.isNotBlank(search.location)) {
                String location = String.escapeSingleQuotes(search.location);
                strWHERE +=' AND Location_Description__c= :location';
            }

            if(String.isNotBlank(search.attendanceMode)) {
                String attendanceMode = String.escapeSingleQuotes(search.attendanceMode);
                strWHERE +=' AND Attendance_Mode__c= :attendanceMode';
            }

            String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                    .showSOQLStatement(true)
                    .setEnforced(true)
                    .querySObject('Course_Offering__c')
                    .queryFields(new Set<String> {'Id', 'Course_Code__c', 'Citizenship_Type__c', 'Admission_Calendar_Description__c', 'Attendance_Mode__c', 
                                                    'Course_Title__c', 'Faculty__c', ' Course_Version_Number__c', 'Location_Description__c', 'Commencement_Period__c', 
                                                    'Attendance_Type__c', 'Admission_Category__c', ' Admission_Calendar_Type__c', 'Attendance_Mode_Description__c', 
                                                    'Unit_Set_Code__c', 'Unit_Set_Description__c'})
                    .getQuery(strWHERE);
            System.debug('dynamicSOQL=='+dynamicSOQL);
            courseOfferings = ( List<Course_Offering__c> )Database.query(dynamicSOQL);
            System.debug('UNIT=='+courseOfferings[0].Unit_Set_Code__c);
        } catch (Exception e) {
            ExLog.add(e.getTypeName(), 'CourseOfferingCC', 'searchCourseOffering', e.getMessage());
            System.debug(e.getStackTraceString());
        }

        return courseOfferings;
    }


    /**
    * @author Trent De Laney
    * @description
    * @date 4 Sep 2019 at 8:30:59 am
    * @param
    * @return
    */
    @AuraEnabled
    public static List<Application_Course_Preference__c> getApplicationACPs(String recordId) {
        List<Application_Course_Preference__c> prefs = [
                SELECT Id, Course_Title__c, Preference_Number__c, Unique_External_Id__c
                FROM Application_Course_Preference__c
                WHERE Application__c = :recordId
        ];
        return prefs;
    }

    /********************************************************
    Look ahead functions for each of the lookups
    ********************************************************/
    public static List<String> getValues(String fieldName, String objectName) {
        List<SObject> values = Database.query('SELECT ' + fieldName + ',count(id) FROM ' + objectName + ' WHERE Active__c = TRUE GROUP BY ' + fieldName +' LIMIT 50000');
        List<String> stringValues = new List<String>();

        for (SObject s : values) {
            stringValues.add((String) s.get(fieldName));
        }

        return stringValues;
    }

    /**
    * @author Shalini Mendu
    * @description
    * @date 21 Sep 2019 at 9:30:59 am
    * @param Id - ApplicationId, selectedOfferings - Array of ACPs
    * @return
    */
    @AuraEnabled
    public static void addACPs( Id appId, String selectedOfferings)
    {
        System.debug('add acps=='+appId);
        Integer prefRec = 0;

        Set<String> ourOfferings = (Set<String>)JSON.deserialize(selectedOfferings, Set<String>.class);

        System.debug('??'+ourOfferings);
        Application__c app = [SELECT Residency_Status__c, Applicant__c,
                                     (SELECT Id, Preference_Number__c FROM Application_Course_Preferences__r ORDER BY Preference_Number__c DESC)
                              FROM Application__c 
                              WHERE ID = :appId 
                              LIMIT 1];
        //Calculate new preference rank
        if(app.Application_Course_Preferences__r != null){
            for(Application_Course_Preference__c loopAcp : app.Application_Course_Preferences__r){
                if(Integer.valueOf(loopAcp.Preference_Number__c) > prefRec){
                    prefRec = Integer.valueOf(loopAcp.Preference_Number__c);
                }
            }
        }

        // get the reference course offerings
        List<Course_Offering__c> offerings = [SELECT Id, Admission_Category__c,Academic_Calendar_Type__c, Academic_CI_Sequence_Number__c,
                Admission_Calendar_Type__c, Admission_CI_Sequence_Number__c, Attendance_Type__c, Attendance_Type_Description__c,
                Admission_Calendar_Description__c, Course_Code__c, Course_Title__c, Course_Version_Number__c, Location_Code__c,
                Location_Description__c, Attendance_Mode__c, Attendance_Mode_Description__c, Type_of_Place_Code__c,
                Type_of_Place_Description__c, Unit_Set_Code__c, Unit_Set_Description__c, Unit_Set_Version__c,
                Fee_Category__c,Enrolment_Category__c,Correspondence_Category__c,Hecs_Payment_Option__c
            FROM Course_Offering__c
        WHERE Id IN : ourOfferings];

        List<Application_Course_Preference__c> acpsToAdd = new List<Application_Course_Preference__c>();
        for(Course_Offering__c selectedCourse:offerings)
        {
            Application_Course_Preference__c appCourse = new Application_Course_Preference__c();
            appCourse.Application__c = appId;
            appCourse.Applicant__c = app.Applicant__c;
            appCourse.Status__c = 'Open';
            appCourse.Preference_Number__c = (prefRec+1)+'';
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
            appCourse.Fee_Category__c = selectedCourse.Fee_Category__c;
            appCourse.Enrolment_Category__c = selectedCourse.Enrolment_Category__c;
            appCourse.Correspondence_Category__c = selectedCourse.Correspondence_Category__c;
            appCourse.Fee_Payment_Option__c = selectedCourse.Hecs_Payment_Option__c;
            appCourse.Unit_Set_Code__c = selectedCourse.Unit_Set_Code__c;
            appCourse.Unit_Set_Description__c = selectedCourse.Unit_Set_Description__c;
            appCourse.Unit_Set_Version__c = selectedCourse.Unit_Set_Version__c;

            if (app.Residency_Status__c=='INTRNTNL'||app.Residency_Status__c=='INT-TEP'){
                appCourse.Admission_Category__c = selectedCourse.Admission_Category__c;
                appCourse.Outcome_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'AP-PROGRES' + Label.Application_Outcome_Status);
                appCourse.Conditional_Offer_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'NOT-APPLIC' + Label.Conditional_Offer_Status);
                appCourse.Deferment_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'NOT-APPLIC' + Label.Deferment_Status);
                appCourse.Documentation_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'PENDING' + Label.Documentation_Status);
                appCourse.Entry_Qualification_Status_LOV__r = new List_Of_Values__c(Unique_Key__c = 'PENDING' + Label.Entry_Qualification_Status);
                appCourse.Fee_Category__c =  selectedCourse.Fee_Category__c;
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
            prefRec = Integer.valueOf(appCourse.Preference_Number__c);
        }

        insert acpsToAdd;
        //This update calls integration
		List<Application_Course_Preference__c> acpsToUpdate = new List<Application_Course_Preference__c>();
        Application_Course_Preference__c acpUpdate;
        
        for(Application_Course_Preference__c acp : acpsToAdd){
            acpUpdate = new Application_Course_Preference__c();
            acpUpdate.Id = acp.Id;
            acpUpdate.Added_by_Assessor__c = true;
            acpsToUpdate.add(acpUpdate);
        }

        update acpsToUpdate;

    }

}