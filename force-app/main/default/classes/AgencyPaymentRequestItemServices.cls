/**
 * @description     Service class specific to Payment_Request_Item__c sObject
 * 
 * @author          K. Vegerano
 * @date            17/09/2020
 * 
 * @revision
 * 
 *      17/09/2020 - K Vegerano - created
 */
public with sharing class AgencyPaymentRequestItemServices {
    /**
    * Prepopulate fields for the Payment Request Item
    */
    public class PrepopulateFields extends TriggerAbstract {
        //Id variables
        private Set<Id> courseAttemptIds {get; set;}
        private List<Payment_Request_Item__c> processCostCentreItems {get; set;}

        /**
        * Method is called on the Before insert / After insert event
        */
        public override void process(SObject record) {
            //Cast to specific object
            Payment_Request_Item__c paymentRequestItem = (Payment_Request_Item__c)record;

            //check if the course attempt is populated
            if(paymentRequestItem.Course_Attempt__c != null){
                if(courseAttemptIds == null){
                    courseAttemptIds = new Set<Id>();
                }
                if(processCostCentreItems == null){
                    processCostCentreItems = new List<Payment_Request_Item__c>();
                }
                courseAttemptIds.add(paymentRequestItem.Course_Attempt__c);
                processCostCentreItems.add(paymentRequestItem);
            }
        }

        /**
        * Method is called on the Before update / After update event
        */
        public override void process(SObject record, SObject oldRec) {
            //Cast to specific object
            Payment_Request_Item__c paymentRequestItem = (Payment_Request_Item__c)record;
            Payment_Request_Item__c oldpaymentRequestItem = (Payment_Request_Item__c)oldRec;

            //check if the course attempt is changed and is populated
            if(oldpaymentRequestItem.Course_Attempt__c != paymentRequestItem.Course_Attempt__c && paymentRequestItem.Course_Attempt__c != null){
                if(courseAttemptIds == null){
                    courseAttemptIds = new Set<Id>();
                }
                if(processCostCentreItems == null){
                    processCostCentreItems = new List<Payment_Request_Item__c>();
                }
                courseAttemptIds.add(paymentRequestItem.Course_Attempt__c);
                processCostCentreItems.add(paymentRequestItem);
            }
        }

        /**
         * Run functionality logic
         */
        public override void execute() {
            try {      
                //Prepopulate cost centre 
                if(courseAttemptIds != null){
                    //Initialize variables
                    Map<Id, String> courseAttemptToAdmissionCategoryMapping = new Map<Id, String>();
                    if(!courseAttemptIds.isEmpty()){
                        //Query course attempt's acp's admission categories
                        for(Course_Attempt__c loopCourseAttempt : [SELECT Id, Application_Course_Preference__r.Admission_Category__c 
                                                                   FROM Course_Attempt__c 
                                                                   WHERE Id IN :courseAttemptIds
                                                                        AND Application_Course_Preference__c != null]){
                            courseAttemptToAdmissionCategoryMapping.put(loopCourseAttempt.Id, loopCourseAttempt.Application_Course_Preference__r.Admission_Category__c);
                        }   
                        
                        //Retrieve cost centre mapping
                        Map<String, AgentCommissionsCodeMapping__mdt> costCentreMapping = this.retrieveCostCentreMapping();

                        //Iterate through each payment request item items - prepopulate cost centre details
                        for(Payment_Request_Item__c loopPaymentRequestItem : processCostCentreItems){
                            //Check if the payment request item's course attempt has mapping to admission category
                            if(courseAttemptToAdmissionCategoryMapping.containsKey(loopPaymentRequestItem.Course_Attempt__c)){
                                String processingAdmissionCategory = courseAttemptToAdmissionCategoryMapping.get(loopPaymentRequestItem.Course_Attempt__c);
                                //Check if the admission category of the payment request item has a cost centre mapping
                                if(costCentreMapping.containsKey(processingAdmissionCategory)){     
                                    AgentCommissionsCodeMapping__mdt mappedCostCentre = costCentreMapping.get(processingAdmissionCategory);         
                                    loopPaymentRequestItem.Cost_Centre_Code__c = mappedCostCentre.Cost_Centre_Code__c;
                                    loopPaymentRequestItem.Fund_Code__c = mappedCostCentre.Fund_Code__c;
                                    loopPaymentRequestItem.Entity__c = mappedCostCentre.Entity__c;
                                }
                            }
                        }
                    }
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } finally {
                LogUtilityException.getLimits();
            }
        }

        /**
        * Method to retrieve cost centre mapping metadata
        */
        private Map<String, AgentCommissionsCodeMapping__mdt> retrieveCostCentreMapping(){
            Map<String, AgentCommissionsCodeMapping__mdt> costCentreMapping = new Map<String, AgentCommissionsCodeMapping__mdt>();
            for(AgentCommissionsCodeMapping__mdt loopCostCentre : [SELECT Id, Admission_Category__c, Classification__c, Cost_Centre_Code__c, Entity__c, Fund_Code__c
                                                                   FROM AgentCommissionsCodeMapping__mdt]){
                costCentreMapping.put(loopCostCentre.Admission_Category__c, loopCostCentre);
            }
            return costCentreMapping;
        }
    }
}