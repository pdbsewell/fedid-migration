/**
 * FoC_Service.cls
 * The "Traffic Cop". Orchestrates resolution, MoID minting, and Persona updates 
 * in a single execution context.
 */
public with sharing class FoC_Service {

    public static FoC_DTOs.Result process(FoC_DTOs.Request req) {
        FoC_DTOs.Result res = new FoC_DTOs.Result();
        Savepoint sp = Database.setSavepoint(); 

        try {
            // STEP 1: RESOLVE (Get Wrapper)
            // We get the Contact PLUS the status flags (isNew, hasAmbiguity)
            FoC_ContactResolver.ResolutionOutcome outcome = FoC_ContactResolver.resolve(req);
            Contact contactRecord = outcome.record;
            
            // STEP 2: COMMIT PARENT
            // If it was strict matched, this is an update. If new, it was already inserted in Resolver.
            // Safe to upsert to ensure we have the latest state.
            upsert contactRecord;
            
            // STEP 3: MINT IDENTITY (Child Object)
            // Pass the ID to the Minter
            String moid = FoC_MoIDService.ensureMoID(contactRecord.Id);
            
            // STEP 4: AGGREGATE PERSONA (Child Object)
            if (req.persona != null) {
                // Pass the MoID explicitly as it lives on the Child Object now
                FoC_PersonaAggregator.upsertPersona(contactRecord.Id, moid, req.persona, req.idempotencyKey);
            }

            // STEP 5: PREPARE RESULT (Consistent with DTO)
            res.isSuccess = true;
            res.contactId = contactRecord.Id;
            res.moid = moid; 
            
            // Correctly populated from the Resolver Outcome wrapper
            res.isNewContact = outcome.isNew; 
            res.isPotentialDuplicate = outcome.hasAmbiguity;
            
        } catch (Exception e) {
            Database.rollback(sp);
            res.isSuccess = false;
            res.message = e.getMessage();
        }

        return res;
    }
}