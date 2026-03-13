/**
 * EntraJitHandler — SAML JIT for Experience Cloud (Entra → Salesforce)
 * - CREATE: link User to existing Contact (lookup by Contact.PAG_MoID__c), set Persona, set FederationIdentifier=MoID
 * - UPDATE: keep fields in sync; keep FederationIdentifier=MoID
 * - UAP handles permission set assignment after insert/update
 */
global with sharing class EntraJitHandler implements Auth.SamlJitHandler {

    // Use a simple custom exception to fail SSO with a clear message
    private class JitException extends Exception {}

    // === Config ===
    private static final String PERMSET_IDENTIFIER = 'Customer Community My.Application';


    // ---- CREATE: called when user doesn't exist yet ----
    global User createUser(
        Id samlSsoProviderId,
        Id communityId,
        Id portalId,
        String federationIdentifier,
        Map<String, String> attributes,
        String assertion
    ) {
        // pull attributes from assertion
        String email        = attributes.get('User.Email');
        String firstName    = attributes.get('User.FirstName');
        String lastName     = attributes.get('User.LastName');
        String username     = attributes.get('User.Username');        // insert-only
        String profileName  = attributes.get('User.ProfileId');       // profile NAME (we resolve to Id)
        String persona      = attributes.get('User.Persona_Name__c'); // drives UAP
        String moid         = attributes.get('Contact.PAG_MoID__c');  // from Entra user.employeeId

        // validate required
        if (String.isBlank(email) || String.isBlank(lastName) || String.isBlank(profileName) || String.isBlank(username)) {
            throw new JitException('Missing required SAML attrs: User.Email, User.LastName, User.ProfileId (name), User.Username.');
        }
        if (String.isBlank(moid)) {
            throw new JitException('Missing Contact.PAG_MoID__c (MoID) in SAML assertion.');
        }

        // resolve profile by NAME
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

        // find Contact by MoID (must already exist)
        Contact c = [SELECT Id FROM Contact WHERE PAG_MoID__c = :moid LIMIT 1];

        // build user
        User u = new User();
        u.Username             = username;   // insert-only
        u.Email                = email;
        u.FirstName            = firstName;
        u.LastName             = lastName;
        u.ProfileId            = p.Id;
        u.ContactId            = c.Id;

        // set FederationIdentifier to MoID (your stable external key)
        u.FederationIdentifier = moid;

        // sensible region defaults
        User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id = :UserInfo.getUserId()];

        if (String.isBlank(u.TimeZoneSidKey))    u.TimeZoneSidKey    = currentUser.TimeZoneSidKey;
        if (String.isBlank(u.LocaleSidKey))      u.LocaleSidKey      = currentUser.LocaleSidKey;
        if (String.isBlank(u.LanguageLocaleKey)) u.LanguageLocaleKey = currentUser.LanguageLocaleKey;
        if (String.isBlank(u.EmailEncodingKey))  u.EmailEncodingKey = currentUser.EmailEncodingKey;

        // alias ≤ 8 chars
        u.Alias = ((firstName != null ? firstName.substring(0,1) : 'x') + (lastName != null ? lastName : 'user')).left(8);

        // set persona for UAP
        if (persona != null) {
            u.put('Persona_Name__c', persona);
        }

        system.debug('$$%%^^ inserting user:' + u);
        insert u; // UAP evaluates after insert
        system.debug('$$%%^^ inserted user:' + u);

        system.debug('$$%%^^ inserting perm set:' + PERMSET_IDENTIFIER);
        // assign the permission set (if not already)
        ensurePermissionSetAssigned(u.Id, PERMSET_IDENTIFIER);
        system.debug('$$%%^^ inserted perm set:' + PERMSET_IDENTIFIER);

        return u;
    }

    // ---- UPDATE: called for subsequent logins of an existing user ----
    global void updateUser(
        Id userId,
        Id samlSsoProviderId,
        Id communityId,
        Id portalId,
        String federationIdentifier,
        Map<String, String> attributes,
        String assertion
    ) {
        String email        = attributes.get('User.Email');
        String firstName    = attributes.get('User.FirstName');
        String lastName     = attributes.get('User.LastName');
        String profileName  = attributes.get('User.ProfileId');       // profile NAME
        String persona      = attributes.get('User.Persona_Name__c');
        String moid         = attributes.get('Contact.PAG_MoID__c');  // MoID for Contact & FedId

        if (String.isBlank(email) || String.isBlank(lastName) || String.isBlank(profileName)) {
            throw new JitException('Missing required SAML attrs: User.Email, User.LastName, User.ProfileId (name).');
        }
        if (String.isBlank(moid)) {
            throw new JitException('Missing Contact.PAG_MoID__c (MoID) in SAML assertion.');
        }

        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE PAG_MoID__c = :moid LIMIT 1];

        User u = [
            SELECT Id, Email, FirstName, LastName, ProfileId, ContactId, FederationIdentifier,
                   TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey, Alias
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];

        u.Email                = email;
        u.FirstName            = firstName;
        u.LastName             = lastName;
        u.ProfileId            = p.Id;
        u.ContactId            = c.Id;

        // keep FederationIdentifier aligned to MoID on every login
        u.FederationIdentifier = moid;

        User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id = :UserInfo.getUserId()];

        if (String.isBlank(u.TimeZoneSidKey))    u.TimeZoneSidKey    = currentUser.TimeZoneSidKey;
        if (String.isBlank(u.LocaleSidKey))      u.LocaleSidKey      = currentUser.LocaleSidKey;
        if (String.isBlank(u.LanguageLocaleKey)) u.LanguageLocaleKey = currentUser.LanguageLocaleKey;
        if (String.isBlank(u.EmailEncodingKey))  u.EmailEncodingKey = currentUser.EmailEncodingKey;

        if (String.isBlank(u.Alias)) {
            u.Alias = ((firstName != null ? firstName.substring(0,1) : 'x') + (lastName != null ? lastName : 'user')).left(8);
        }
        if (persona != null) {
            u.put('Persona_Name__c', persona);
        }

        update u; // UAP will re-evaluate on update
    }

    // === Helpers ===

    // Assigns a Permission Set to a user if not already assigned.
    private static void ensurePermissionSetAssigned(Id userId, String permLabelOrApi) {
        Id psId = resolvePermissionSetId(permLabelOrApi);
        if (psId == null) {
            throw new JitException('Permission Set not found by Label or API Name: ' + permLabelOrApi);
        }

        // already assigned?
        List<PermissionSetAssignment> existing = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSetId = :psId
            LIMIT 1
        ];
        if (!existing.isEmpty()) return;

        try {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = psId);
        } catch (DmlException e) {
            // Common causes: PS has a different license than the user's profile license
            throw new JitException('Failed to assign Permission Set "' + permLabelOrApi + '": ' + e.getMessage());
        }
    }

    // Finds a Permission Set by Label or API Name; also tries a sanitized API version of the label.
    private static Id resolvePermissionSetId(String labelOrApi) {
        // Try Label or Name directly
        List<PermissionSet> ps = [
            SELECT Id, Name, Label
            FROM PermissionSet
            WHERE Label = :labelOrApi OR Name = :labelOrApi
            LIMIT 1
        ];
        if (!ps.isEmpty()) return ps[0].Id;

        return null;
    }
}