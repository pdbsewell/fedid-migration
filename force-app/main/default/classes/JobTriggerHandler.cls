/*
   @author       Nitin Khandelwal
   @date         9.April.2018        
   @description  Handler class for job trigger. Creates or updates target object records from staging object.
   @revision     26 April 2018 Nitin Khandelwal - Logic to include all-courses in the trigger processing
                 11 June 2018 Nitin Khandelwal / Majid Reisi Dehkordi - Logic to include calendar, calendar dates, cricos code and course fee objects for trigger processing
				 23 Nov 2020 Martin Cadman - Moved to switch statement
				 20 Oct 2021 Inderpal Dhanoa -  Added scenarios for OrgUnit ENGAGEIE-886

  IMPORTANT
  This trigger will process only 2000 records at a time, to handle the CPU timeout limit. 
  If we have more than 2000 records, need to manually update the job control table and process the records.

**/
public class JobTriggerHandler
{
    public static final String fieldValue = 'Course-Published';
    private List<jobTriggerMapping__mdt> lstFieldMapping = null;
    private Schema.SObjectType sobType = null;
    private Schema.SObjectType sourceObjType = null;

    public void onAfterUpdate(List<Job_Control__c> lstNewObjA)
    {
        //checking the prerequisites for the trigger to fire
        if (lstNewObjA.size() > 1 || (String.isBlank(lstNewObjA[0].Job_Code__c )  || lstNewObjA[0].Processing_Status__c != 'CRM Ready to Process') ){
            return;
        }

        //picking up a single record from the job control table and processing it.
        Job_Control__c oJobControl = lstNewObjA[0];
        List<Job_Control__c> LstJobtoUpdateCRM = new List<Job_Control__c>();
        lstFieldMapping = [SELECT Source_Field__r.QualifiedApiName, Source_Object__c, Target_Field__r.QualifiedApiName, Target_Object__r.QualifiedApiName, Source_Object__r.QualifiedApiName
                           FROM jobTriggerMapping__mdt WHERE Target_Object__r.DeveloperName =:oJobControl.Process_Name__c AND IsActive__c = true ];
        sobType = Schema.getGlobalDescribe().get(lstFieldMapping[0].Target_Object__r.QualifiedApiName);
        sourceObjType = Schema.getGlobalDescribe().get(lstFieldMapping[0].Source_Object__r.QualifiedApiName);
        processJobControlRecord(oJobControl.Job_Code__c, oJobControl.Process_Name__c, oJobControl.Type__c);
    }
    
    private void processJobControlRecord(String sUniqueId, String targetObjName, String sType)
    {
        
        //Create the target obj based on the field mapping
        //First we initialize using the right target object type and field mapping
        //And then we call the function that it responsible for creating the ultimate obj

        Switch on targetObjName {
        when 'Course' {
                JobTriggerHandlerCourseHelper.initializeJobControlRecord(sobType, lstFieldMapping);
                JobTriggerHandlerCourseHelper.processJobControlRecord(sUniqueId, targetObjName, sType);
           }
          when 'Calendar_Dates' {
                JobTriggerHandlerCalDatesHelper.initializeJobControlRecord(lstFieldMapping, sobType);
                JobTriggerHandlerCalDatesHelper.processJobControlRecord(sUniqueId, targetObjName);
            }
             when 'Calendar'{
                JobTriggerHandlerCalendarHelper.initializeJobControlRecord(sobType, lstFieldMapping);
                JobTriggerHandlerCalendarHelper.processJobControlRecord(sUniqueId, targetObjName, sType);
            }
            when 'CRICOS_Code' {
                JobTriggerHandlerCriCodeHelper.initializeJobControlRecord(sobType, lstFieldMapping);
                JobTriggerHandlerCriCodeHelper.processJobControlRecord(sUniqueId, targetObjName, sType);
            }
			when 'Org_Unit' {
                JobTriggerHandlerOrgUnitHelper.processJobControlRecord(sUniqueId, targetObjName, sType); 
            }
           when else {
               LogUtilityException.logExceptionMSG(sType, sUniqueId, 'Unknown target object - ' + targetObjName );
            }
        }
    }
}