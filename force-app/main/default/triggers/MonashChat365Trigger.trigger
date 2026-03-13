/**
* @author Angelo Rivera
* @date 05.09.19
* @group Monash Connect
* @description Trigger for Live Chat transcript for Monash Chat 365 functionality
* @revision 05.09.19 - Initial Create <br/>
*/

trigger MonashChat365Trigger on LiveChatTranscript (after update) {

	if (TriggerCommon.doNotRunTrigger('LiveChatTranscript')) { return; }
	new Triggers()
			//After Update Events
			.bindExtended(Triggers.Evnt.afterupdate, new MonashChat365TriggerHandler.CheckStatusUpdatesOnLiveChatTranscript())
			.bindExtended(Triggers.Evnt.afterupdate, new MonashChat365TriggerHandler.UpdateChat365Log())
			.execute();
}