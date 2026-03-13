/**
 * PAG_PersonaService
 *
 * Responsibility:
 *  - Ingest a persona.state message and persist it into:
 *      (a) Current snapshot (PAG_Persona_Aggregation__c) — one live row per (MoID|Type|SubType|Context)
 *      (b) Immutable history (PAG_Persona_Aggregation_History__c)
 *  - Enforce MECE for the current snapshot: each new state supersedes the prior one.
 *  - Record idempotency so replays can be detected later.
 *  - When a new MoID is minted, publish a Platform Event (PAG_MoID_Minted__e) for downstream SoR sync.
 */
public with sharing class PAG_PersonaService {

    /** Simple result DTO returned to callers (API/tests) */
    public class Result { public Id contactId; public Id personaId; public Id historyId; public Boolean created; public String moid;}

    /**
     * Ingest a JSON payload representing a PAG_PersonaModels.PersonaEvent.
     * Steps:
     *  1) Validate payload shape and domain rules.
     *  2) Resolve/create Contact and update identifiers (MoID, Banner PIDM).
     *  3) Mint MoID if missing; optionally publish PE to notify SoR.
     *  4) Build composite key (MoID|Type|SubType|Context).
     *  5) Enforce MECE on current snapshot; upsert current aggregation.
     *  6) Append immutable history row.
     *  7) Insert idempotency record for replay detection.
     *
     * @param rawJson The raw JSON body of the persona.state event.
     * @return Result with Contact, current Aggregation, and History Ids.
     * @throws PAG_Errors.ValidationException when the event is malformed or violates domain rules.
     */
    @AuraEnabled
    public static Result ingest(String rawJson){
        PAG_PersonaModels.PersonaEvent evt = (PAG_PersonaModels.PersonaEvent)
            JSON.deserialize(rawJson, PAG_PersonaModels.PersonaEvent.class);

        // --- validation ---
        if(evt==null || evt.messageType!='persona.state') throw new PAG_Errors.ValidationException('Invalid messageType');
        if(!PAG_PersonaModels.isValidType(evt.persona.type)) throw new PAG_Errors.ValidationException('Invalid persona.type');
        if(!PAG_PersonaModels.isValidSubType(evt.persona.subType)) throw new PAG_Errors.ValidationException('Invalid persona.subType');
        if(evt.persona.type=='Applicant' && !PAG_PersonaModels.isValidApplicantState(evt.state.value)) throw new PAG_Errors.ValidationException('Invalid Applicant state');
        if(evt.persona.type=='Student' && !PAG_PersonaModels.isValidStudentState(evt.state.value)) throw new PAG_Errors.ValidationException('Invalid Student state');
        if(String.isBlank(evt.idempotencyKey)) throw new PAG_Errors.ValidationException('idempotencyKey required');

        // === NEW: early idempotency pre-check (no-op if already processed) ===
        List<PAG_Idempotency__c> prior = [
            SELECT Id FROM PAG_Idempotency__c WHERE PAG_Key__c = :evt.idempotencyKey LIMIT 1
        ];
        if(!prior.isEmpty()){
            Result rr = new Result();
            rr.created = false; // indicate replay
            return rr;
        }

        // --- resolve/create Contact ---
        Contact c = null;
        if(evt.subject != null && !String.isBlank(evt.subject.moid)){
            List<Contact> byMo = [
                SELECT Id, PAG_MoID__c, PAG_BannerID__c
                FROM Contact WHERE PAG_MoID__c = :evt.subject.moid LIMIT 1
            ];
            if(!byMo.isEmpty()) c = byMo[0];
        }
        if(c==null && evt.subject != null && !String.isBlank(evt.subject.sorPersonId)){
            List<Contact> bySoRId = null; 
            if (evt.subject.sor == 'banner') {
                bySoRId = [
                    SELECT Id, PAG_MoID__c, PAG_BannerID__c
                    FROM Contact WHERE PAG_BannerID__c = :evt.subject.sorPersonId LIMIT 1
                ];
            }
            if (evt.subject.sor == 'unicrm') {
                bySoRId = [
                    SELECT Id, PAG_MoID__c
                    FROM Contact WHERE Id = :evt.subject.sorPersonId LIMIT 1
                ];
            }           
            if(!bySoRId.isEmpty()) {
                c = bySoRId[0];
            }
        }
        if(c==null){
            c = new Contact(LastName = 'PLM-' + String.valueOf(DateTime.now().getTime()));
            insert c;
        }
        Contact upd = new Contact(Id=c.Id);
        if(evt.subject != null && !String.isBlank(evt.subject.moid)) upd.PAG_MoID__c = evt.subject.moid;
        if(evt.subject != null && evt.subject.sor == 'banner' && !String.isBlank(evt.subject.sorPersonId)) upd.PAG_BannerID__c = evt.subject.sorPersonId;
        update upd;
        c = [SELECT Id, PAG_MoID__c FROM Contact WHERE Id=:c.Id];

        // --- mint MoID if missing (publish event if minted & SoR known) ---
        Boolean minted = false;
        String moid = String.isBlank(c.PAG_MoID__c) ? PAG_Util.mintMoID() : c.PAG_MoID__c;
        if(String.isBlank(c.PAG_MoID__c)){
            update new Contact(Id=c.Id, PAG_MoID__c = moid);
            minted = true;
        }
        String key = PAG_Util.compositeKey(moid, evt.persona.type, evt.persona.subType, evt.persona.context);
        if(minted && evt.subject != null && !String.isBlank(evt.subject.sor) && !String.isBlank(evt.subject.sorPersonId)){
            PAG_Events.publishMoIDMinted(evt.subject.sor, evt.subject.sorPersonId, moid, c.Id, key);
        }

        // --- current snapshot (MECE) ---
        PAG_Persona_Aggregation__c current = null;
        Boolean insertOrigin = false;
        List<PAG_Persona_Aggregation__c> cur = [
            // === NEW: include PAG_CompositeKey__c in the query ===
            SELECT Id, PAG_CompositeKey__c, PAG_State__c, PAG_StartDate__c, PAG_EndDate__c, PAG_Origin__c, PAG_Reason__c
            FROM PAG_Persona_Aggregation__c
            WHERE PAG_CompositeKey__c = :key
            LIMIT 1
        ];
        if(!cur.isEmpty()) {
            current = cur[0]; // persona with this key exists
        } else {
            insertOrigin = true; // write origin only once on first persona with this key
        }

        system.debug(evt);

        if(current != null) {
            if ((current.PAG_State__c != evt.state.value) || (current.PAG_Reason__c != evt.state.reason)){
                current.PAG_EndDate__c = evt.state.startDate;
                update current;
                current = null; // force create of a new “current” row below
            } 
        }

        if(current == null){ 
            current = new PAG_Persona_Aggregation__c();
            current.PAG_CompositeKey__c = key;   // ensure external id is set
            current.PAG_MoID__c        = moid;
            current.PAG_Contact__c     = c.Id;
            current.PAG_Type__c        = evt.persona.type;
            current.PAG_SubType__c     = evt.persona.subType;
            current.PAG_Context__c     = evt.persona.context;
            if (insertOrigin) {
                current.PAG_Origin__c  = (evt.persona.origin != null ? evt.persona.origin : null); // Set only on 1st persona instance
            }
        } else {
            // === NEW: defensive — keep key on the sObject instance ===
            current.PAG_CompositeKey__c = key;
        }

        current.PAG_State__c           = evt.state.value;
        current.PAG_Reason__c          = evt.state.reason;
        current.PAG_StartDate__c       = evt.state.startDate;
        current.PAG_EndDate__c         = evt.state.endDate;
        current.PAG_SoR__c             = (evt.subject != null ? evt.subject.sor : null);
        current.PAG_Sequence__c        = evt.sequence;
        current.PAG_RecordedAt__c      = evt.recordedAt;
        current.PAG_OriginEventJson__c = rawJson;

        // === NEW: avoid upsert-by-external-id when Id exists ===
        if(current.Id != null){
            update current;
        } else {
            upsert current PAG_CompositeKey__c;
        }

        // --- immutable history ---
        PAG_Persona_Aggregation_History__c h = new PAG_Persona_Aggregation_History__c();
        h.PAG_PersonaAggregation__c = current.Id;
        h.PAG_IdempotencyKey__c     = evt.idempotencyKey;
        h.PAG_SoR__c                = (evt.subject != null ? evt.subject.sor : null);
        h.PAG_Sequence__c           = evt.sequence;
        h.PAG_Producer__c           = evt.producer;
        h.PAG_OccurredAt__c         = evt.occurredAt;
        h.PAG_RecordedAt__c         = evt.recordedAt;
        h.PAG_Type__c               = evt.persona.type;
        h.PAG_SubType__c            = evt.persona.subType;
        h.PAG_Context__c            = evt.persona.context;
        h.PAG_Origin__c             = (evt.persona.origin != null ? evt.persona.origin : null);
        h.PAG_State__c              = evt.state.value;
        h.PAG_Reason__c             = evt.state.reason;
        h.PAG_StartDate__c          = evt.state.startDate;
        h.PAG_EndDate__c            = evt.state.endDate;
        h.PAG_RuleId__c             = evt.state.ruleId;
        h.PAG_MessageType__c        = evt.messageType;
        h.PAG_RawJson__c            = rawJson;
        h.Contact__c                = c.Id;
        insert h;

        // === NEW: idempotency write that works with either lookup field ===
        Schema.SObjectType t = Schema.getGlobalDescribe().get('PAG_Idempotency__c');
        Schema.DescribeSObjectResult d = t.getDescribe();
        Map<String, Schema.SObjectField> fm = d.fields.getMap();

        SObject idem = t.newSObject();
        idem.put('PAG_Key__c', evt.idempotencyKey);
        idem.put('PAG_ProcessedAt__c', System.now());
        if(fm.containsKey('PAG_PersonaAggHistory__c')){
            idem.put('PAG_PersonaAggHistory__c', h.Id);
        } else if (fm.containsKey('PAG_PersonaHistory__c')){
            idem.put('PAG_PersonaHistory__c', h.Id);
        }
        upsert idem; // upsert by external id (PAG_Key__c)

        Result r = new Result();
        r.contactId = c.Id; r.personaId = current.Id; r.historyId = h.Id; r.created = true; r.moid = moid;
        return r;
    }   
}