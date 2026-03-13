/*******************************************************************************
* @author       Ant Custodio
* @date         10.Apr.2017         
* @description  controller class for appWorkExperience.cmp lightning component
* @revision     Stefan Scheit (2018-09-15): Changed class to with sharing, removed currentUser filter
*******************************************************************************/
public with sharing class appWorkExperienceCC {
	private static Work_Experience__c workExperienceRec;
	private static List<Work_Experience__c> workExperienceList;
    private static final User currentUser = [   SELECT  ContactId, App_Previously_Studied_at_Monash__c
                                                FROM    User
                                                WHERE   Id =: userInfo.getUserId()];

	/*******************************************************************************
    * @author       Ant Custodio
    * @date         10.Apr.2017         
    * @description  retrieve the community user's work experience
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<Work_Experience__c> retrieveWorkExpList() {
        workExperienceList = new List<Work_Experience__c>();

        if (currentUser.ContactId != null) {
            workExperienceList = [     SELECT  Id,
                                        Contact__c,
                                        Position__c,
                                        Employer_Name__c,
                                        Start_Date__c,
                                        End_Date__c, 
                                        Reference_Count__c 
                                FROM    Work_Experience__c
                                ORDER BY Start_Date__c DESC];
        }
        return workExperienceList;
    }

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         17.Aug.2018
    * @description  retrieve the contct id
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static string retrieveContactId() {
        return currentUser.ContactId;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         2.May.2017         
    * @description  retrieve the community user's application work experience provided
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<Application_Work_Experience_Provided__c> retrieveAppWorkExpProvidedList(String applicationId) {
        List<Application_Work_Experience_Provided__c> workExpList = new List<Application_Work_Experience_Provided__c>();

        if (currentUser.ContactId != null) {
            workExpList = [     SELECT  Id, 
                                        Is_Submitted__c, 
                                        Application__c,
                                        Work_Experience__c,
                                        Work_Experience__r.Contact__c,
                                        Work_Experience__r.Position__c,
                                        Work_Experience__r.Employer_Name__c,
                                        Work_Experience__r.Start_Date__c,
                                        Work_Experience__r.End_Date__c
                                FROM    Application_Work_Experience_Provided__c
                                WHERE   Application__c =: applicationId];
        }
        return workExpList;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         10.Apr.2017         
    * @description  saves the new record
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Work_Experience__c insertNewWorkExpRecord (Work_Experience__c workExpToInsert) {
        system.debug('@@@workExpToInsert: '+ workExpToInsert);
        if (workExpToInsert != null) {
            workExpToInsert.Contact__c = currentUser.ContactId;
            insert workExpToInsert;
        }
        return workExpToInsert;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         10.Apr.2017         
    * @description  saves the new record
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Work_Experience__c insertNewWorkExpRecordWithApp (Work_Experience__c workExpToInsert, String applicationId, Boolean isEdit) {
        system.debug('@@@workExpToInsert: '+ workExpToInsert);
        if (workExpToInsert != null) {
            if(workExpToInsert.Contact__c == null){
                workExpToInsert.Contact__c = currentUser.ContactId;
            }
            upsert workExpToInsert;

            if(!isEdit) {
                Application_Work_Experience_Provided__c appWorkExpToInsert = new Application_Work_Experience_Provided__c();
                appWorkExpToInsert.Work_Experience__c = workExpToInsert.Id;
                appWorkExpToInsert.Application__c = applicationId;
                insert appWorkExpToInsert;
            }
            
        }
        return workExpToInsert;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         10.Apr.2017         
    * @description  saves the new record
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static String deleteSelectedWorkExperience (String workExperienceId) {
        String deletedId = '';
        if (workExperienceId != null && workExperienceId != '') {
            List<Work_Experience__c> workExperienceToDelete = [ SELECT Id FROM Work_Experience__c WHERE Id =: workExperienceId LIMIT 1];
            if (!workExperienceToDelete.isEmpty()) {
                deletedId = workExperienceToDelete[0].Id;
                delete workExperienceToDelete;
            }
        }

        return deletedId;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         10.Apr.2017         
    * @description  saves the new record
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static String deleteSelectedAppWorkExpProvided (String appWorkExpProvidedId) {
        String deletedId = '';
        if (appWorkExpProvidedId != null && appWorkExpProvidedId != '') {
            List<Application_Work_Experience_Provided__c> appWorkExpToDelete = [ SELECT Id, Work_Experience__c FROM Application_Work_Experience_Provided__c WHERE Id =: appWorkExpProvidedId LIMIT 1];
            if (!appWorkExpToDelete.isEmpty()) {
                List<Work_Experience__c> workExp = [SELECT Id FROM Work_Experience__c WHERE Id =:appWorkExpToDelete[0].Work_Experience__c];
                delete workExp;
            }
        }
        return deletedId;
    }

    

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         1.May.2017         
    * @description  creates a new work experience record
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static string createWorkExpAndRetrieveID(String applicationId) {
        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord.contact__c = currentUser.ContactId;
        insert workExpRecord;
        Application_Work_Experience_Provided__c appWorkExpToInsert = new Application_Work_Experience_Provided__c();
        appWorkExpToInsert.Work_Experience__c = workExpRecord.Id;
        appWorkExpToInsert.Application__c = applicationId;
        insert appWorkExpToInsert;
        String workExpAndappWorkExpProvided = '' + workExpRecord.id + ',' + appWorkExpToInsert.id;
        return workExpAndappWorkExpProvided;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         1.May.2017         
    * @description  creates a new work experience record
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Work_Experience__c createNewWorkExpRecord() {
        Work_Experience__c workExpRecord = new Work_Experience__c();
        //TODO
        return workExpRecord;
    }

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         10.July.2017         
    * @description  edit a work experience
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Work_Experience__c editWorkExpRecord(String workExperienceId) {
        Work_Experience__c workExpRecord = new Work_Experience__c();
        
        if(workExperienceId != null && workExperienceId != ''){
           workExpRecord = [SELECT Id, Contact__c, Position__c, Employer_Name__c, Start_Date__c, End_Date__c, 
                            Contact_Person_First_Name__c, Contact_Person_Last_Name__c, Contact_Person_Email__c, 
                            Contact_Person_Phone__c, Contact_Person_Street__c, Contact_Person_City__c, 
                            Contact_Person_State__c, Contact_Person_PostalCode__c 
                            FROM Work_Experience__c 
                            WHERE Id =:workExperienceId]; 
        }
        //TODO
        return workExpRecord;
    }
}