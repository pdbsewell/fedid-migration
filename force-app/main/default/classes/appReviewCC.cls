/*******************************************************************************
* @author       Ant Custodio
* @date         10.May.2017         
* @description  controller class for appReview.cmp lightning component
* @revision     Stefan Scheit (2018-09-15): Removed currentUser filter from SOQLs (done through sharing)
* @revision     Andrew Yeo 06/02/2019 modified Fee Rules code to call MyApplicationUtitiles class for isMonashStudentFeeWaiver
                Suman Gunaganti(2019-07-05): (SF-2781) Removed Application Document provided object reference
                Shalini(13/03/2020):SFTLG-806-As a my.app applicant I do not want to pay an application fee if I apply for any course starting in 2020 Semester 2
                Shalini(18/03/2020):SFTLG-813-As a my.app applicant I do not want to pay an application fee if I apply for a Malaysian course on 21-Mar-2020 MYT
                *******************************************************************************/
                public with sharing class appReviewCC {
                    static Feature_Switch__c fs = Feature_Switch__c.getInstance();

                    /*
                    private static final User currentUser = [   SELECT  ContactId, App_Previously_Studied_at_Monash__c
                                                                FROM    User
                                                                WHERE   Id =: userInfo.getUserId()];
                    */
                    /*******************************************************************************
                    * @author       Ant Custodio 
                    * @date         10.May.2017        
                    * @description  retrieves the application by Id
                    * @param appId
                    * @return Application__c
                    * @revision     
                    *******************************************************************************/
                    @AuraEnabled
                    public static Application__c retrieveApplication(String appId) {
                        List<Application__c> applicationList =  [   SELECT  Id, Status__c, Name, Applicant__r.Citizenship__c, Guardian_Full_Name__c, Guardian_Email_Address__c, Guardian_Phone_Number__c, Guardian_Relationship__c
                                                                    FROM    Application__c
                                                                    WHERE   Id =: appId ];
                        
                        Application__c appRecord = new Application__c();
                        if (!applicationList.isEmpty()) {
                            appRecord = applicationList[0];
                        }
                        
                        
                        //will return new application if application Id is not found
                        return appRecord;
                    }
                
                    /*******************************************************************************
                    * @author       Ant Custodio
                    * @date         10.May.2017        
                    * @description  retrieves the qualification and map it by record type 
                                        developer name
                    * @param appId
                    * @return Map<String, List<Application_Qualification_Provided__c>> 
                    * @revision     
                    *******************************************************************************/
                    @AuraEnabled
                    public static Map<String, List<Application_Qualification_Provided__c>> retrieveApplicationQualMap(String appId) {
                        Map<String, List<Application_Qualification_Provided__c>> appQualMap = new Map<String, List<Application_Qualification_Provided__c>>();
                
                        if (appId != '') {
                            for (Application_Qualification_Provided__c aqpRecord : [    SELECT  Id,
                                                                                                Name,
                                                                                                Application__c,
                                                                                                Contact_Qualification__c,
                                                                                                Contact_Qualification__r.RecordType.DeveloperName,
                                                                                                Contact_Qualification__r.Institution_Name__c,
                                                                                                Contact_Qualification__r.Other_Institution__c,
                                                                                                Contact_Qualification__r.Qualification__c,
                                                                                                Contact_Qualification__r.Qualification__r.Qualification_Name__c,
                                                                                                Contact_Qualification__r.Other_Qualification__c,
                                                                                                Contact_Qualification__r.Qualification_Document__c,
                                                                                                Contact_Qualification__r.Country__c,
                                                                                                Contact_Qualification__r.Instruction_in_English__c,
                                                                                                Contact_Qualification__r.First_Year_Enrolled__c,
                                                                                                Contact_Qualification__r.Last_Year_Enrolled__c,
                                                                                                Contact_Qualification__r.Qualification_Document__r.Filename__c,
                                                                                                Contact_Qualification__r.Qualification_Document__r.Comments__c,
                                                                                                Contact_Qualification__r.Year_of_Completion__c,
                                                                                                Contact_Qualification__r.State__c,
                                                                                                Contact_Qualification__r.Status__c,
                                                                                                Contact_Qualification__r.Score__c,
                                                                                                Contact_Qualification__r.Date_Achieved__c,
                                                                                                Contact_Qualification__r.Other_Qualification_Comments__c,
                                                                                                Contact_Qualification__r.isTestCompleted__c,
                                                                                                Contact_Qualification__r.Qualification_Document__r.Document_Type__c,
                                                                                                Contact_Qualification__r.Essay_Rating__c,
                                                                                                Contact_Qualification__r.Listening__c,
                                                                                                Contact_Qualification__r.Reading__c,
                                                                                                Contact_Qualification__r.Speaking__c,
                                                                                                Contact_Qualification__r.Test_of_Written_English__c,
                                                                                                Contact_Qualification__r.Writing__c
                                                                                        FROM    Application_Qualification_Provided__c
                                                                                        WHERE   Application__c =: appId
                                                                                        ORDER BY CreatedDate DESC ] ) {
                                if (appQualMap.containsKey(aqpRecord.Contact_Qualification__r.RecordType.DeveloperName)) {
                                    appQualMap.get(aqpRecord.Contact_Qualification__r.RecordType.DeveloperName).add(aqpRecord);
                                } else {
                                    appQualMap.put(aqpRecord.Contact_Qualification__r.RecordType.DeveloperName, new List<Application_Qualification_Provided__c> {aqpRecord});
                                }
                            }
                        }
                        return appQualMap;
                    }
                
                    /*******************************************************************************
                    * @author       Ant Custodio
                    * @date         23.May.2017        
                    * @description  retrieves the work experience and map it by record type 
                                        developer name
                    * @param appId
                    * @return List<Application_Work_Experience_Provided__c> 
                    * @revision     
                    *******************************************************************************/
                    @AuraEnabled
                    public static List<Application_Work_Experience_Provided__c> retrieveApplicationWorkExpList(String appId) {
                        List<Application_Work_Experience_Provided__c> appWorkExpList = new List<Application_Work_Experience_Provided__c>();
                
                        if (appId != '') {
                            for (Application_Work_Experience_Provided__c aweRecord : [    SELECT  Id,
                                                                                                Name,
                                                                                                Application__c,
                                                                                                Work_Experience__c,
                                                                                                Work_Experience__r.Contact_Person_Phone_c__c,
                                                                                                Work_Experience__r.Contact_Person__c,
                                                                                                Work_Experience__r.Contact_Person_City__c,
                                                                                                Work_Experience__r.Contact_Person_Email__c,
                                                                                                Work_Experience__r.Contact_Person_First_Name__c,
                                                                                                Work_Experience__r.Contact_Person_Last_Name__c,
                                                                                                Work_Experience__r.Contact_Person_Phone__c,
                                                                                                Work_Experience__r.Contact_Person_PostalCode__c,
                                                                                                Work_Experience__r.Contact_Person_State__c,
                                                                                                Work_Experience__r.Contact_Person_Street__c,
                                                                                                Work_Experience__r.Employer_Name__c,
                                                                                                Work_Experience__r.End_Date__c,
                                                                                                Work_Experience__r.Position__c,
                                                                                                Work_Experience__r.Start_Date__c
                                                                                        FROM    Application_Work_Experience_Provided__c
                                                                                        WHERE   Application__c =: appId 
                                                                                        ORDER BY Work_Experience__r.Start_Date__c DESC ] ) {
                                appWorkExpList.add(aweRecord);
                            }
                        }
                        return appWorkExpList;
                    }
                
                    /*******************************************************************************
                    * @author       Ryan Wilson
                    * @date         23.May.2017        
                    * @description  retrieves Application Documents
                    * @revision     
                    *******************************************************************************/
                 /*   @AuraEnabled
                    public static List<Application_Document_Provided__c> retrieveAppDocuments(String appId) {
                        List<Application_Document_Provided__c> appDocuments = new List<Application_Document_Provided__c>();
                        appDocuments = [SELECT Id, CreatedDate, Application__c, Contact_Document__c, Contact_Document__r.Name, 
                                        Contact_Document__r.Document_Type_Name__c, Contact_Document__r.Filename__c, 
                                        Document_Id__c, Contact_Document__r.Comments__c   
                                        FROM Application_Document_Provided__c 
                                        WHERE Application__c =:appId 
                                        ORDER BY CreatedDate DESC 
                                        LIMIT 20];
                        return appDocuments;
                    }
                */
                
                    /*******************************************************************************
                    * @author       Ryan Wilson
                    * @date         23.May.2017        
                    * @description  retrieves Application Course Preferences
                    * @param appId
                    * @return List<CourseWrapper> 
                    * @revision     
                    *******************************************************************************/
                    @AuraEnabled
                    public static List<CourseWrapper> retrieveApplicationCourses(String appId) {
                        List<CourseWrapper> listCourse = new List<CourseWrapper>();
                
                        List<Application_Course_Preference__c> applicationCourses = new List<Application_Course_Preference__c>();
                
                        applicationCourses = [SELECT Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Admission_Calendar_Type__c,
                                                Admission_CI_Sequence_Number__c,Applicant__c,Application__c,Attendance_Type__c,Attendance_Mode_Description__c,
                                                Commencement_Period__c,Attendance_Type_Description__c,Attendance_Mode__c, Type_of_Place_Description__c,
                                                Course_Code__c,Course_Offering__c,Course_Title__c,Course_Version_Number__c,Course__c,CreatedDate,Id,
                                                Location_Code__c,Name,Outcome_Status__c,Preference_Number__c,Status__c,Unit_Set_Code__c, Unit_Set_Description__c,
                                                Offer_Response_Status__c,Offer_Condition__c, Offer_Date__c, Offer_Response_Date__c, Actual_Offer_Response_Date__c     
                                                FROM Application_Course_Preference__c 
                                                WHERE Application__c =:appId 
                                                ORDER BY Preference_Number__c ASC];
                
                        if(applicationCourses.size() >0){
                            for(Application_Course_Preference__c appCourse: applicationCourses){
                                listCourse.add(builCourseWrapper(appCourse));
                            }
                        }
                        
                        
                        return listCourse;
                    }
                
                   /*********************************************************************************************************
                    * @author       Andrew Yeo
                    * @date         17.July.2018        
                    * @description  Determine fee amount for the applicant (SF-1448)
                    * @param applicationId
                    * @revision     8/11/2018 SF-1715/1670 modified by Andrew Yeo
                    *               10/12/2018 SFTM-113, 115, 116 modified by Andrew Yeo
                    *               06/02/2019 modified Fee Rules code to call MyApplicationUtitiles class for isMonashStudentFeeWaiver
                    *********************************************************************************************************/
                   @AuraEnabled
                    //@InvocableMethod
                   
                    public static void determineFeeRule(string applicationId){
                      Application__c contextApplication = [SELECT Id, Name, Source_system__c,Status__c FROM Application__c WHERE Id = :applicationId LIMIT 1];
                        try{
                            if(contextApplication != null && contextApplication.Source_system__c!='AgentPortal'){
                                if(contextApplication.Status__c == 'Draft' || contextApplication.Status__c == AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT){
                                    // get the rule and amount from the custom metadata
                                    List<Application_Fee_Rule__mdt> applicationFeeRules = [SELECT DeveloperName, Fee_Amount__c 
                                                                                            FROM Application_Fee_Rule__mdt where Fee_Amount__c!=null];
                                
                                    //Map the rule to the record
                                    Map<String, Decimal> ruleFeeMap = new Map<String, Decimal>();
                                    for(Application_Fee_Rule__mdt applicationFeeRuleVar: applicationFeeRules){
                                        ruleFeeMap.put(applicationFeeRuleVar.DeveloperName, applicationFeeRuleVar.Fee_Amount__c);
                                    }
                            
                                    // get applications
                                    Application__c appRecord = [SELECT Id,Fee_Amount__c, Applicant__r.Birthdate,Fee_Payment_Mode__c, Residency_Status__c, Residency_Sub_status__c,Applicant__r.Previous_Monash_ID__c,Type_of_Study__c,Source_System__c 
                                                                FROM Application__c
                                                                WHERE Id =: applicationId];
                                    boolean validateStudent = false;
                                    appRecord.Fee_Amount__c = null;
                                    validateStudent = isMonashStudent( appRecord.Applicant__r.Previous_Monash_ID__c, appRecord.Applicant__r.Birthdate);
                                    appRecord = updateFee( validateStudent,  appRecord, ruleFeeMap );
                                    update appRecord;
                                }
                            }
                        }catch(Exception ex)
                        {
                            Nebula.Logger.error('Exception in appReviewCC.determineFeeRule on application'+contextApplication.Name, ex);
                        }
                    }
                    /**
                    * @author SMendu - solving cyclomatic complexity
                    * @date 18 Jul 2025 
                    * @description Determine if it is monash student
                    * @params String monashId
                    * @params Date birthDate
                    */
                    static Boolean isMonashStudent(String monashId, Date birthDate)
                    {
                        //declare and intialise variables
                        String prevMon = null;
                        Date prevMonBD = null;
                        Boolean validateStudent = false;

                        If (monashId!= null){
                            If(birthDate != null){
                                prevMon =  string.ValueOf(monashId);  
                                prevMonBD =  date.ValueOf(birthDate);
                                validateStudent = MyApplicationUtilities.isMonashStudentFeeWaiver(prevMon, prevMonBD);
                            }
                        }
                        return validateStudent;
                    }
                    /**
                    * @author SMendu - solving cognitive complexity
                    * @date 18 Jul 2025 
                    * @description Populate Fee based on previous monash student/study type
                    * @params Application__c appRecord Application record
                    * @params Boolean validateStudent monash student
                    * @params Map<String, Decimal> ruleFeeMap Map containing fee cmdt
                    */
                    static Application__c updateFee( Boolean validateStudent, Application__c appRecord,Map<String, Decimal> ruleFeeMap )
                    {
                         if(appRecord.Type_of_Study__c == 'Study Abroad' || appRecord.Type_of_Study__c == 'Exchange')
                        {
                            appRecord.Fee_Amount__c =  ruleFeeMap.get('Study_Abroad_Student');
                        }

                        If(validateStudent == true ){
                            appRecord.Fee_Amount__c = ruleFeeMap.get('Monash_Student');
                        }
                        else if ((validateStudent == false) || (appRecord.Applicant__r.Previous_Monash_ID__c == null) || (appRecord.Applicant__r.Birthdate == null))
                        {   
                            if(appRecord.Fee_Amount__c == null)
                            {
                                return updateFeeOnResidency(appRecord, ruleFeeMap);
                            }
                        }
                        return appRecord;
                    }
                    
                    /**
                    * @author SMendu - solving cognitive complexity
                    * @date 18 Jul 2025 
                    * @description Populate Fee based on Residency/Residency substatus
                    * @params Application__c appRecord Application record
                    * @params Map<String, Decimal> ruleFeeMap Map containing fee cmdt
                    */
                    static Application__c updateFeeOnResidency( Application__c appRecord,Map<String, Decimal> ruleFeeMap )
                    {
                       
                        //switch logic
                        switch on appRecord.Residency_Status__c {
                            //Rule 2 - Domestic applicant at Australian campus 
                            when 'DOM-AUS','DOM-NZ', 'DOM-PR', 'DOM-HV' {
                                appRecord.Fee_Amount__c = ruleFeeMap.get('Domestic_Applicant');
                            }
                            //Rule 3 - International applicant to Australian campus
                            when 'INTRNTNL', 'INT-TEP'{
                                if(fs.Display_New_Application_Fee__c)
                                {
                                    appRecord.Fee_Amount__c = ruleFeeMap.get('Australian_International_Updated_Fee');
                                }else{
                                    appRecord.Fee_Amount__c = ruleFeeMap.get('Australian_International_Applicant');
                                }
                            }
                            //Rule 4 - Malaysian campus applicants - added Non citizen and citizen fee
                            when 'INT-SUN-P','INT-SUN'{
                                appRecord.Fee_Amount__c = ruleFeeMap.get('Malaysia_Campus_Non_Citizen');
                            }
                            When 'DOM-SUN'{
                                switch on appRecord.Residency_Sub_status__c{
                                    When 'DOM-SUN.A'{
                                        appRecord.Fee_Amount__c = ruleFeeMap.get('Malaysia_Campus_Citizen');
                                    }
                                    When 'DOM-SUN.B'{
                                        appRecord.Fee_Amount__c = ruleFeeMap.get('Malaysia_Campus_Non_Citizen');
                                    }
                                } 
                            }
                            //Rule 5 - Indonesian campus applicants
                            //5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes - part of indonesian implementation
                            when 'DOM-IDN','DOM-IDN-PR','INT-IDN-P','INT-IDN'{
                                appRecord.Fee_Amount__c = ruleFeeMap.get('Indonesia_Campus');
                            }
                        } 

                        return appRecord;   
                    }
                
                    /*******************************************************************************
                    * @author       ??
                    * @date                
                    * @description  Build a POJO from ACP
                    * @param appCourse
                    * @return CourseWrapper
                    * @revision     
                    *******************************************************************************/
                    private static CourseWrapper builCourseWrapper(Application_Course_Preference__c appCourse) {
                        CourseWrapper course = new CourseWrapper();
                        if(appCourse != null){
                            course.courseId = appCourse.Id;
                        
                            course.courseDetail = appCourse.Course_Code__c+'-'+appCourse.Course_Title__c;
                            if(appCourse.Unit_Set_Description__c != null){
                                course.courseDetail += '/ '+appCourse.Unit_Set_Description__c;
                            }
                            if(appCourse.Type_of_Place_Description__c != null){
                                course.courseDetail += '/ '+appCourse.Type_of_Place_Description__c; 
                            }
                
                            course.attMode = appCourse.Attendance_Type_Description__c+' '+appCourse.Attendance_Mode_Description__c;
                            
                            course.location = appCourse.Location_Code__c;
                            course.commencementPeriod = appCourse.Commencement_Period__c;
                        }
                        
                        return course;
                    }
                  
                    /*******************************************************************************
                    * @author       ??
                    * @date                
                    * @description  POJO
                    * @revision     
                    *******************************************************************************/
                    public class CourseWrapper {
                        @AuraEnabled public String courseId {get; set;}
                        @AuraEnabled public String courseDetail {get; set;}
                        @AuraEnabled public String attMode {get; set;}
                        @AuraEnabled public String location {get; set;}
                        @AuraEnabled public String commencementPeriod {get; set;}
                    }
                    
                    
                }