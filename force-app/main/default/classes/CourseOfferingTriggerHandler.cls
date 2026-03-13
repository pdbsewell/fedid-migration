/**
 * @File Name          : CourseOfferingTriggerHandler.cls
 * @Description        : 
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 3/12/2020, 12:44:54 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    3/12/2020   jasmin.rudio@monash.edu     Initial Version
**/ 
public inherited sharing class CourseOfferingTriggerHandler {
    public inherited sharing class CourseOfferingInitiator extends TriggerAbstract{
        
        @TestVisible
        private CourseOfferingTransform courseOfferingCricosCodeJoin;
        
        Map<String, Calendar__c> calendars = new Map<String, Calendar__c>();
        Map<String, Course__c> courses = new Map<String, Course__c>();
        Map<String,Course_Duration__c> durations = new Map<String,Course_Duration__c>();
        
        public CourseOfferingInitiator() {
            this.courseOfferingCricosCodeJoin = 
                new CourseOfferingCricosCodeJoin(new CricosCodeSelector());
        }

        /**
        * @description this method evaluate on insert if record can be processed or not
        * @author David Browaeys
        * @param rec record to evaluate
        * @return void
        */
        public override void process (SObject rec){
            process(rec,null);
        }
        public override void process (SObject rec, SObject oldRec){
            Course_Offering__c co = (Course_Offering__c) rec;
            Course_Offering__c oldCo = (Course_Offering__c) oldRec;
            //In non-production this can cause issue if calendars and offerings are sent out of order.
            //if ( (co.Calendar__c == null && (co.Academic_CI_Sequence_Number__c != null && co.Admission_CI_Sequence_Number__c != null)) || 
            if ((co.Academic_CI_Sequence_Number__c != null && co.Admission_CI_Sequence_Number__c != null)
                && (oldRec == null 
                || co.Override_Duration_Unit__c != oldCo.Override_Duration_Unit__c 
                || co.Override_Duration__c != oldCo.Override_Duration__c 
                || co.Override_End_Date__c != oldCo.Override_End_Date__c 
                || co.Override_Start_Date__c != oldCo.Override_Start_Date__c )) {
                calendars.put(Integer.valueOf(co.Academic_CI_Sequence_Number__c) + '_' + Integer.valueOf(co.Admission_CI_Sequence_Number__c), null);
                records.add(co);
            }
            if (co.Course_Code__c != null && co.Course_Version_Number__c != null) {
                courses.put(co.Course_Code__c + '_' + Integer.valueOf(co.Course_Version_Number__c), null);
                durations.put(co.Unit_Set_Code__c != null ? 
                    co.Course_Code__c + '_' + co.Unit_Set_Code__c : 
                    co.Course_Code__c,null);
            }
        }

        public override void execute(){
            if (!records.isEmpty()) {
                getCalendars();
                getCourses();
                getOverrideDuration();

                for (Course_Offering__c co : (Course_Offering__c[]) records){
                    //set calendar lkp
                    String calCode = Integer.valueOf(co.Academic_CI_Sequence_Number__c) + '_' + Integer.valueOf(co.Admission_CI_Sequence_Number__c);
                    Calendar__c cal = calendars.get(calCode);
                    
                    if (cal == null) continue;  //if no calendar then ignore process

                    if (co.Calendar__c == null){
                        co.Calendar__c = cal.Id;
                    }
                    co.Start_Date__c = co.Override_Start_Date__c != null ? co.Override_Start_Date__c : cal.Course_Start_Date__c;

                    String courseCode = co.Course_Code__c + '_' + Integer.valueOf(co.Course_Version_Number__c);
                    if (courses.get(courseCode) != null){
                        if (co.Course__c == null) {//set course lkp
                            co.Course__c = courses.get(courseCode).Id;
                        }
                        String courseOfferingKey = co.Unit_Set_Code__c != null ? co.Course_Code__c + '_' + co.Unit_Set_Code__c : co.Course_Code__c;
                        if (durations.get(courseOfferingKey) != null && co.Override_Duration__c == null){
                            co.Override_Duration__c = durations.get(courseOfferingKey).Duration__c;
                            co.Override_Duration_Unit__c = durations.get(courseOfferingKey).Duration_Unit__c;
                        }
                        calculateOverrideEndDate(co,courses.get(courseCode),cal);
                    }
                    
                }
                this.courseOfferingCricosCodeJoin.transform((Course_Offering__c[]) records);
            }
        }
        /**
         * @description get calendar by calendar code
         */
        private void getCalendars(){
            for (Calendar__c c : [SELECT Id, Calendar_Code__c, Course_Start_Date__c, Course_Start_Date_End_Calc__c FROM Calendar__c WHERE Calendar_Code__c IN: this.calendars.keySet()]) {
                calendars.put(c.Calendar_Code__c,c);
            }
        } 
        /**
         * @description get course by course code
         */
        private void getCourses(){
            for (Course__c c : [SELECT Id, Course_Code__c, Duration_FT__c FROM Course__c WHERE Course_Code__c IN: this.courses.keySet()]) {
                courses.put(c.Course_Code__c,c);
            }
        } 
        /**
        * @description get duration override for setting default override
        */
        public void getOverrideDuration(){
            Course_Duration__c[] tmp = [    SELECT  Id, External_ID__c, Duration__c, Duration_Unit__c FROM Course_Duration__c 
                                            WHERE   RecordType.DeveloperName = 'Duration'
                                            AND     Active__c = true
                                            AND     External_ID__c IN :durations.keySet()
                                            ORDER BY CreatedDate ASC];
            for (Course_Duration__c cd : tmp){
                durations.put(cd.External_ID__c, cd);
            }
        }

        /**
        * @description Calculate end date base on firstly override end date if not blank, otherwise check if there is any override duration, otherwise use default values.  
        * @param co course offering to process
        * @param course main course link to course offering in order to get default duration
        * @param cal calendar of the course offering
        */
        private void calculateOverrideEndDate(Course_Offering__c co, Course__c course, Calendar__c cal){
            Date startDate = co.Override_Start_Date__c != null ? co.Override_Start_Date__c : (
                cal.Course_Start_Date_End_Calc__c != null ? cal.Course_Start_Date_End_Calc__c : cal.Course_Start_Date__c
            );
            if (co.Override_End_Date__c != null){    //is there an override end date for course offering ? 
                co.End_Date__c = co.Override_End_Date__c;
            }else if (co.Override_Duration__c != null && startDate != null){  //is there an override duration for course offering ? 
                switch on co.Override_Duration_Unit__c {
                    when 'Week'  {
                        co.End_Date__c = startDate.addDays(7 * (Integer)co.Override_Duration__c);
                    }when 'Month' {
                        co.End_Date__c = startDate.addMonths((Integer)co.Override_Duration__c);
                    }when 'Year'  {
                        co.End_Date__c = startDate.addMonths(Math.round(12 * co.Override_Duration__c));
                    }when else {    //oops missing override duration unit 
                        co.addError('Override Duration Unit not found, must be "Week", "Month", or "Year".');
                    }
                }
            } else if (course != null && startDate != null && course.Duration_FT__c != null){

                try {
                    co.End_Date__c = DateUtil.addYears(
                        startDate, course.Duration_FT__c
                    );

                } catch (UnsupportedOperationException e) {
                    // just ignore but raise a warning
                    // The business does not expect partial months to be calculated
                    // for durations
                    System.debug('Unsupported Operation requested for date ' 
                        + ' calculation - likely due to the calculation ' 
                        + ' resulting with partial months. Duration_FT__c: ' + 
                        course.Duration_FT__c + ' and startDate: ' + startDate 
                        + '### Exception: ' + e.getMessage() + ', ' 
                        + e.getStackTraceString()
                    );
                }
                
            }
        }
    }
}