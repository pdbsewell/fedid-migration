/**
 * MoID_Service.cls
 * Generates and assigns the 4x4 Numeric format MoID directly to the Contact.
 */
public class MoID_Service {
    
    // 1. Generate ID in memory (Used by Okta Hook for Pass-Through)
    public static String generateMoIDString() {
        // return getRandomBlock() + '-' + getRandomBlock() + '-' + 
        //       getRandomBlock() + '-' + getRandomBlock();
        // return getRandomBlock() + getRandomBlock() + 
        //       getRandomBlock() + getRandomBlock();

        // Instantly mint the new MoID in the requested UUID format
        return System.Uuid.randomUUID().toString();
    }

    // 2. Assign ID (Called from Contact BEFORE INSERT Trigger)
    public static void ensureMoIDs(List<Contact> newContacts) {
        for (Contact c : newContacts) {
            // Only mint an ID if the field is completely blank.
            // If the JIT Handler passed an Okta-minted ID, this skips it automatically.
            if (String.isBlank(c.Monash_Object_Id__c)) {
                c.Monash_Object_Id__c = generateMoIDString();
            }
        }
    }

    private static String getRandomBlock() {
        Integer randomInt = Math.abs(Crypto.getRandomInteger());
        Integer blockVal = Math.mod(randomInt, 10000);
        return String.valueOf(blockVal).leftPad(4, '0');
    }
}