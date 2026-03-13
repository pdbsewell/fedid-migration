/**
 * @description       : Contains all the trigger handlers for Channels
 * @author            : Paul Veiser
 * @group             : Trigger Handler
 * @last modified on  : 2020-10-16
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Date         Author          Modification
 * 2024-06-11   Martin Cadman   Due to completely different field mapping requirements for emergency contacts, a separate event is triggered
 * 2020-10-14   Stefan Scheit   Copied from ChannelServices, refactored from Contact_Point__e to Channel_Point__e
 * 2019-07-04   Paul Victoriano Deprecated Channel Rollup, Added Contact Point Dispatch Event Logic
 * 2018-11-12   Martin Cadman   Removed sync methods and moved logic to ChannelBatchServices
 * 2018-04-09   Martin Cadman   Added support for Recalculation after  deleted channels in updateContactAddressFields, Rollup Rank field on Channel, metadata additions of MAILING
 * 2018-03-01   Paul Veiser     Changed logic to not rely on Person_ID for sync
 * 2018-02-28   Stefan Scheit   Added TODOs
 * 2018-02-01   Paul Veiser     Initial version
**/
public with sharing class ChannelTriggerHandler {
    /**
     * Channel__c object record is inserted, updated, or deleted Contact Point Event is dispatched
     */
    public class DispatchChannelEvent extends TriggerAbstract {
        List<Channel_Event__e> channelEvents = new List<Channel_Event__e>();
        List<Async_Process__e> ecChannelEvents = new List<Async_Process__e>();

        /**
         * Create Channel_Events__e for Channel__c record inserts
         */
        public override void process(SObject sobj) {
            Channel__c channelRecord = (Channel__c)sobj;

            Feature_Switch__c fs = Feature_Switch__c.getInstance();
            
            if (channelRecord.Is_Processed__c == false) {
                if (channelRecord.type__c == 'EMERCONT'  && fs.Process_Emergency_Contacts__c) {
                    AsyncProcessPayload payload = new AsyncProcessPayload();
                    payload.put ('Id', channelRecord.id);
                    payload.put ('retryCount', 0);
                    ecChannelEvents.add(new Async_Process__e (
                        Process_Name__c = 'ChannelEventUtility.ProcessECChannel', 
                        Parameter__c = payload.serialize()
                        )
                    );
                } else {
                    channelEvents.add(
                        new Channel_Event__e(
                            Contact_Id__c = channelRecord.Contact__c,
                            Channel_Id__c = channelRecord.Id)
                    );
                }
            }
        }

        /**
         * Create Channel_Events__e for Channel__c record updates
         */
        public override void process(SObject sobj, SObject oldRec) {
            Channel__c channelRecord = (Channel__c)sobj;
            Feature_Switch__c fs = Feature_Switch__c.getInstance();
            
            if (channelRecord.Is_Processed__c == false) {
                if (channelRecord.type__c == 'EMERCONT'  && fs.Process_Emergency_Contacts__c) {
                    AsyncProcessPayload payload = new AsyncProcessPayload();
                    payload.put ('Id', channelRecord.id);
                    payload.put ('retryCount', 0);
                    ecChannelEvents.add(new Async_Process__e (
                        Process_Name__c = 'ChannelEventUtility.ProcessECChannel', 
                        Parameter__c = payload.serialize()
                        )
                    );
                } else {
                    channelEvents.add(
                        new Channel_Event__e(
                            Contact_Id__c = channelRecord.Contact__c,
                            Channel_Id__c = channelRecord.Id)
                        );
            	}
            }
        }
        
        /**
         * Dispatch Platform Events
         */
        public override void execute() {
            Database.SaveResult[] srList;
            try {
                if (channelEvents.size() > 0)   {srList = EventBus.publish(channelEvents);}
                if (ecChannelEvents.size() > 0) {srList = EventBus.publish(ecChannelEvents);}
            } catch (Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }
}