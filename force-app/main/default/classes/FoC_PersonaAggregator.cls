/**
 * FoC_PersonaAggregator.cls
 * The "Status Engine". Manages the lifecycle state of the user.
 * Implements the "System of Authority for Persona Aggregation".
 */
public class FoC_PersonaAggregator {

    // UPDATED SIGNATURE: Accepts 'moid' as a standalone string
    public static void upsertPersona(Id contactId, String moid, FoC_DTOs.PersonaContext pData, String idempotencyKey) {
        
        // 1. Construct Composite Key (MECE definition: Type + SubType + Context) 
        // Example: MOID-123|Student|Coursework|BSCI
        // FIX: Uses the passed 'moid' string instead of c.MoID__c
        String compositeKey = moid + '|' + pData.type + '|' + 
                             (pData.subType != null ? pData.subType : '') + '|' + 
                             (pData.context != null ? pData.context : '');

        // 2. Prepare the Record 
        // Maps to schema defined in Persona Management
        Persona_Aggregation__c pag = new Persona_Aggregation__c(
            PAG_Contact__c = contactId, // Uses ID passed in argument
            PAG_MoID__c = moid,         // Uses String passed in argument
            PAG_Composite_Key__c = compositeKey, // External ID for Idempotent Upsert
            PAG_Type__c = pData.type,
            PAG_SubType__c = pData.subType,
            PAG_Context__c = pData.context,
            PAG_State__c = pData.state,
            PAG_Reason__c = pData.reason,
            PAG_StartDate__c = pData.startDate,
            PAG_EndDate__c = pData.endDate
        );

        // 3. Upsert based on Composite Key
        // This ensures one and only one record per Persona Key (MECE)
        upsert pag PAG_Composite_Key__c;

        // 4. Create Immutable History (Audit Trail)
        createHistory(pag, idempotencyKey);

        // 5. Publish Event (Push Pattern)
        // Signals downstream systems (MiX -> FIM/Banner) that state changed 
        publishStateEvent(pag);
    }

    private static void createHistory(Persona_Aggregation__c pag, String idempotencyKey) {
        Persona_Aggregation_History__c hist = new Persona_Aggregation_History__c(
            PAG_Parent__c = pag.Id,
            PAG_State_Snapshot__c = pag.PAG_State__c,
            PAG_RecordedAt__c = System.now(),
            PAG_Idempotency_Key__c = idempotencyKey 
        );
        insert hist;
    }

    private static void publishStateEvent(Persona_Aggregation__c pag) {
        // Defines the 'persona.state' event contract
        Persona_State__e evt = new Persona_State__e(
            MoID__c = pag.PAG_MoID__c,
            Type__c = pag.PAG_Type__c,
            State__c = pag.PAG_State__c,
            Timestamp__c = System.now()
        );
        EventBus.publish(evt);
    }
}