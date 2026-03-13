/**
 * Added by UC Innovation to add default name logic to salutation - 2019-09-19
 * Class SalutationHandler
 */
global class SalutationHandler extends ucinn_ascendv2.ascend_TDTM_Runnable {
    
    private ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper dmlWrapper = new ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper();

    /*******************************************************************************
    * @date         10/9/2019 
    * @description  Executes as entry point into trigger handler.
    *******************************************************************************/
    global override ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList, ucinn_ascendv2.ascend_TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        //Cast SObject lists to be Review Transactions
        List<ucinn_ascendv2__Salutation__c> trigger_new = (List<ucinn_ascendv2__Salutation__c>) newList;
        List<ucinn_ascendv2__Salutation__c> trigger_old = (List<ucinn_ascendv2__Salutation__c>) oldList;

        //After Insert
        if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterInsert) {
            populateDefaultName(trigger_new);
        //After Update
        } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterUpdate) {
			populateDefaultName(trigger_new);
        }

        return dmlWrapper;
    }
    
    /*******************************************************************************
    * @date         11/11/2019 
    * @description  Creates default name for salutation.
    *******************************************************************************/
    private void populateDefaultName(List<ucinn_ascendv2__Salutation__c> trigger_new) {
        ucinn_ascendv2.ascend_TRIG_RecordNameUpdate recordNameUpdater = new ucinn_ascendv2.ascend_TRIG_RecordNameUpdate();
        
		recordNameUpdater.updateName(	new ucinn_ascendv2__Salutation__c().getSObjectType().getDescribe().getName(), 
                                        null,
                                        'ucinn_ascendv2__Salutation_Name_Auto_Number__c',
                                        '',
                                        '',
                                        null,
                                        trigger_new);
    }
}