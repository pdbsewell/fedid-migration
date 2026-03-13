/**
 * ContactTriggerMoID.trigger
 * Handles autonomous MoID Minting and Propagation tracking.
 * NOTE: THIS SHOULD BE MOVED TO SINGLE CONTACT TRIGGER / HANDLER
 */
trigger ContactTriggerMoID on Contact (before insert, after insert, after update) {
    
    // --- 1. AUTONOMOUS MINTING (Runs BEFORE insert in memory) ---
    if (Trigger.isBefore && Trigger.isInsert) {
        // Pass the actual Contact records so the service can check the field 
        // and stamp the new MoID directly before saving to the database.
        MoID_Service.ensureMoIDs(Trigger.new);
    }

    // --- 2. BANNER PROPAGATION (Runs AFTER the record is securely saved) ---
    if (Trigger.isAfter) {
        Set<Id> contactsToPropagate = new Set<Id>();
        
        for (Contact c : Trigger.new) {
            if (Trigger.isInsert && c.Person_ID_unique__c != null) {
                contactsToPropagate.add(c.Id);
            }
            else if (Trigger.isUpdate) {
                Contact oldC = Trigger.oldMap.get(c.Id);
                if (c.Person_ID_unique__c != null && oldC.Person_ID_unique__c == null) {
                    contactsToPropagate.add(c.Id);
                }
            }
        }

        if (!contactsToPropagate.isEmpty()) {
            MoID_PropagationHandler.propagateAsync(contactsToPropagate);
        }
    }
}