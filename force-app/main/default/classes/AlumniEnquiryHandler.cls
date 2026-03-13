/**
 * @author			Inderpal Dhanoa
 * @group			ERDA
 * @description		Trigger Handlers for Alumni Enquiry.
 */
public class AlumniEnquiryHandler {
    public class syncAlumniEnquiryToEnquiry extends TriggerAbstract {
        public override void process(SObject record) {
            //Alumni_Enquiry__c caseRecord = (Alumni_Enquiry__c)record;
            records.add(record);            
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                List<Case> syncEnqList = new List<Case>();
                Case syncEnq;
                for(Alumni_Enquiry__c alumniEnq : (List<Alumni_Enquiry__c>)records){
                    syncEnq = new Case();
                    syncEnq.Description = alumniEnq.Description__c;//alumniEnq.Description__c;
                    syncEnq.Enquiry_Type__c = alumniEnq.Enquiry_Type__c;
                    syncEnq.Rich_Description__c = alumniEnq.Rich_Description__c;
                    syncEnq.Subject = alumniEnq.Subject__c;
                    syncEnq.SuppliedEmail = alumniEnq.SuppliedEmail__c;
                    syncEnq.OwnerId = [SELECT Id FROM GROUP WHERE Type = 'Queue' AND DeveloperName = 'Alumni_Engagement'].Id;
                    syncEnq.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Alumni_Engagement').getRecordTypeId();
                    syncEnq.Bypass_Case_Assignment__c = true;
                    syncEnq.Origin = 'Web';
                    syncEnqList.add(syncEnq);
                }
                try{
                    if(!syncEnqList.isEmpty()){
                        insert syncEnqList;
                    }
                }Catch(Exception ex){
                    Nebula.Logger.error(ex.getMessage(), ex);Nebula.Logger.saveLog();throw ex;
                }
            }
            LogUtilityException.getLimits();
        }
    }
}