/**
 * @author       Monash University
 * @date         19/09/2019
 * @description  General Name__c services
 * @revision     1.0
 *               15.06.2020 - J.Mapanao     - Added logic to not deselect primary when user previously selected manually
 *	 			 03.05.2021 - Martin Cadman - Added rollup rank sorting for student names
 *	 			 12.05.2022 - Tom Gangemi   - SA-1477 - Added class for primary record sorting
 *               07.03.2023 - Martin Cadman - Consistent handling of null values in generatefullname
 *               07-07-2023 - Nick Guia     - rephrased the code to get default picklist value of Name.Type__c
 */
public class NameServices {
   /*
	* @description Hash is generated against a case insenitive (not including the contact id) string
	* @param nameRecord A name contact point record
	* @return A UUID produced from the name fields
    */
	@InvocableMethod (label='Generate Name unique key' description='Returns a UID based on current record state')
    public static list<String> generateKeyUID(list<Name__c> nameRecords) {
        return new list<String>{generateKeyUID(nameRecords[0])};
    }

    /* 
     * @description Build the keyset and generate the unique key for a name record. 
     * 
	 * NOTE THAT THIS DUPLICATES LOGIC IN CONTACTPOINTUTILITY. CHANGES HERE MAY NEED TO BE REFLECTED THERE.
     **/
    public static String generateKeyUID(Name__c nameRecord) {
        // add the Name__c.Contact__c Id to the set
        Set<String> keySet = new Set<String> {nameRecord.Contact__c};

        // Distingush Type 
        if (nameRecord.Type__c == null) {
            nameRecord.Type__c = (String) Schema.Name__c.Type__c.getDescribe().getDefaultValue();
        }
        keySet.add(nameRecord.Type__c.toLowercase());
            
        // generate fullName
        String fullName = generateFullName(nameRecord);

        // add the Full Name into the set as one of the key parameters
        if (String.isNotBlank(fullName)) {
            keySet.add(fullName.toLowercase());
        }         

        // generate Key and return
        return Person360Helper.generatePerson360Key(keySet);
    }

   /*
    * @description Generates concatenated string based on the populated fields of the parametre
    * @param nameRecord A populated name__c record
    * @return A concatenated string presenting the fullname, no spaces
    */
    public static String generateFullName(Name__c nameRecord) {
        // format the name
        String fullName = Person360Helper.formatName(nameRecord.First_Name__c, nameRecord.Middle_Name__c, nameRecord.Last_Name__c);

        // add Salutation, Prefix, Suffix
        fullName += nameRecord.Prefix__c==''?null:nameRecord.Prefix__c;
        fullName += nameRecord.Salutation__c==''?null:nameRecord.Salutation__c;
        fullName += nameRecord.Suffix__c==''?null:nameRecord.Suffix__c;

        // return Full Name
        return fullName;
    }

    /**
     * @description Given a list of Name__c records, calculate and return the primary
     * @param names A list of names for sorting
     * @param isStudent An active student indicator
     * @return A list of names sorted based on different business criteria
     */
    public static Name__c findPrimary(Name__c[] names, Boolean isStudent) {
        Person360Helper.SortableContactPoint[] sortableNames = new Person360Helper.SortableContactPoint[0];
        for(Name__c n :names) {
            // rollup rank of 10 and 100 used to reflect existing Name__c.Rollup_Rank__c field logic
            // 10 is a callista record for a student, 100 is everything else
            sortableNames.add(new Person360Helper.SortableContactPoint(n, isStudent && n.Type__c == 'Student Name' ? 10 : 100));
        }
        sortableNames.sort();
        return (Name__c)sortableNames[0].obj;
    }
}