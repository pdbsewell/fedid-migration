/**
* @author Angelo Rivera
* @date 05.09.19
* @group Enquiry Management
* @description  Custom Controller Extension for use in custom service console component(s).<br/>
*               Specifically, the component that surfaces course and application information
* @revision 17/01/2019 - APRivera - Remove API calls to Callista and fully rely to CRM data. <br/>
*           23/01/2019 - APRivera - replace managing faculty by course id when searching for course. <br/>
*           06/12/2019 - APRivera - removed references of API_ResultWrapper (API.Monash) <br/>
*           20/05/2020 - APRivera - updated due to PMD error <br/>
*/

public with sharing class Console_CourseInfo_CE {

    public Case c {get; private set;}
    public String tab {get;set;} // used to retain tab context across refreshes of tabbed view
    public string courseIdSelected {get;set;}
    public boolean httpError {get;set;}
    public boolean loadAttempted {get;set;}
    public string errMessage {get;set;}
    public boolean renderTable {
        get{
            return (courseAttemptsList.size() > 0 || applicationCoursePreferencesList.size() > 0) ? true : false;
        }
    }
    public list<Unit_Attempt__c> unitEnrolementList{get; set;}
    public list<Course_Attempt__c> courseAttemptsList{get; set;}
    public list<Application_Course_Preference__c> applicationCoursePreferencesList{get; set;}

    public static Map<String, List<Course_Attempt__c>> mapCourseAttemptsByStatus = new Map<String, List<Course_Attempt__c>>();
    public List<String> courseStatusList{get; set;}


    /** updates case record when course linked/unlinked */

    private void updateCaseRecord(){
        try{
            update c;
        } catch (exception ex){
            Exlog.write('Controller Extension','Console_components_CE','updateCaseRecord',ex.getMessage());
        }
    }

    /** removes course references from the case record */

    public pageReference unlinkFromCase(){
        system.debug('>>>>>>>Unlink from case');
        c.Course__c = null;
        c.Course_Code__c = null;
        updateCaseRecord();
        return null;
    }

    /** links a course record to case, as selected from the course and/or application information surfaced in component */
    public pageReference linkToCase(){
        c.Course__c = null;
        String[] params = courseIdSelected.split(':');
        if(params[0].length() > 14) c.Course__c = params[0]; // can only link if we have a record in courses
        // Also stamp current state information onto enquiry
        c.Course_Code__c = params[1];
        Console_CourseInfo_CE.LinkCourseToCase lcc = new Console_CourseInfo_CE.LinkCourseToCase(c, courseAttemptsList,applicationCoursePreferencesList);
        return null;
    }

    /**
* custom controller extension instantiation
* @param controller standard controller
*/

    public Console_CourseInfo_CE(ApexPages.StandardController controller) {
        c = new case();
        id caseId = (id)controller.getId();
        courseStatusList = new List<String>();
        try{

            c = [Select id, Location_Code__c, Attendance_Mode__c, Attendance_Type__c, Managing_Faculty__c,
                    Home_Campus__c, contactId, contact.Person_Id__c, Course_Code__c, Course__c, Course_Linked__c, Status
            From Case
            Where id =:caseId limit 1];

            getunitEnrolementList();
            getcourseAttemptsList();
            getapplicationCoursePreferencesList();
            getCourseStatusList(courseStatusList);
        } catch (exception e){
            // deleted record, or invalid id so no further work
        }

        tab = '1'; // default
        httpError = false;
        loadAttempted = false;
        errMessage = '';
        courseIdSelected = '';

    }

    /** one of the multiple steps taken to instantiate the page information */

    public pageReference initalLoad(){
        if(c.Contact.Person_Id__c != null) {
            string process = 'populateCourses'; // in case of error reporting
            try{
                mapCourseAttemptsByStatus = buildMapCourseAttemptsByStatus(courseAttemptsList);
                if(!mapCourseAttemptsByStatus.isEmpty()){
                    autolinkToCase();
                }

            } catch (exception ex){
                httpError = true; CaseServices.storeExLog('Console_CourseInfo_CE', 'initialLoad', process , ex.getMessage());
            }

        }
        loadAttempted = true;
        return null;
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
    public static Map<String, List<Course_Attempt__c>> buildMapCourseAttemptsByStatus(List<Course_Attempt__c> lstCrsAttempts){
        Map<String, List<Course_Attempt__c>> mapCourseAttemptsByStatus = new Map<String, List<Course_Attempt__c>>();
        for (Course_Attempt__c courseAttempt : lstCrsAttempts) {
            if (!mapCourseAttemptsByStatus.containsKey(courseAttempt.Course_Attempt_Status__c.touppercase()))
                mapCourseAttemptsByStatus.put(courseAttempt.Course_Attempt_Status__c.touppercase(), new List<Course_Attempt__c>());
            mapCourseAttemptsByStatus.get(courseAttempt.Course_Attempt_Status__c.touppercase()).add(courseAttempt);
        }
        return mapCourseAttemptsByStatus;
    }

    public void autolinkToCase(){
        try{
            System.debug(LoggingLevel.INFO, '### Starting autolinkToCase ');
            Course_Attempt__c courseAttempt = new Course_Attempt__c();
            updateCaseLinkCourse(c, mapCourseAttemptsByStatus, courseAttempt, courseStatusList);
        } catch (exception ex) {
            system.debug('>>>>>Exception Occurred::'+ex);
        }
    }

    //actual update on case where course is linked
    public static void updateCaseLinkCourse(Case componentEnquiry, Map<String, List<Course_Attempt__c>> mapCourseAttemptsByStatus, Course_Attempt__c courseAttempt, List<String> courseStatusList){
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

    //Update Enquiry with the new linked Course
    public static void updateEnquiryWithCourseLink(Case componentEnquiry, Course_Attempt__c courseAttempt) {
        Console_CourseInfo_CE.EnquiryUpdate eu =  new Console_CourseInfo_CE.EnquiryUpdate(componentEnquiry, courseAttempt);
    }

    //retrieve Unit Enrolments
    public list<Unit_Attempt__c> getunitEnrolementList(){
        try{
            if(unitEnrolementList == Null) {
                unitEnrolementList =  new list<Unit_Attempt__c>();
                unitEnrolementList = [select Name,Academic_Year__c,Unit_Code__c,Course_Code__c,Status__c, Calendar_Type__c from Unit_Attempt__c 
                                       where Student__c =:c.contactId ORDER BY Academic_Year__c DESC];
                return unitEnrolementList;
            }
        } catch (exception ex) {
            system.debug('>>>> Exception Occurred ::'+ex);
        } return null;
    }

    //retrieve Course Attempts
    public List<Course_Attempt__c> getcourseAttemptsList(){
        try{
            if(courseAttemptsList == Null) {
                courseAttemptsList =  new List<Course_Attempt__c>();
                courseAttemptsList = [Select Id, Name, Course__c, Course_Code__c, Course_Attempt_Status__c, Attendance_Type__c, Attendance_Mode__c, Location__c, Course_Managing_Faculty__c, Course_Short_Title__c
                From Course_Attempt__c
                Where Contact__c =:c.contactId ];
                return courseAttemptsList;
            }
        } catch (exception ex) {
            system.debug('>>>> Exception Occurred ::'+ex);
        } return null;
    }

    //retrieve Application Course Preferences
    public List<Application_Course_Preference__c> getapplicationCoursePreferencesList(){
        try{
            if(applicationCoursePreferencesList == Null) {
                applicationCoursePreferencesList =  new List<Application_Course_Preference__c>();
                applicationCoursePreferencesList = [Select Id, Name, Managing_Faculty_Text__c, Course__c, Course_Title__c, Course_Code__c, Outcome_Status__c, Offer_Response_Status__c,
                        Attendance_Mode__c, Attendance_Type__c, Location_Code__c
                From Application_Course_Preference__c
                Where Applicant__c =:c.contactId and Applicant__c != null];
                return applicationCoursePreferencesList;
            }
        } catch (exception ex) {
            system.debug('>>>> Exception Occurred ::'+ex);
        } return null;
    }

    public without sharing class EnquiryUpdate {
        public EnquiryUpdate(Case componentEnquiry, Course_Attempt__c courseAttempt){
            try{
                if (courseAttempt != null) {
                    componentEnquiry.Course__c = courseAttempt.Course__c;
                    componentEnquiry.Course_Code__c = courseAttempt.Course_Code__c;
                    componentEnquiry.Location_Code__c = courseAttempt.Location__c;
                    componentEnquiry.Attendance_Mode__c = courseAttempt.Attendance_Mode__c;
                    componentEnquiry.Attendance_Type__c = courseAttempt.Attendance_Type__c;
                    componentEnquiry.Managing_Faculty__c = courseAttempt.Course_Managing_Faculty__c;
                    componentEnquiry.Home_Campus__c = courseAttempt.Location__c;
                    componentEnquiry.Course_Attempt_Status__c = courseAttempt.Course_Attempt_Status__c;
                    componentEnquiry.Campus__c = courseAttempt.Location__c;
                    componentEnquiry.Course_Linked__c = true; // APRivera - 03/05/2018 - DCXCRM-1690 - Fix on incorrect 'Last Modified by' value
                    updateCase(componentEnquiry);
                }
            } catch (exception ex) {
                System.debug(LoggingLevel.ERROR, String.valueOf(Console_CourseInfo_CE.class)+': the Case record ['+componentEnquiry.Id+'] could not be updated due to error: '+ ex.getMessage());
            }
        }
    }

    public without sharing class LinkCourseToCase {
        public LinkCourseToCase(Case c, List<Course_Attempt__c> courseAttemptsList, List<Application_Course_Preference__c> applicationCoursePreferencesList){
            Boolean courseMatched = false;
            if(courseAttemptsList.isEmpty()) courseAttemptsList = new List<Course_Attempt__c>();
            for(Course_Attempt__c ca : courseAttemptsList){
                if(ca.Course_Code__c == c.Course_Code__c){
                    c.Course__c = ca.Course__c;
                    c.Location_Code__c = ca.Location__c;
                    c.Attendance_Mode__c = ca.Attendance_Mode__c;
                    c.Attendance_Type__c = ca.Attendance_Type__c;
                    c.Home_Campus__c = ca.Location__c;
                    c.Course_Attempt_Status__c = ca.Course_Attempt_Status__c;
                    courseMatched = true; break;
                }
            }
            if(!courseMatched ){
                if(applicationCoursePreferencesList.isEmpty()) applicationCoursePreferencesList = new List<Application_Course_Preference__c>();
                for(Application_Course_Preference__c ca : applicationCoursePreferencesList){
                    if(ca.Course_Code__c == c.Course_Code__c){
                        c.Course__c = ca.Course__c;
                        c.Location_Code__c = ca.Location_Code__c;
                        c.Attendance_Mode__c = ca.Attendance_Mode__c;
                        c.Attendance_Type__c = ca.Attendance_Type__c;
                        c.Application_Outcome_Status__c = ca.Outcome_Status__c;
                        c.Application_Response_Status__c = ca.Offer_Response_Status__c;
                        break;
                    }
                }
            }
            updateCase(c);
        }
    }

    public static void updateCase(Case caseRecord){
        try{
            update caseRecord;
        } catch(exception ex){
            System.debug(LoggingLevel.ERROR, String.valueOf(Console_CourseInfo_CE.class)+': the Case record ['+caseRecord.Id+'] could not be updated due to error: '+ ex.getMessage());
        }
    }

}