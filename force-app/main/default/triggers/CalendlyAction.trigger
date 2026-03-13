/**
 * Created by tom on 27/5/2022.
 */

trigger CalendlyAction on Calendly__CalendlyAction__c (after insert) {

    if (TriggerCommon.doNotRunTrigger('Calendly__CalendlyAction__c')) {
        return;
    }

    new Triggers()
        .bindExtended(Triggers.Evnt.afterinsert, new CalendlyServices.processActions())
    .execute();
}