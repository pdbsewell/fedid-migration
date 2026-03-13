/**
 * MoID_OktaHook.cls
 * Dedicated lightweight endpoint for Okta JIT Login.
 * Uses Pass-Through Minting to bypass DML timeouts.
 */
@RestResource(urlMapping='/api/identity/resolve')
global with sharing class MoID_OktaHook {
    
    @HttpPost
    global static void resolveIdentity() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        // 1. Parse Payload
        Map<String, Object> oktaBody = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
        Map<String, Object> data = (Map<String, Object>) oktaBody.get('data');
        Map<String, Object> userProfile = (Map<String, Object>) data.get('userProfile');

        String email = (String) userProfile.get('email');
        String vtacId = (String) userProfile.get('vtacId');
        String moidToReturn;

        // 2. FIND: Try to match existing Contact (Strict matching only for security)
        List<Contact> candidates = new List<Contact>();
        if (String.isNotBlank(vtacId)) {
            candidates = [SELECT Id, Monash_Object_Id__c 
                          FROM Contact WHERE VTAC_ID__c = :vtacId LIMIT 1];
        } else if (String.isNotBlank(email)) {
            candidates = [SELECT Id, Monash_Object_Id__c 
                          FROM Contact WHERE Email = :email LIMIT 1];
        }

        // 3. PASS-THROUGH MINTING: If no match, generate ID in memory. No insert DML.
        if (candidates.isEmpty()) {
            moidToReturn = MoID_Service.generateMoIDString();
        } else {
            // Existing Contact found
            Contact matched = candidates[0];
            
            if (String.isNotBlank(matched.Monash_Object_Id__c)) {
                // Return existing MoID
                moidToReturn = matched.Monash_Object_Id__c;
            } else {
                // Safety net: Contact exists but is missing a MoID (e.g., legacy data).
                // Generate and update the record immediately. 
                // (An update is generally faster than a fresh insert, keeping us inside the Okta timeout window).
                moidToReturn = MoID_Service.generateMoIDString();
                matched.Monash_Object_Id__c = moidToReturn;
                update matched; 
            }
        }

        // 4. RETURN to Okta
        // Pass back the MoID and a flag indicating if this was a fresh, in-memory mint
        Boolean isNewlyMinted = candidates.isEmpty();

        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'commands' => new List<Object>{
                new Map<String, Object>{
                    'type' => 'com.okta.user.profile.update',
                    'value' => new Map<String, Object>{ 
                        'MoID' => moidToReturn,
                        'Is_New_Identity' => isNewlyMinted 
                    }
                }
            }
        }));
        res.addHeader('Content-Type', 'application/json');
        res.statusCode = 200;
    }
}