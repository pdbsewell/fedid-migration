/**
 * @author          PwC
 * @description     Services class to implement Course__c logic
 * @revision        24/04/2018 - PwC- Initial version
 * 				    25/04/2018 - Stefan Scheit - Added header and trigger handler logic i.e. updateFields()
 * 					01/08/2018 - Nick Guia - Added LinkCourseMaster, RollupLatestCourse, 
 *                                           getExistingCourseMaster, and CourseMasterWrapper (DCXCRM-1975)
 *                  14/08/2018 - Added Capturing of Latest Active Course Version (DCXCRM-1986)
 * 					23 Nov 2020 Martin Cadman - Added faculty lookup. Because this is done in a 'before' context, a lookup must be done. You can not use the 
 *                                              = new Account() method. However, this approach does protect from a non-existant orig unit.
 */
public class CourseServices {        
	
    /**
    * @author          PwC
    * @description     returns a map of course information that is indexed by course code
    * @revision        24/04/2018 - PwC - Initial version
    */
    public static Map<String,Course__c> CourseInfoByName {
        get{
            if(CourseInfoByName == null){
                CourseInfoByName = new Map<String,Course__c>();
                for(List<Course__c> courses: [select id,
                                               name,
                                               Course_Description__c
                                       		   from Course__c limit 2000]){
                     for(Course__c course : courses) CourseInfoByName.put(course.name, course);
                }
            }
            return CourseInfoByName;
        }
        private set;
    }

    /**
     * @author Nick Guia
     * @description for getting all existing Course Masters based on Course Code
     * @param courseList - list of Course records to check
     * @return map of existing Course Master records by Course Code
     * @revision
     *  01/08/2018  Nick Guia   - Initial Version
     */
    public static Map<String, Course_Master__c> getExistingCourseMaster(List<Course__c> courseList) {
        Map<String, List<Course__c>> courseMapByCode = 
            (Map<String, List<Course__c>>) CommonUtilities.addListToMapByKey(courseList, 'Name');
        Map<String, Course_Master__c> courseMasterByName = new Map<String, Course_Master__c>();

        for(Course_Master__c cm : [SELECT Id, Course_Code__c, Name
                                FROM Course_Master__c 
                                WHERE Course_Code__c IN :courseMapByCode.keySet()]) 
        {
            courseMasterByName.put(cm.Course_Code__c, cm);
        }
        return courseMasterByName;
    }
 
    /**
    * @author           Stefan Scheit
    * @description      Public method to encapsulate the logic of deriving a (unique) course version id
    * @revision         25/04/2018 - Handler logic added
    */
    public static String getCourseCodeUnique(String name, String version) {
        return name + '_' + version;
    }
    public static String getCourseCodeUnique(String name, Decimal version) {
        return name + '_' + version;
    }
 
    /**
    * @author           Stefan Scheit
    * @description      Handler implementation to set fields
    * @revision         25/04/2018 - Handler logic added
    */
    public class UpdateFieldsHandler implements Triggers.Handler {
        public void run() {
            if (Trigger.isDelete) {
                return; // no action required
            }

            List<Course__c> courseList = (List<Course__c>) Trigger.new;
            Map<String, Id> aID = new MAP<String, Id>();
            List<String> facultyCode = new List<String>();

            // Populate a list of all org units in the batch
            for (Course__c c : courseList) {
                if (c.Faculty_Code__c != null) { facultyCode.add(c.Faculty_Code__c); }
                if (c.Partner_Faculty_Code__c != null) { facultyCode.add(c.Partner_Faculty_Code__c); }
            }

            // Get the account id for each org unit
            for (Account a : [SELECT Id, Callista_Org_Unit_Code__c FROM Account WHERE Callista_Org_Unit_Code__c in :facultyCode]){
				aID.put(a.Callista_Org_Unit_Code__c, a.id);
            }
            
            for (Course__c iCourse : courseList) {
 				// Standardise the course name
                iCourse = this.updateFields(iCourse);
				
                // Apply the account id for the faculty
                iCourse.Faculty__c = aID.get(iCourse.Faculty_Code__c);
                iCourse.Partner_Faculty__c = aID.get(iCourse.Partner_Faculty_Code__c);
            }
        }
        
        // (Re-usable) method to set fields
        @TestVisible
        private Course__c updateFields(Course__c course) {           
            if (course!=null) {
                // set course code if it is different to the course type "Course-Published" OR if course type is null 
               if(((course.Course_Type__c==null) || !course.Course_Type__c.equalsIgnoreCase(JobTriggerHandler.fieldValue)) && course.Version__c!=null ) {
                    course.Course_Code__c = CourseServices.getCourseCodeUnique(course.Name, course.Version__c);
                }
            }
            return course;
        }
    }

    /**
     * @author Nick Guia
     * @description Entry criteria:
     *               - All new inserts with type 'Course-All' or 'Short Course' must run the checking.
     *                 on if a Course Master for the corresponding Course Code already exists.
     *               - if the Course Code (Name) was updated, run the check for existing Course Master.
     *               - If Bypass Course Rollup Entry Criteria Custom Setting is on, always run this (for migration)
     *              Assumption: Course Type will never change.
     * @revision     
     *   01/08/2018  Nick Guia   Initial version (DCXCRM-1975)
     */
    public class LinkCourseMaster implements Triggers.Handler {
        private List<Course__c> checkCourseList;
        private Map<String, Course_Master__c> cmByCode; //Course Master map by Code

        public void run() {
            Environment_Settings__c envSettings = Environment_Settings__c.getOrgDefaults();

            checkCourseList = new List<Course__c>();
            //entry criteria
            if(Trigger.isInsert) {
                //All new inserts with type 'Course-All' or 'Short Course' must run the check.
                //OR if Bypass Course Rollup Entry Criteria Custom Setting is on
                for(Course__c iCourse : (List<Course__c>) Trigger.new) {
                    if((iCourse.Type__c == Label.Course_Type_Course_All || iCourse.Type__c == Label.Course_Type_Short_Course)
                        || envSettings.Bypass_Course_Master_Rollup_Criteria__c)
                    {
                        checkCourseList.add(iCourse);
                    }
                }
            } else if(Trigger.isUpdate) {
                //check if Course Code was updated
                for(Course__c iCourse : (List<Course__c>) Trigger.new) {
                    Course__c oldCourse = (Course__c) Trigger.oldMap.get(iCourse.Id);
                    if(iCourse.Name != oldCourse.Name || envSettings.Bypass_Course_Master_Rollup_Criteria__c) {
                        checkCourseList.add(iCourse);
                    }
                }
            }

            if(!checkCourseList.isEmpty()) {
                cmByCode = new Map<String, Course_Master__c>(); //instantiate, so will never be null
                cmByCode = getExistingCourseMaster(checkCourseList);
                createLinkCourseMaster(checkCourseList, cmByCode);
            }
        }

        /**
         * Link Courses to it's Course Master if it exists, Otherwise
         * create a new Course Master and link the courses. This method will call itself
         * if there are still Courses that doesn't have a Course Master
         */
        private void createLinkCourseMaster(List<Course__c> checkCourseList,
                                            Map<String, Course_Master__c> cMasterByCode) 
        {
            Map<String, List<Course__c>> courseMapByCode = 
                (Map<String, List<Course__c>>) CommonUtilities.addListToMapByKey(checkCourseList, 'Name');

            List<Course__c> orphanCourses = new List<Course__c>();
            Map<String, Course_Master__c> newCMByCode = new Map<String, Course_Master__c>();

            
            for(String iCode : courseMapByCode.keySet()) {
                if(cMasterByCode.containsKey(iCode)) {
                    //if Course Master already exists for this code, link the corresponding Courses
                    for(Course__c iCourse : courseMapByCode.get(iCode)) {
                        iCourse.Course_Master__c = cMasterByCode.get(iCode).Id;
                    }
                } else {
                    //collect all orphan Courses
                    List<Course__c> newCourses = courseMapByCode.remove(iCode);
                    orphanCourses.addAll(newCourses);
                    newCMByCode.put(iCode, new Course_Master__c(Course_Code__c = iCode, Name = iCode));
                }
            }

            try {
                //insert new Course Masters and re-run this method to assign Courses
                if(!newCMByCode.isEmpty()) {
                    insert newCMByCode.values();
                    //re-run this method
                    createLinkCourseMaster(orphanCourses, newCMByCode);
                }
            } catch(Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();                
            }
            
        }
    }

    /**
     * @author Nick Guia
     * @description Code logic to rollup the latest version of Course to Course Master
     *              Assumption: Course Type will never change.
     * @revision     
     *   01/08/2018  Nick Guia   Initial version (DCXCRM-1975)
     */
    public class RollupLatestCourse implements Triggers.Handler {
        public void run() {
            Environment_Settings__c envSettings = Environment_Settings__c.getOrgDefaults();
            Set<String> courseCodes = new Set<String>();
            Set<String> courseStatusChanged = new Set<String>();
            Set<Id> cmIds = new Set<Id>();
            //entry criteria
            if(Trigger.isInsert) {
                //All new inserts with type 'Course-All' or 'Short Course' must run the check.
                //OR if Bypass Course Rollup Entry Criteria Custom Setting is on
                for(Course__c iCourse : (List<Course__c>) Trigger.new) {
                    if((iCourse.Type__c == Label.Course_Type_Course_All || iCourse.Type__c == Label.Course_Type_Short_Course)
                        || envSettings.Bypass_Course_Master_Rollup_Criteria__c)
                    {
                        courseCodes.add(iCourse.Name);
                    }
                }
            } else if(Trigger.isUpdate) {
                /**
                 * check if the following fields were updated:
                 * Course_Master__c, Version__c
                 * OR envSettings.Bypass_Course_Master_Rollup_Criteria__c = true
                 */
                for(Course__c iCourse : (List<Course__c>) Trigger.new) {
                    Course__c oldCourse = (Course__c) Trigger.oldMap.get(iCourse.Id);
                    if((iCourse.Course_Master__c != oldCourse.Course_Master__c || iCourse.Version__c != oldCourse.Version__c)
                        || envSettings.Bypass_Course_Master_Rollup_Criteria__c) 
                    {
                        courseCodes.add(iCourse.Name);
                        if(oldCourse.Course_Master__c != null) {
                            //collect the IDs of old Course Masters as they need to be re-evaluated
                            cmIds.add(oldCourse.Course_Master__c);
                        }
                    } else if(iCourse.Status__c != oldCourse.Status__c) { //if only status changed
                        courseStatusChanged.add(iCourse.Name);
                    }
                }
            }

            if(!courseCodes.isEmpty() || !courseStatusChanged.isEmpty()) {
                /** 
                 * assumption at this point is that Course Master map will never 
                 * be null and they have been created in before insert/update
                 */
                List<Course_Master__c> cmUpdateList = new List<Course_Master__c>();
                for(Course_Master__c cm : [SELECT Id, Course_Code__c, Latest_Course_Version__c,
                                            Latest_Active_Course_Version__c, Name,
                                            (SELECT Id, Version__c, Status__c
                                            FROM Courses__r 
                                            WHERE Version__c != NULL)
                                        FROM Course_Master__c 
                                        WHERE (Course_Code__c IN :courseCodes 
                                            OR Course_Code__c IN :courseStatusChanged)
                                        OR Id IN :cmIds])
                {
                    if(!cm.Courses__r.isEmpty()) {
                        CourseMasterWrapper cmw = new CourseMasterWrapper(cm);
                        cmw.addCourses(cm.Courses__r);
                        //if this is a new insert, or Course Master or Version is changed
                        if(courseCodes.contains(cm.Course_Code__c)) {
                            Boolean isUpdated = false;
                            //try to update is Latest Course Version
                            isUpdated = isUpdateLatestCourseVersion(cmw);
                            //try to update is Latest Course Active Version
                            isUpdated = (isUpdateLatestCourseActiveVersion(cmw)) ? true : isUpdated;
                            if(isUpdated) cmUpdateList.add(cmw.cMaster);
                        //if Status is changed
                        } else if(courseStatusChanged.contains(cm.Course_Code__c)) {
                            if(isUpdateLatestCourseActiveVersion(cmw)) {
                                cmUpdateList.add(cmw.cMaster);
                            }
                        }
                        
                    } else {
                        /**
                         * no more Courses associated to this Course Master. Update the
                         * Latest Course Version and Latest Active Course Version to null
                         */
                        cm.Latest_Course_Version__c = null;
                        cm.Latest_Active_Course_Version__c = null;
                        cmUpdateList.add(cm);
                    }
                }

                try {
                    if(!cmUpdateList.isEmpty()) update cmUpdateList;
                } catch(Exception ex) {
                    nebula.logger.exception(ex.getMessage(), ex);
                } finally {
                    nebula.logger.saveLog();                
                }
            }
        }

        /**
         * @description Try to update Course Master's Latest Course Active Version if
         *              not already is. Leverages CourseMasterWrapper's method to get
         *              the latest active course version
         */
        private Boolean isUpdateLatestCourseActiveVersion(CourseMasterWrapper cmw) {
            Boolean isUpdated = false;
            cmw.getLatestActiveCourseVersion();
            //only update Course Master if this is not the latest active course version
            if(cmw.latestActiveCourseVersion != null &&
               cmw.latestActiveCourseVersion.Id != cmw.cMaster.Latest_Active_Course_Version__c)
            {
                cmw.cMaster.Latest_Active_Course_Version__c = cmw.latestActiveCourseVersion.Id;
                isUpdated = true;
            } else if(cmw.latestActiveCourseVersion == null) {
                //no remaining active course
                cmw.cMaster.Latest_Active_Course_Version__c = null;
                isUpdated = true;
            }
            return isUpdated;
        }
        /**
         * @description Try to update Course Master's Latest Course Version if
         *              not already is. Leverages CourseMasterWrapper's method to get
         *              the latest course version
         */
        private Boolean isUpdateLatestCourseVersion(CourseMasterWrapper cmw) {
            Boolean isUpdated = false;
            cmw.getLatestCourseVersion();

            //only update Course Master if this is not the latest course version
            if(cmw.latestCourseVersion != null && 
               cmw.latestCourseVersion.Id != cmw.cMaster.Latest_Course_Version__c) 
            {
                cmw.cMaster.Latest_Course_Version__c = cmw.latestCourseVersion.Id;
                isUpdated = true;
            }
            return isUpdated;
        }
    }

    //Wraps Course Master and all it's child Courses
    public class CourseMasterWrapper {
        public Course_Master__c cMaster {get; set;}
        public Map<Integer, Course__c> courseByVersion {get; set;}
        public Course__c latestCourseVersion {get; set;}
        public Course__c latestActiveCourseVersion {get; set;}

        //constructor
        public CourseMasterWrapper(Course_Master__c cMaster) {
            this.cMaster = cMaster;
            this.courseByVersion = new Map<Integer, Course__c>();
        }

        /** 
         * @description add courses with the same course code and map them by version
         *              up0dates the courseByVersion attribute
         */
        public void addCourses(List<Course__c> courseList) {
            for(Course__c iCourse : courseList) {
                if(String.isNotBlank(iCourse.Version__c)) {
                    this.courseByVersion.put(Integer.valueOf(iCourse.Version__c), iCourse);
                }
            }
        }

        /** 
         * @description get the latest version of child courses and roll up ID to Course Master
         *              updates the latestCourseVersion attribute
         */
        public void getLatestCourseVersion() {
            if(!this.courseByVersion.isEmpty()) {
                List<Integer> versions = sortCourseVersions();
                if(!versions.isEmpty()) {
                    this.latestCourseVersion =  this.courseByVersion.get(versions[versions.size()-1]); //get last value (max)
                } 
            }
        }
        /** 
         * @description get the latest version of child courses whose status = 'Active'
         *              updates the latestActiveCourseVersion attribute
         */
        public void getLatestActiveCourseVersion() {
            List<Integer> versions = sortCourseVersions();
            if(!versions.isEmpty()) {
                for(Integer i = versions.size()-1; i >= 0; i --) { //start checking from end of list
                    Course__c iCourse = this.courseByVersion.get(versions[i]);
                    if(iCourse.Status__c == Label.Course_Status_Active) {
                        this.latestActiveCourseVersion = iCourse; //once latest active is found, exit loop
                        break;
                    }
                }
            }
        }
        /** 
         * @description private reusable logic for sorting Course versions in
         *              ascendin order.
         */
        private List<Integer> sortCourseVersions() {
            List<Integer> versions = new List<Integer>();
            if(!this.courseByVersion.isEmpty()) {
                versions.addAll(this.courseByVersion.keySet()); //sort in ascending order
                versions.sort();
            }
            return versions;
        }
    }
}