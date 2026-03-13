/**
 * @description Trigger handler for ibdGROffers__e
 * @group		Grad Research Applications
 * @revision    23/01/2025 - Vishal Gupta - Initial version
 */
public with sharing class IbdGROffersServices {

    public class EventHandler extends TriggerAbstract {

        public override void execute() {
            IbdGROffers__e[] events = this.records;

            // Collect Request_Parameter__c from events, Since the platform event batch size is set to 1, we'll get the 1st record form the list of events 
            String offerScholarshipPayload;
            try {
                Nebula.Logger.info('Processing ' + events.size() + ' Inbound grad research scholarship offer events');
            
                if(events.size() > 1) {
                    List<String> offerPayloads = new List<String>();
                    for(IbdGROffers__e event : events) {
                        offerPayloads.add(event.Request_Parameter__c);
                    }
                    if(!offerPayloads.isEmpty()) {
                        throw new IbdGROffersServicesException(String.join(offerPayloads, '\n\n').substring(0, 131072));
                    }
                } else if(events[0].Process_Name__c == 'GRScholarshipOfferService') {
                    offerScholarshipPayload = events[0].Request_Parameter__c;
                }
                
                if(offerScholarshipPayload != null) {
                    GRScholarshipOfferService.parseJson(offerScholarshipPayload);
                }   
            }    
            catch(Exception ex) {
                Nebula.Logger.error(ex.getMessage(), ex).addTag('Graduate Research');
            }    
            Nebula.Logger.saveLog();
        }
    }

    /**
    * @description IbdGROffersServices exception class
    */
    public class IbdGROffersServicesException extends Exception {}
}