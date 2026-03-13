/**
 * @description       : Selector class for Contact Merge processes
 * @date              : 11-07-2023
 * @group             : Contact Merge
 * @author            : Nick Guia
 * @last modified on  : 23-08-2023
 * @last modified by  : Nick Guia
 * @revision
 *      03-08-2023  Nick Guia   - added selectContact()
 *      04-08-2023  Nick Guia   - bulkified all queries to cater for multiple contact Ids
 *                              - added methods to group query result sets by Contact ID
 * 
 *  NOTE:
 *      -   any query that has an ORDER BY need to strictly return a List type
 *      -   any change in ordering will affect the survivorship of the contact merge
**/
public virtual inherited sharing class ContactMergeSelector {

    private final Set<Id> contactIds;
        
    public ContactMergeSelector(Set<Id> contactIdSet) {
        this.contactIds = contactIdSet;
    }   

    /**
    * @description Requery the Contact record during contact merge for the following reasons:
    *   - get the Is_student__c field for contact points primary calculation
    *   - get an exclusive locks on the object due to potential race conditions and avoid rolling back the
    *     changes of (only) a specific step of the contact merge where the race condition occurs.
    * @author Nick Guia | 04-08-2023 
    * @return Map<Id, Contact> 
    **/
    public Map<Id, Contact> selectContacts() {
        return new Map<Id, Contact>(
            [SELECT Id, Is_student__c 
                FROM Contact
                WHERE Id IN :this.contactIds
                FOR UPDATE]
        );
    }

    /**
    * @description Group the result set of affiliations by its parent contact ID
    * @author Nick Guia | 04-08-2023 
    * @param String recTypeDevName 
    * @return Map<Id, List<Affiliation__c>> 
    **/
    public Map<Id, List<Affiliation__c>> selectAffiliationsGroupedByContactId(String recTypeDevName) {
        return (Map<Id, List<Affiliation__c>>) groupRecordsBy('Contact__c', selectAffiliations(recTypeDevName));
    }

    /**
    * @description Group the result set of affiliations by its parent contact ID
    * @author Nick Guia | 04-08-2023 
    * @return Map<Id, List<Affiliation__c>> 
    **/
    public Map<Id, List<Affiliation__c>> selectAffiliationsGroupedByContactId() {
        return selectAffiliationsGroupedByContactId('');
    }

    /**
    * @description Group the result set of Names by its parent contact ID
    * @author Nick Guia | 04-08-2023 
    * @return Map<Id, List<Name__c>> 
    **/
    public Map<Id, List<Name__c>> selectNamesGroupedByContactId() {
        return (Map<Id, List<Name__c>>) groupRecordsBy('Contact__c', selectNames());
    }

    /**
    * @description Group the result set of Phones by its parent contact ID
    * @author Nick Guia | 04-08-2023 
    * @return Map<Id, List<Phone__c>> 
    **/
    public Map<Id, List<Phone__c>> selectPhonesGroupedByContactId() {
        return (Map<Id, List<Phone__c>>) groupRecordsBy('Contact__c', selectPhones());
    }

    /**
    * @description Group the result set of Addresses by its parent contact ID
    * @author Nick Guia | 04-08-2023 
    * @return Map<Id, List<Address__c>> 
    **/
    public Map<Id, List<Address__c>> selectAddressesGroupedByContactId() {
        return (Map<Id, List<Address__c>>) groupRecordsBy('Contact__c', selectAddresses());
    }

    /**
    * @description Group the result set of Emails by its parent contact ID
    * @author Nick Guia | 04-08-2023 
    * @return Map<Id, List<Email__c>> 
    **/
    public Map<Id, List<Email__c>> selectEmailsGroupedByContactId() {
        return (Map<Id, List<Email__c>>) groupRecordsBy('Contact__c', selectEmails());
    }

    /**
    * @description Group the result set of CPAs by its parent contact ID
    * @author Nick Guia | 04-08-2023 
    * @return Map<Id, List<Contact_Point_Affiliation__c>> 
    **/
    public Map<Id, List<Contact_Point_Affiliation__c>> selectCPAsGroupedByContactId() {
        return (Map<Id, List<Contact_Point_Affiliation__c>>) groupRecordsBy('Contact__c', selectCPAs());
    }

    /**
    * @description select Affiliation records related to the contact
    * @author Nick Guia | 11-07-2023 
    * @return List<Affiliation__c>
    **/
    public List<Affiliation__c> selectAffiliations() {
        return selectAffiliations('');
    }
    
    /**
    * @description select Affiliation records related to the contact
    * @author Nick Guia | 11-07-2023 
    * @param String recTypeDevName : filter by Affiliation record type developer name
    * @return List<Affiliation__c>
    **/
    public List<Affiliation__c> selectAffiliations(String recTypeDevName) {
        String wClause = 'Contact__c IN :contactIds'; // filter by Contact IDs
        wClause = String.isNotBlank(recTypeDevName) ? wClause + ' AND RecordType.DeveloperName = :recTypeDevName' : wClause; // maybe filter by record type
        wClause += ' ORDER BY LastModifiedDate DESC';
        String soqlStr = DynamicSoqlBuilder.getInstance()
                            .showSOQLStatement(true)
                            .setEnforced(false)
                            .querySObject('Affiliation__c')
                            .validateFields(false)
                            .queryFields(
                                new Set<String>{
                                    'Id',
                                    'Account__c',
                                    'Account_Communications__c',
                                    'Composite_Key__c',
                                    'Contact__c', 
                                    'Department__c',
                                    'Description__c',
                                    'End_Date__c',
                                    'Engagement_Scoring_Applied__c',
                                    'isActive__c',
                                    'Opportunity__c',
                                    'Position__c',
                                    'Position_Level__c',
                                    'Program__c',
                                    'Roles__c',
                                    'Share_Contact_to_Account_Role__c',
                                    'Share_Force_Recalculation__c',
                                    'Sharing_Composite_Key__c',
                                    'Start_Date__c',
                                    'Account__r.Name', 
                                    'RecordTypeId',
                                    'LastModifiedDate'
                                })
                            .getQuery(wClause);
        return Database.query(soqlStr);
    }

    /**
    * @description select Name records related to the contact
    * @author Nick Guia | 11-07-2023 
    * @return List<Name__c>
    **/
    public List<Name__c> selectNames() {
        return [
            SELECT Id, Contact__c, Type__c, Suffix__c, Prefix__c, First_Name__c, Middle_Name__c, Last_Name__c, Salutation__c, Key_Uid__c,
            Start_Date__c, CreatedDate, Is_Primary__c, Rollup_Rank__c, Primary_set_by__c
            FROM Name__c
            WHERE Contact__c IN :this.contactIds
        ];
    }

    /**
    * @description select Phone records related to the contact
    * @author Nick Guia | 11-07-2023 
    * @return List<Phone__c>
    **/
    public List<Phone__c> selectPhones() {
        return [
            SELECT Id, Contact__c, Name, Type__c, Key_UID__c, Is_Primary__c, Primary_set_by__c,
                Start_date__c, CreatedDate, Channel__c
            FROM Phone__c 
            WHERE Contact__c IN :this.contactIds
            ORDER BY Start_date__c DESC, Channel__c NULLS LAST
        ];
    }

    /**
    * @description select Email records related to the contact
    * @author Nick Guia | 11-07-2023 
    * @return List<Email__c>
    **/
    public List<Email__c> selectEmails() {
        return [
            SELECT Id, Contact__c, Contact__r.Is_Student__c, Name, Classification__c, Key_UID__c, Is_Primary__c, Primary_set_by__c,
                Start_date__c, CreatedDate, Channel__c
            FROM Email__c 
            WHERE Contact__c IN :this.contactIds
            ORDER BY Start_date__c DESC, CreatedDate DESC, Channel__c NULLS LAST
        ];
    }

    /**
    * @description select Address records related to the contact
    * @author Nick Guia | 11-07-2023 
    * @return Map<Id, Address__c> 
    **/
    public List<Address__c> selectAddresses() {
        return [
            SELECT Id, Contact__c, Street_name__c, City__c, Country2__c, Post_Code__c, State__c, Type__c, 
                Key_UID__c, Is_Primary__c, Primary_set_by__c, Source__c, Callista_rollup_rank__c, 
                Start_date__c, Channel__c, CreatedDate
            FROM Address__c 
            WHERE Contact__c IN :this.contactIds
            ORDER BY Start_date__c DESC, Channel__c NULLS LAST
        ];
    }

    /**
    * @description select Contact Point Affiliation records related to the contact
    * @author Nick Guia | 11-07-2023 
    * @return List<Contact_Point_Affiliation__c>
    **/
    public List<Contact_Point_Affiliation__c> selectCPAs() {
        return [
            SELECT Id, Contact__c, Composite_key__c, Affiliation__c, Phone__c, Email__c, Address__c, Type__c
            FROM Contact_Point_Affiliation__c 
            WHERE Contact__c IN :this.contactIds
            AND Type__c IN ('Phone','Email','Address')
        ];
    }

    /**
    * @description used by queries that need to be "grouped by" to return a map of parent ID => List
    * @author Nick Guia | 04-08-2023 
    * @param String parentIdField 
    * @param List<SObject> recordList 
    * @return Map<Id, List<SObject>> 
    **/
    @TestVisible
    private Map<Id, List<SObject>> groupRecordsBy(String parentIdField, List<SObject> recordList) {
        Map<Id, List<SObject>> recordByParentIdField = new Map<Id, List<SObject>>();

        for(SObject rec : recordList) {
            Id parentId = (Id) rec.get(parentIdField); // force an 18 digit ID
            List<SObject> iList = recordByParentIdField.get(parentId);
            if(iList == null) {
                iList = new List<SObject>();
            }
            iList.add(rec);
            recordByParentIdField.put(parentId, iList);
        }
        return recordByParentIdField;
    }
}