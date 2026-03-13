/**
 * FoC_MoIDService.cls
 * Manages the "Contact Identifier" child object.
 * Mints a new Primary MoID using the 4x4 Numeric Format (e.g. 3444-3334-3434-3343).
 */
public class FoC_MoIDService {
    
    // SINGLE RECORD ENTRY POINT
    public static String ensureMoID(Id contactId) {
        ensureMoIDs(new List<Id>{contactId});

        Contact_Identifier__c ci = [
            SELECT GuID__c 
            FROM Contact_Identifier__c 
            WHERE Contact__c = :contactId 
            AND Type__c = 'MoID' 
            AND Sub_Type__c = 'Primary' 
            LIMIT 1
        ];
        return ci.GuID__c;
    }

    // BULK ENTRY POINT
    public static void ensureMoIDs(List<Id> contactIds) {
        // 1. Check Existing
        Set<Id> contactsWithIds = new Set<Id>();
        
        for (Contact_Identifier__c ci : [
            SELECT Contact__c 
            FROM Contact_Identifier__c 
            WHERE Contact__c IN :contactIds 
            AND Type__c = 'MoID' 
            AND Sub_Type__c = 'Primary'
            AND Active__c = true
        ]) {
            contactsWithIds.add(ci.Contact__c);
        }

        // 2. Mint Missing
        List<Contact_Identifier__c> toInsert = new List<Contact_Identifier__c>();
        
        for (Id cId : contactIds) {
            if (!contactsWithIds.contains(cId)) {
                
                // NEW GENERATION LOGIC: 4 blocks of 4 digits
                String newMoID = generateNumericMoID();

                toInsert.add(new Contact_Identifier__c(
                    Contact__c = cId,
                    Type__c = 'MoID',
                    Sub_Type__c = 'Primary',
                    GuID__c = newMoID,
                    Active__c = true,
                    Primary__c = true,
                    Key__c = cId + '|MoID|Primary'
                ));
            }
        }
        
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    // HELPER: Generates format "XXXX-XXXX-XXXX-XXXX"
    private static String generateNumericMoID() {
        return getRandomBlock() + '-' + getRandomBlock() + '-' + 
               getRandomBlock() + '-' + getRandomBlock();
    }

    // HELPER: Generates a 4-digit string (0000-9999) using Crypto for uniqueness
    private static String getRandomBlock() {
        // Crypto.getRandomInteger() returns a secure random 32-bit integer
        // We use Math.abs and Modulo 10000 to get a number between 0-9999
        Integer randomInt = Math.abs(Crypto.getRandomInteger());
        Integer blockVal = Math.mod(randomInt, 10000);
        
        // Pad with leading zeros (e.g., 5 -> "0005")
        return String.valueOf(blockVal).leftPad(4, '0');
    }
}