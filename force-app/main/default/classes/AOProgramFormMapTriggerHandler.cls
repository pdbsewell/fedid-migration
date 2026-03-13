/**
 * /**
 * @author : [Babyshark]
 * @description : Trigger Handler Class for Program Form Map Object
 *  - CreateEncyptedText -> Encrypts the Salesforce Id and stores it in Encoded Id field for URL construction for publishing
 * @group : Abroad Outbound
 * @date : 19/08/2024
 */
public with sharing class AOProgramFormMapTriggerHandler {
   
    public class CreateEncyptedText extends TriggerAbstract {

        List<AO_Program_Form_Map__c> recList = new List<AO_Program_Form_Map__c>();
        public override void process(SObject sobj) {
			AO_Program_Form_Map__c newObj = (AO_Program_Form_Map__c) sobj;
            recList.add(newObj);
		}

        public override void execute() {
			try {
				String key = SystemSettingsUtil.getInstance().getByKeyFeature('AO_ABROAD', 'ENCRYPTION_KEY')?.value__c;
                List<AO_Program_Form_Map__c> formMaps = new List<AO_Program_Form_Map__c>();
                for(AO_Program_Form_Map__c objPF : recList){
                    formMaps.add(new AO_Program_Form_Map__c(
                        Id = objPF.Id, 
                        AO_Encoded_Id__c = AOEncryptionUtil.encrypt256(key, objPF.Id)));
                }
                if(!formMaps.isEmpty()){
                    update formMaps;
                }
			} catch(Exception e) {
				nebula.logger.exception(e.getMessage(), e);
			} 
        }

    }
}