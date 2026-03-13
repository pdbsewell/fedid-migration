/**
* @author Inderpal Dhanoa
* @date 07.07.21
* @description - AgentWorkTrigger Class to cater to AgentWorkTriggerHandler 
* @revision 07.07.21 - Initial Create <br/>
*/
trigger AgentWorkTrigger on AgentWork (before insert, after insert, before update, after update) {
    if (TriggerCommon.doNotRunTrigger('AgentWork')) { return; }
	new Triggers()
		//After Update Events
		.bindExtended(Triggers.Evnt.afterupdate, new AgentWorkTriggerHandler.UpdateCaseDetailsOnTranscriptTransfer())
		.execute(); 
	LogUtilityException.getLimits(); 

}