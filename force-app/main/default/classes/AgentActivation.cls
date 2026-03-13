/**
 * @description     Agent Activation automation code - to enable agencies and create/update agents
 * @author          Smen
 * @date            27/11/2023
 * @revision
 */
public with sharing class AgentActivation {
    private static Id fileId = null;
    static Map < String, Account > accOrgUnitMap = new Map < String, Account > ();
    static Map < String, List < Contact >> orgUnitContactMap = new Map < String, List < Contact >> ();
    //static Id rtid = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency_Contact').getRecordTypeId();
    static String rtid = CommonServices.recordTypeId('Contact', 'Agency_Contact');
    static List<Contact> counsellorRoleUpdateList = new List<Contact>();
    static List<Contact> bmRoleUpdateList = new List<Contact>();
    static List<Contact> insertContactList = new List<Contact>();


    /************
    * @author:		smen
    * @date:		27/11/2023
    * @description:	FUTURE method to process csv row by row  

    *********/
    @future
    public static void run(Id fileId) {
        fileId = fileId;

        // Query the ContentVersion object to get the file contents
        ContentVersion fileVersion = [SELECT Id, VersionData FROM ContentVersion WHERE Id =: fileId];

        // Get the file contents as a blob
        Blob fileBody = fileVersion.VersionData;

        // Convert the blob to a string
        String csvFileBody = fileBody.toString();
        // Split the CSV file into rows
        List < String > csvRows = csvFileBody.split('\n');
        String row = '';
        List < String > orgUnits = new List < String > ();
        String orgUnit = '';
        String bmFirstname = '';
        String bmLastName = '';
        String email = '';
        String appendedEmail = '';
      
        try {
            for (Integer i = 1; i < csvRows.size(); i++) {
                // Split the current row into columns
                List < String > csvColumns = csvRows[i].split(',');
                for (String col: csvColumns) {
                    orgUnit = csvColumns[0].trim();
                }
                orgUnits.add(orgUnit.toUpperCase());
            }
            System.debug('orgUnits==' + orgUnits);
            Map < Id, Account > accMap = new Map < Id, Account > ([select id, Callista_Org_Unit_Code__c from Account where Callista_Org_Unit_Code__c =: orgUnits]);
            List < Account > accList = new List < Account > ();
            for (Account acc: accMap.values()) {
                accOrgUnitMap.put(acc.Callista_Org_Unit_Code__c.toUpperCase(), acc);
                acc.isPartner = true;
                acc.Agent_Portal_Access_Is_Enabled__c = true;
                accList.add(acc);
            }
            System.debug('accOrgUnitMap=='+accOrgUnitMap);
            TriggerCommon.disableTrigger('Account');

            update accList;

            List < contact > conList = new List < Contact > ([SELECT Id, Account.Callista_Org_Unit_Code__c, Agency_Contact_Roles__c from contact where
                Account.Callista_Org_Unit_Code__c =: orgUnits
                and RecordType.DeveloperName = 'Agency_Contact'
                and role_account_flag__c != true and Agency_Contact_Roles__c includes('Branch Manager')
            ]);
            for (Contact con: conList) {
                if (orgUnitContactMap.containsKey(con.Account.Callista_Org_Unit_Code__c.toUpperCase())) {
                    List < Contact > abc = orgUnitContactMap.get(con.Account.Callista_Org_Unit_Code__c.toUpperCase());
                    abc.add(con);
                    orgUnitContactMap.put(con.Account.Callista_Org_Unit_Code__c.toUpperCase(), abc);
                } else {
                    orgUnitContactMap.put(con.Account.Callista_Org_Unit_Code__c.toUpperCase(), new List < Contact > {
                        con
                    });
                }
            }
            System.debug('orgUnitContactMap=='+orgUnitContactMap);

            for (Integer i = 1; i < csvRows.size(); i++) {

                // Split the current row into columns
                List < String > csvColumns = csvRows[i].split(',');
                for (String col: csvColumns) {
                    orgUnit = csvColumns[0].trim();
                    bmFirstname = csvColumns[1].trim();
                    bmLastName = csvColumns[2].trim();
                    email = csvColumns[3].trim();
                }

                if (email.contains('+')) {
                    String firstSplit = email.substringBefore('+');
                    String after = email.substringAfter('@');
                    appendedEmail = firstSplit + '@' + after;
                }
                
                System.debug('accOrgUnitMap=='+accOrgUnitMap);

                if (!accOrgUnitMap.containsKey(orgUnit.toUpperCase())) {
                    ExLog.add('AgentActivation', 'N/A', 'AgentActivation', 'Agent ' + ' with orgunit code: ' + orgunit + ' does not exist ');

                } else {
                    createBranchManger(orgUnit, bmFirstname, bmLastName, email, appendedEmail, accList);
                }


            }
            update counsellorRoleUpdateList;
            update bmRoleUpdateList;
            insert insertContactList;
        } catch (Exception ex) {
            ExLog.add('AgentActivation', 'N/A', 'AgentActivation.run', 'Exception: ' + ex.getCause()+'::'+ex.getMessage());

        }

    }

    /************
    * @author:		smen
    * @date:		27/11/2023
    * @description:	Method to create/update branch manager

    *********/
    private static void createBranchManger(String orgUnit, String bmFirstname, String bmLastName, String email, String appendedEmail, List < Account > accList) {

       orgUnit = orgUnit.toUpperCase();
        if (orgUnitContactMap.get(orgUnit) != null && orgUnitContactMap.get(orgUnit).size() > 0) {
            List < Contact > conList = orgUnitContactMap.get(orgUnit);
            for (contact con1: conList) {
                if (con1.Agency_Contact_Roles__c != null)
                    con1.Agency_Contact_Roles__c = 'Counsellor';
            }
            TriggerCommon.disableTrigger('Contact');
            counsellorRoleUpdateList.addAll(conList);


        }


        List < Contact > conList2 = new List < Contact > ([select id, Agency_Contact_Roles__c from contact where RecordType.DeveloperName = 'Agency_Contact'
            and role_account_flag__c != true and AccountId =: accOrgUnitMap.get(orgUnit).Id and(email =: appendedEmail or email =: email) and FirstName =: bmFirstname and LastName =: bmLastName
        ]);
        System.debug('conList2=='+conList2+ '::'+ accOrgUnitMap.get(orgUnit));
        if (conList2.size() > 0) {
            conList2[0].Agency_Contact_Roles__c = 'Branch Manager;Counsellor;Delegated Admin;';
            conList2[0].email = email;
            bmRoleUpdateList.addAll(conList2);

            ExLog.add('AgentActivation', 'N/A', 'AgentActivation', 'Agent activation done for orgUnit updating the  contact with emailaddress:' + email + ' for OrgUnit code:' + orgUnit);
            return;
        }

        Contact con = new Contact(RecordTypeid = rtid,
            AccountId = accOrgUnitMap.get(orgUnit).Id,
            email = email,
            FirstName = bmFirstname,
            LastName = bmLastName,
            Agency_Contact_Roles__c = 'Branch Manager;Counsellor;Delegated Admin;'
        );
        insertContactList.add(con);
        
       
        ExLog.add('AgentActivation', 'N/A', 'AgentActivation', 'Agent activation done for orgUnit inserting a new contact with emailaddress:' + email + 'for OrgUnit code:' + orgUnit);
    }

}