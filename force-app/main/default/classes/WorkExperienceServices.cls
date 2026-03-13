public class WorkExperienceServices {

    public class tidyPhone extends TriggerAbstract {
        List<Work_Experience__c> workEx = new List<Work_Experience__c>();
        
        public override void process(SObject record) {
            Work_Experience__c newWE = (Work_Experience__c) record;
            if (String.isNotEmpty(newWE.Contact_Person_Phone__c)) {
                workEx.add (newWE);
            }
        }
        
        public override void process(SObject record, SObject oldRec) {
            Work_Experience__c newWE = (Work_Experience__c) record;
            Work_Experience__c oldWE = (Work_Experience__c) oldrec;

            if (String.isNotEmpty(newWE.Contact_Person_Phone__c) 
              && CommonUtilities.fieldHasChanged('Contact_Person_Phone__c', newWE, oldWE)) {
                workEx.add (newWE);
            }
        }
        
        public override void execute() {
            if (!workEx.isEmpty()) {
                phoneServices.formatPhoneWrapper fpw;
    
                for (Work_Experience__c w : workEx) {
                    fpw = phoneServices.initiatePhoneFormat(w.Contact_Person_Phone__c);
                    if (fpw.formatted) {
                        w.Contact_Person_Phone__c = fpw.phonenumber;    
                    } else {
                        w.Contact_Person_Phone__c = phoneServices.tidyPhone(w.Contact_Person_Phone__c); 
                    }
                }
            }
        }
    }
}