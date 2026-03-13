/**
 * @description       : Responsible for reparenting Contact Points to the surviving CPAs
 *                      and CPAs to the surviving Affiliation.
 * @date              : 12-07-2023
 * @group             : Contact Merge
 * @author            : Nick Guia
 * @last modified on  : 23-08-2023
 * @last modified by  : Nick Guia
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/286688267/Contact+Merge+Person+360
 * @revision
 *      03-08-2023  Nick Guia   - added calculatePrimaryContactPoints()
 *                              - removed mergePerson360 so we can calculate primary and ingest is_Student__c
 * 
 * @example
 * 
 *  // codes here to build p360List via ContactMergePerson360...
 * 
 *  ContactMergeP360Director director = new ContactMergeP360Director();
 *  director.resolveDependencies(p360List); // resolve all dependencies
 *  director.calculatePrimaryContactPoints(con.Is_Student__c); // recalculate the new primary
 *  Boolean isSuccess = director.commitRecords(); // commit records
 * 
**/
public virtual inherited sharing class ContactMergeP360Director extends Person360BuilderDirector {

    @TestVisible
    private CalculatePrimaryContactPointService calculatePrimaryService;

    public ContactMergeP360Director() {
        this(new ContactMergeBaseClass());
    }

    /**
    * @description resolve the dependencies from the perspective of Contact Merge:
    *   - Resolve Contact Point Affiliation => Affiliation
    *   - Resolve Contact Point Affiliation => Contact Point
    *   - Each external IDs that will be processed will be registered in a cache. For a subsequent (duplicate)
    *     external IDs will be deleted.
    *   - The method would also iterate through each SObjectType on the P360 attributes, rather than
    *     the otherway around. This allows us to regsiter all unique keys in the first instance - enabling
    *     a proactive insert/update OR delete, rather than insert/update > if fails - delete
    *   - Elements with lower index (added earlier) will have the higher likelyhood of surviving the merge.
    * @author Nick Guia | 18-07-2023 
    * @param Person360 p360 
    * @return Person360BuilderDirector 
    *   ASSUMPTIONS MADE :
    *       - The Database.merge() has already executed meaning - the Account and Contact relationships have already been resolved.
    *       - all unique external IDs have already been recalculated by the builder (except for CPA)
    **/
    public override Person360BuilderDirector resolveDependencies(List<Person360> p360List) {
        /**
         * STEP 1 : commit Affiliation changes.
         */
        resolveAffiliations(p360List);
        /**
         * STEP 2 : commit Contact Point changes
         */
        resolveContactPoints(p360List);
        /**
         * STEP 3 : commit Contact Point Affiliation changes
         */
        resolveContactPointAffiliations(p360List);

        return this;
    }

    /**
    * @description calculates the new primary contact points
    * @author Nick Guia | 03-08-2023 
    * @param Boolean isStudent 
    * @return Person360BuilderDirector 
    **/
    public Person360BuilderDirector calculatePrimaryContactPoints(Boolean isStudent) {
        
        ContactMergeBaseClass contactMergeBc = (ContactMergeBaseClass) super.bc;

        List<Phone__c> phoneRegister = (List<Phone__c>) contactMergeBc.pull(Phone__c.SObjectType);
        List<Email__c> emailRegister = (List<Email__c>) contactMergeBc.pull(Email__c.SObjectType);
        List<Address__c> addressRegister = (List<Address__c>) contactMergeBc.pull(Address__c.SObjectType);
        List<Name__c> nameRegister = (List<Name__c>) contactMergeBc.pull(Name__c.SObjectType);

        CalculatePrimaryContactPointService.Input param = new CalculatePrimaryContactPointService.Input(isStudent);
        param.shouldSort = true;
        param.phoneList = phoneRegister;
        param.emailList = emailRegister;
        param.addressList = addressRegister;
        param.nameList = nameRegister;
        // do not include the baseclass in this parameter, or this will error out with duplicate ids in the commit list

        new CalculatePrimaryContactPointService().calculate(param);

        return this;
    }

    /**
    * @description commit Affiliation changes and register their new unique keys
    * @author Nick Guia | 18-07-2023 
    * @param List<Person360> p360List 
    **/
    @TestVisible
    private void resolveAffiliations(List<Person360> p360List) {
        for(Person360 p360 : p360List) {
            Affiliation__c aff = p360.getAffiliation();
            if(aff != null) {
                registerSObject(aff, aff.Composite_Key__c);
            }
        }
    }

    /**
    * @description commit Contact Point changes and register their new unique keys
    * @author Nick Guia | 18-07-2023 
    * @param List<Person360> p360List 
    **/
    @TestVisible
    private void resolveContactPoints(List<Person360> p360List) {
        for(Person360 p360 : p360List) {
            Map<String, List<SObject>> contactPointMap = p360.getContactPointMap();
            if(contactPointMap != null) {
                for(String cpSObjType : contactPointMap.keySet()) {
                    // STEP 3 : commit Contact Point changes
                    registerSObject(contactPointMap.get(cpSObjType), 'Key_UID__c');
                }
            }
        }
    }

    /**
    * @description resolves the linkage between:
    *   Contact Point Affiliation => Affiliation
    *   Contact Point Affiliation => Contact Point
    * @author Nick Guia | 18-07-2023 
    * @param List<Person360> p360List 
    *   NOTE: The class assumes that Affiliations and Contact Points have been resolved
    *         and that their unique keys have been registered.
    **/
    @TestVisible
    private void resolveContactPointAffiliations(List<Person360> p360List) {

        for(Person360 p360 : p360List) {

            Map<String, List<Contact_Point_Affiliation__c>> cpaMap = p360.getContactPointAffiliationMap();

            if(cpaMap != null) {
                
                Affiliation__c affiliation = p360.getAffiliation();
                
                Map<String, List<SObject>> contactPointMap = p360.getContactPointMap();

                for(String cpaType : cpaMap.keySet()) {
                    // convert all the related contact points to a map of Id => SObject
                    Map<Id, SObject> cpMapByRecordId = new Map<Id, SObject>(contactPointMap.get(cpaType));

                    for(Contact_Point_Affiliation__c cpa : cpaMap.get(cpaType)) {
                        /**
                         * STEP 1: resolve Contact Point Affiliation => Affiliation
                         * since the Affiliation record in this P360 instance may not survive,
                         * get the record ID of the Affiliation record that is guaranteed to survive
                         * from the registry, and use that instead
                         */
                        SObject survivingAffiliation = ((ContactMergeBaseClass) super.bc).pull(Affiliation__c.SObjectType, affiliation.Composite_Key__c);
                        cpa.Affiliation__c = survivingAffiliation.Id;

                        /**
                         * STEP 2: resolve Contact Point Affiliation => Contact Point
                         * since the contact point record in this P360 instance may not survive,
                         * get the record ID of the contact point record that is guaranteed to survive
                         * from the registry, and use that instead
                         */
                        Id tempCpId = ContactPointUtility.getContactPointIdFromCPA(cpa);
                        // get the unique hash of the currently related contact point
                        String cpHash = (String) cpMapByRecordId.get(tempCpId)?.get('Key_UID__c');
                        // find the surviving contact point
                        SObject survivingCp = ((ContactMergeBaseClass) super.bc).pull(tempCpId.getSobjectType(), cpHash);
                        String cpLookupField = ContactPointUtility.getContactPointLookupFieldFromCPA(cpa);
                        // form relationship
                        cpa.put(cpLookupField, survivingCp.Id);

                        /**
                         * STEP 3: once all the required lookups are resolved, the record
                         * is now ready to generate a new composite key, then register
                         */
                        cpa.Composite_Key__c = ContactPointUtility.getContactPointAffiliationKey(cpa);
                        registerSObject(cpa, cpa.Composite_Key__c);
                    }
                }
            }
        }
    }

    /**
    * @description manages the insert/update/delete of records depending on
    *   whether their external Id is unique in the register or not.
    *   Throws a Developer Exception if the unique key is null or blank
    * @author Nick Guia | 18-07-2023 
    * @param SObject rec : the record to register
    * @param String extId : the unique external Id of the record
    **/
    @TestVisible
    private void registerSObject(SObject rec, String extId) {
        try {
            // push if unique, pop if duplicate
            ((ContactMergeBaseClass) super.bc).registerRecord(rec, extId);
        } catch(ContactMergeBaseClass.ContactMergeBaseClassDeveloperException e) {
            throw new ContactMergeP360DirectorDeveloperException('You must calculate the unique keys prior to merging');
        } catch(Exception e) {
            throw new ContactMergeP360DirectorException('Unexpected error while registering SObject key : ' + e.getMessage());
        }
    }

    /**
    * @description manages the insert/update/delete of records depending on
    *   whether their external Id is unique in the register or not.
    *   Throws a Developer Exception if the unique key is null or blank
    * @author Nick Guia | 18-07-2023 
    * @param List<SObject> recordList 
    * @param String externalIdAPIName 
    **/
    @TestVisible
    private void registerSObject(List<SObject> recordList, String externalIdAPIName) {
        for(SObject rec : recordList) {
            registerSObject(rec, (String) rec.get(externalIdAPIName));
        }
    }

    @TestVisible // for test mocking
    private ContactMergeP360Director(ContactMergeBaseClass bc) {
        super(bc);
    }

    public class ContactMergeP360DirectorDeveloperException extends Exception { }

    public class ContactMergeP360DirectorException extends Exception { }
}