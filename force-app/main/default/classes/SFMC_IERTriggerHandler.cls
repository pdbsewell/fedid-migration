/**
 * @author       : Ibrahim Rumi
 * @date         : 03-07-2023
 * @group        : SFMC
 * @description  : Trigger handler for Individual email results
**/
public class SFMC_IERTriggerHandler{

    /**
     * @description generates a cloudpage URL which displays a snapshot of the email sent to the contact via SFMC.
     */
    public class EncryptViewURL extends TriggerAbstract{

        public override void process(SObject record){
            et4ae5__IndividualEmailResult__c ierRecord = (et4ae5__IndividualEmailResult__c)record;
            if(String.isNotBlank(ierRecord.et4ae5__JobId__c)){
                ierRecord.View_Email_Copy_Online__c = SFMC_IERUtility.generateEmailPreviewUrl(ierRecord);
            }
        }
    }
}