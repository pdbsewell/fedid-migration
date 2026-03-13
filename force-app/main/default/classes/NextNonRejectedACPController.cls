/**
* @description Controller class to get all Non Rejected ACPs used in 'SCR-ACP-Outcome Assistant:Rejected' Flow
* @author      Sravani Naramsetti
* @date        16/01/2025
* @group       Admissions
*/
global class NextNonRejectedACPController {
    /**
     * @description Method which gets next Non-Rejected ACPs in 'SCR - ACP - Outcome Assistant : Rejected' Flow
     * @param  List<Id> acpIds 
     */
    @InvocableMethod
    global static List<CustomOutput> getnextACPChoices(List<Id> acpIds) {
        try{
            Application_Course_Preference__c acp=[SELECT Id,Application__c FROM Application_Course_Preference__c WHERE Id IN: acpIds LIMIT 1];
            if(acp.Application__c!=null){
                List<CustomOutput> outputList = new List<CustomOutput>();
                CustomOutput outputToReturn = new CustomOutput();
                List<CustomChoice> choicesList = new List<CustomChoice>();
                List<Application_Course_Preference__c> lstACP = new List<Application_Course_Preference__c>();
                List<String> OutcomeValues = new List<String>{'REJECTED','REJECT-Q','REJ-MIDIP','REJ-MIMUFY','REJECT-GTE','CITZ-CHNG','CHANGE-R','APP-WDRWN','ERROR-ACAL','ERROR-CRS','ERROR-ACAT','INTAKE-CL','AP-LAPSED','REJECT-FRD'};
                    //Get all Non-Rejected ACPs for same Application
                    lstACP = [SELECT Id, Preference_Number__c, Course__r.Title__c, Course__r.Course_Code__c, Commencement_Period__c, Workflow_Status__c, Outcome_Status_Value__c FROM Application_Course_Preference__c WHERE Application__c=:acp.Application__c AND Id NOT IN: acpIds AND Outcome_Status_Value__c NOT IN: OutcomeValues ORDER BY Preference_Number__c];
                if(!lstACP.isEmpty()){
                    for(Application_Course_Preference__c acp1:lstACP){
                        CustomChoice choice = new CustomChoice(
                            acp1.Preference_Number__c+' | '+acp1.Course__r.Title__c+' | '+acp1.Course__r.Course_Code__c+' | '+acp1.Commencement_Period__c+' | '+acp1.Outcome_Status_Value__c+' | Workflow: '+acp1.Workflow_Status__c,
                            acp1.Id
                        );
                        choicesList.add(choice);
                    }
                    outputToReturn.choiceForOutput = choicesList;
                    outputList.add(outputToReturn);
                    return outputList;
                }
            }  
        }catch(Exception ex){
            Nebula.Logger.error('NextNonRejectedACPController.getnextACPChoices', ex);
            Nebula.Logger.saveLog();
        }
        return null;
    }
    
    @InvocableVariable
    global Id acpIds;
    
    //Wrapper to store return data to flow
    global class CustomOutput {
        @InvocableVariable
        global List<CustomChoice> choiceForOutput; 
    }
}