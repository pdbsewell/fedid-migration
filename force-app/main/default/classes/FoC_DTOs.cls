/**
 * FoC_DTOs.cls
 * Data Transfer Objects for the FoC Service
 * Defines the strict input/output contracts for the Service.
 * Aligned with 'Persona Payload' definition in Persona Management (1)
 * And definitions in Access Authorisation Framework (2)
 * (1) https://monash-esol.atlassian.net/wiki/spaces/SP2/pages/1573093515/Persona+Management
 * (2) https://monash-esol.atlassian.net/wiki/spaces/SP2/pages/1418199102/Access+Authorisation+Framework
 */
public class FoC_DTOs {

    public class Request {
        public String correlationId;      // For tracing (TRACE-abcd1234)
        public String idempotencyKey;     // Critical for dedupe 
        public String systemOfOrigin;     // Point where contact was originated or accepted eg. Banner
        
        // Identity Traits (Used for Resolution) 
        public String firstName;
        public String lastName;
        public String email;
        public String mobile;
        public Date dob;
        public String externalId;         // e.g., VTAC ID, PIDM
        public String externalIdType;     // 'VTAC_ID', 'Banner_PIDM'

        // Persona Context (Optional - passed if state update is required)
        public PersonaContext persona; 
    }

    // Aligned with the Persona Taxonomy 
    public class PersonaContext {
        public String type;               // e.g., 'Applicant', 'Student'
        public String subType;            // e.g., 'Coursework'
        public String context;            // e.g., 'BSCI' (Course Code) 
        public String state;              // e.g., 'inProgress', 'offered'
        public String reason;             // e.g., 'firstOfferActive'
        public Date startDate;            // Effective Start 
        public Date endDate;              // Effective End 
    }

    public class Result {
        public Boolean isSuccess;
        public Boolean isPotentialDuplicate;
        public String contactId;
        public String moid;               // GUID for digital identity; refer Access Authorisation Framework                                   
        public Boolean isNewContact;      // Telemetry
        public String message;
    }
}