/**
 * FoC_ContactResolver.cls
 * Fixed: Removed references to non-existent Contact.MoID__c field.
 */
public class FoC_ContactResolver {

    public class ResolutionOutcome {
        public Contact record;
        public Boolean isNew;
        public Boolean hasAmbiguity;
    }

    public static ResolutionOutcome resolve(FoC_DTOs.Request req) {
        ResolutionOutcome outcome = new ResolutionOutcome();
        
        // 1. Try Strict Match
        Contact strictMatch = findStrictMatch(req);
        if (strictMatch != null) {
            outcome.record = strictMatch;
            outcome.isNew = false;
            outcome.hasAmbiguity = false;
            return outcome;
        }

        // 2. Try Fuzzy Match (Ambiguity Check)
        List<Contact> fuzzyMatches = findFuzzyMatches(req); 
        
        // 3. Create New Shell Contact
        Contact newContact = new Contact(
            FirstName = req.firstName,
            LastName = req.lastName,
            Email = req.email,
            MobilePhone = req.mobile,
            VTAC_ID__c = (req.externalIdType == 'VTAC') ? req.externalId : null
        );
        
        insert newContact; 

        // 4. Log Ambiguities
        if (!fuzzyMatches.isEmpty()) {
            createPotentialMatches(newContact.Id, fuzzyMatches, req);
            outcome.hasAmbiguity = true;
        } else {
            outcome.hasAmbiguity = false;
        }

        outcome.record = newContact;
        outcome.isNew = true;
        
        return outcome;
    }

    private static void createPotentialMatches(Id newContactId, List<Contact> existing, FoC_DTOs.Request req) {
        List<Potential_Match__c> matches = new List<Potential_Match__c>();
        for (Contact c : existing) {
            matches.add(new Potential_Match__c(
                New_Contact__c = newContactId,
                Existing_Contact__c = c.Id,
                Status__c = 'New',
                Match_Score__c = 85,
                Match_Rule__c = 'Fuzzy Name + DOB',      // Requires Field in Step 2
                Source_System__c = req.systemOfOrigin,   // Requires Field in Step 2
                Incoming_Payload__c = JSON.serialize(req)
            ));
        }
        insert matches;
    }
    
    // -------------------------------------------------------------------------
    // STRATEGY 1: STRICT MATCH
    // NB. THIS IS JUST DEMO LOGIC AND NEEDS TO BE REPLACED
    // Logic: Matches on Unique IDs (VTAC ID) OR Exact Email. 
    // These are considered "High Trust" signals.
    // -------------------------------------------------------------------------
    private static Contact findStrictMatch(FoC_DTOs.Request req) {
        List<Contact> candidates = new List<Contact>();

        if (req.externalIdType == 'VTAC' && String.isNotBlank(req.externalId)) {
            candidates = [SELECT Id, VTAC_ID__c, Email, FirstName, LastName 
                          FROM Contact 
                          WHERE VTAC_ID__c = :req.externalId 
                          LIMIT 1];
        }

        if (candidates.isEmpty() && String.isNotBlank(req.email)) {
            candidates = [SELECT Id, VTAC_ID__c, Email, FirstName, LastName 
                          FROM Contact 
                          WHERE Email = :req.email 
                          LIMIT 1];
        }

        return candidates.isEmpty() ? null : candidates[0];
    }

    // -------------------------------------------------------------------------
    // STRATEGY 2: FUZZY MATCH
    // NB. THIS IS JUST DEMO LOGIC AND NEEDS TO BE REPLACED
    // Logic: Matches on First Name + Last Name + Date of Birth.
    // Catches typos in Email or missing External IDs.
    // Returns a LIST because common names (e.g., John Smith) might return multiple.
    // -------------------------------------------------------------------------
    private static List<Contact> findFuzzyMatches(FoC_DTOs.Request req) {
        if (String.isBlank(req.lastName) || req.dob == null) {
            return new List<Contact>();
        }

        String firstNameQuery = req.firstName + '%';
        
        return [
            SELECT Id, FirstName, LastName, Email, Birthdate
            FROM Contact
            WHERE LastName = :req.lastName
            AND Birthdate = :req.dob
            AND FirstName LIKE :firstNameQuery
            LIMIT 5 
        ];
    }
}