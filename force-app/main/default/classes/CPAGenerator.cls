/**
 * @description  CPA creation class that will be invoked on a Quick Action button click on 
 *              Affiliation record
 * @author      Shalini Mendu
 * @since       20/02/2024
 * @group       Admissions
 */
public class CPAGenerator {

    /**
        * @description Invocable method to create Contact Point Affiliations
                       on a button click on the  Affiliation record
        * @param affiliationId : List of Affiliation record Ids
        * @revision
    **/
    @InvocableMethod
    public static void createCPAs(List < String > affiliationId) {
        Map < Id, Id > affContactMap = new Map < Id, Id > ();
        Map < Id, Phone__c > conPhoneMap = new Map < Id, Phone__c > ();
        Map < Id, Email__c > conEmailMap = new Map < Id, Email__c > ();
        Map < Id, Address__c > conAddressMap = new Map < Id, Address__c > ();
        List < String > mobilePhones = new List < String > ();
        List < String > personalEmails = new List < String > ();
        List < Person360 > p360List = new List < Person360 > ();

        //Query the Affiliations
        List < Affiliation__c > affList = [select id, Contact__c, Contact__r.Id, Contact__r.Mobilephone,
            Contact__r.Personal_email__c, Start_date__c
            from Affiliation__c where Id =: affiliationId ];
        try {
            for (Affiliation__c aff: affList) {
                    //Map<AffiliationId, Contact__c>
                    affContactMap.put(aff.Id, aff.Contact__c);

                    //Add MobilePhone to a List
                    mobilePhones.add(aff.Contact__r.Mobilephone);

                    //Add Personal_Email__c to a List
                    personalEmails.add(aff.Contact__r.Personal_email__c);
            }

            //Map<Id,Contact>>
            Map < Id, Contact > contactMap = new Map < Id, Contact > ([select id, AccountId from Contact where Id =: affContactMap.values()]);
            //Phone__c, Email__c, Address__c maps with latest Start_date__c 
            conPhoneMap = populateContactPhoneMap(mobilePhones, new Set<Id>(affContactMap.values()));
            conEmailMap = populateContactEmailMap(personalEmails, new Set<Id>(affContactMap.values()));
            conAddressMap = populateContactAddressMap(new Set<Id>(affContactMap.values()));

            Person360BuilderDirector.Options opt = new Person360BuilderDirector.Options();
            //Iterate over Affiliations
            for (Affiliation__c aff: affList) {
                    //Get Contact instance to pass it to the builder
                    Id conId = affContactMap.get(aff.Id);
                    Contact con = contactMap.get(conId);
                    //Instantiate the builder
                    Person360.Person360Builder builder = new Person360.Person360Builder(con);
                    opt.commitContact = false;
                    opt.commitAffiliation = false;
                    opt.commitContactPoints = false;
                    opt.useExternalId = false;
                    //Create CPAs for Phone/Email/Address
                    builder.withAffiliation(aff)
                        .withPhone(conPhoneMap.get(con.Id))
                        .withEmail(conEmailMap.get(con.Id))
                        .withAddress(conAddressMap.get(con.Id));

                    // build the Person360Builder and add the builder to a List
                    p360List.add(builder.build());
            }

            //Resolve dependencies
            BaseClass bc = new Person360BuilderDirector().resolveDependencies(p360List, opt).getBaseClass();
            //commit records partially
            BaseClass.ResultSet result = bc.commitRecordsPartial();

        } catch (Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex);
            //Throw exception so that the screen can show on Quick action
            throw new CPAGeneratorException('Unable to create CPAs due to ' + ex.getMessage() + ' at ' + ex.getLineNumber());
        }
        Nebula.Logger.saveLog();
    }


    /**
        * @description Method that populates Contact->Phone__c map
        * @param names : List of Mobilephone of Contact
        * @param conIds : List of ContactIds
        * @Return Map < Id, Phone__c > : Map of Contact->Phone__c 
        * @revision
    **/
    private static Map < Id, Phone__c > populateContactPhoneMap(List < String > names, Set < Id > contIds) {
        //Initialize PhoneComparable list
        List < PhoneComparable > compList = new List < PhoneComparable > ();

        //Initialize Contac,Phone__c Id,Id into a Map
        Map < Id, Id > contactPhoneIdMap = new Map < Id, Id > ();
        
        //Initialize Contac,Phone__c Id,record into a Map
        Map < Id, Phone__c > contactPhoneMap = new Map < Id, Phone__c > ();
 
        //Retrieve Id,Phone map of all the ContactIds and the Name combination
        Map < Id, Phone__c > phMap = new Map < Id, Phone__c > ([select Id,Channel__c, Start_date__c, CreatedDate, Type__c, Contact__c from Phone__c
                                                                where name =: names and is_Active__c =true and Contact__c =: contIds]);

        //Get the Phone__c list to feed it to PhoneComparable
        List < Phone__c > phList = (List < Phone__c > ) phMap.values();

        //Construct PhoneComparable with the Phone__c list 
        for (Phone__C ph: phList) {
            compList.add(new PhoneComparable(ph));
        }
        //Sort the PhoneComparable list to order by Start_Date__c desc
        compList.sort();
        //Go over compList to add the first PhoneComparable record for a Contact into a Map
        for (PhoneComparable cp: compList) {
            Id cId = (Id) cp.compareFrom.get('Contact__c');
            if (contactPhoneIdMap.get(cId) == null) {
                contactPhoneIdMap.put(cId, cp.compareFrom.Id);
            }
        }
        //Query all the Phone__c records from the Map 
        Map < Id, Phone__c > phoneMap = new Map < Id, Phone__c > ([select Id, Contact__c from Phone__c where 
                                                                   id =: contactPhoneIdMap.values()]);
        //Construct ContactId, Phone__c map                                                                   
        for (Id idd: phoneMap.keySet()) {
            contactPhoneMap.put(phoneMap.get(idd).Contact__c, phoneMap.get(idd));
        }
 
        return contactPhoneMap;
    }

    /**
    * @description Method that populates Contact->Email__c map
    * @param personalEmails : List of Email__c of Contact
    * @param conIds : List of ContactIds
    * @Return Map < Id, Address__c > : Map of Contact->Email__c 
    * @revision
    **/
    private static Map < Id, Email__c > populateContactEmailMap(List < String > personalEmails, Set < Id > contIds) {
         //Initialize EmailComparable list
        List < EmailComparable > compList = new List < EmailComparable > ();
         //Initialize Contac,Email__c Id,Id into a Map
        Map < Id, Id > contactEmailId = new Map < Id, Id > ();
        //Initialize Contac,Email__c Id,record into a Map
        Map < Id, Email__c > contactEmailMap = new Map < Id, Email__c > ();

        //Retrieve Id,Email map of all the ContactIds and the Name combination
        Map < Id, Email__c > emailMap = new Map < Id, Email__c > ([select Id, Channel__c, Start_date__c, CreatedDate, Contact__c from Email__c
                                                                where name =: personalEmails and  is_Active__c =true and Contact__c =: contIds]);
        
        //Get the Email__c list to feed it to EmailComparable
        List < Email__c > emailList = (List < Email__c > ) emailMap.values();
        
        //Construct EmailComparable with the Email__c list 
        for (Email__c em: emailList) {
            compList.add(new EmailComparable(em));
        }
        
        //Sort the EmailComparable list to order by Start_Date__c desc
        compList.sort();
       
       //Go over compList to add the first EmailComparable record for a Contact into a Map
        for (EmailComparable cp: compList) {
            Id cId = (Id) cp.compareFrom.get('Contact__c');
            if (contactEmailId.get(cId) == null) {
                contactEmailId.put(cId, cp.compareFrom.Id);
            }
        }
        //Query all the Email__c records from the Map 
        Map < Id, Email__c > emMap = new Map < Id, Email__c > ([select Id, Contact__c from Email__c where id =: contactEmailId.values()]);
       //Construct ContactId, Email__c map   
        for (Id idd: emMap.keySet()) {
            contactEmailMap.put(emMap.get(idd).Contact__c, emMap.get(idd));
        }
 
        return contactEmailMap;
    }



     /**
    * @description Method that populates Contact->Address__c map
    * @param conIds : List of ContactId
    * @Return Map < Id, Address__c > : Map of Contact->Address__c 
    * @revision
    **/
    private static Map < Id, Address__c > populateContactAddressMap(Set < Id > contIds) {
        Map < Id, Address__c > conAddressMap = new Map < Id, Address__c > ();

        Map < Id, Address__c > addressMap = new Map < Id, Address__c > ([select Id, Contact__c from Address__c
            where is_primary__c = true and is_Active__c = true and Contact__c =: contIds]);
       
        //Put <<ContactId, Phone__C>> in a map
        for (Address__c email: (List < Address__c > ) addressMap.values()) {
            conAddressMap.put(email.Contact__c, email);
        }
        return conAddressMap;

    }

   
    
    public class CPAGeneratorException extends Exception {}

}