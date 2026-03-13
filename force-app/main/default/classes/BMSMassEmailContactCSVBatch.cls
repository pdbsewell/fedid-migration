/*******************************************************************************
* @author       Ryan Wilson
* @date         10.Jan.2017         
* @description  Batch class that adds campaign members to the campaign while parsing CSV
* @revision     
*******************************************************************************/
global class BMSMassEmailContactCSVBatch implements Database.Batchable<String>, Database.Stateful {
	
	private String campaignId;
	private String attachmentId;
	global final blob contentFile;
	private Boolean isPersonId;
	private List<String> fieldHeaderList;
	public Map<String, CampaignMember> alreadyInsertedCMMap {get;set;}
	public List<String> invalidContactEmails;

	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         10.Jan.2017         
	* @description  constructor
	* @revision     
	*******************************************************************************/
	global BMSMassEmailContactCSVBatch() {
		
	}
	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         10.Jan.2017         
	* @description  constructor called by Bulk Messaging
	* @revision     
	*******************************************************************************/
	global BMSMassEmailContactCSVBatch(String attachmentRecordId, String campaignRecordId, Boolean isThisAListOfPersonIds) {
		Attachment attachmentRecord = [SELECT Id, Body FROM Attachment WHERE Id =: attachmentRecordId];
		campaignId = campaignRecordId;
		contentFile = attachmentRecord.Body;
		isPersonId = isThisAListOfPersonIds;
		if (fieldHeaderList == null){
		    fieldHeaderList = new List<String>();
		}
		if (alreadyInsertedCMMap == null) {
			alreadyInsertedCMMap = new Map<String, CampaignMember>();
		}

		if (invalidContactEmails == null) {
			invalidContactEmails = new List<String>();
		}
	}
	
	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         10.Jan.2017         
	* @description  Batch start method to call in the CSV Iterator
	* @revision     
	*******************************************************************************/
	global Iterable<String> start(Database.batchableContext batchableContext){
	    try {
	    	String csvfile = contentFile.toString();
	    	return new CSVIterator(csvfile, '\r\n');
    	} catch (Exception ex) {
    		//add exception
    		if (ex.getMessage() == 'BLOB is not a valid UTF-8 string') {
    			//use the HTTPRequest functionality to get the body
    			HttpRequest tmp = new HttpRequest();
				tmp.setBodyAsBlob(contentFile);
				String value = tmp.getBody(); //this seem to be a valid utf-8 string
				system.debug('@@@Blob to String' + value);
				return new CSVIterator(value, '\r\n');
    		} else {
    			ExLog.add('BMS Batch Class', ' BMSMassEmailContactCSVBatch', 'start', ex, campaignId);
				return new List<String>();
			}
    	}
	}

	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         10.Jan.2017         
	* @description  Batch Execute
	* @revision     ACUSTODIO, 8.Mar.2017 - added try catch block
	*******************************************************************************/
   	global void execute(Database.BatchableContext BC, List<String> scope) {
		Database.SaveResult[] srList;
		try {
	       	Map<String, Contact> contactOnCSVMap = new Map<String,Contact>();
	       	List<List<String>> csvLines = retrieveCSVLines(scope);
	       	List<Contact> contactSearchList = new List<Contact>();

	       	if (isPersonId) {
	       		Set<String> personIds = buildCampaignMembersUsingPersonId(csvLines);
	       		//query on contacts using the person Ids on the CSV
	       		contactSearchList = new List<Contact>([SELECT Id FROM Contact WHERE Person_Id_unique__c IN: personIds]);
                System.debug('###_personIds: ' + personIds.size());
	       	} else {
	       		contactOnCSVMap = buildCampaignMembersUsingEmail(csvLines);
	       		//retrieve the contacts listed on CSV
	       		//this also inserts contacts that are not found in CRM
	       		contactSearchList = retrieveOrInsertContactsListedInCSV(contactOnCSVMap);
	       	}

			List<CampaignMember> campaignMemberToInsertList = createCampaignMembersFromContactList(contactSearchList);
			
			if (!campaignMemberToInsertList.isEmpty()) {
				//insert campaignMemberToInsertList;
				srList = Database.insert(campaignMemberToInsertList, false);
			}
		} catch (Exception ex) {
			// Iterate through each returned result
			Integer failedInsert = 0;
			if (srList != null) {
				for (Database.SaveResult sr : srList) {
				    if (!sr.isSuccess()) {
				        failedInsert++;
				    }
				}
			}
			//add exception
			ExLog.add('BMS Batch Class. Failed Inserts: '+failedInsert, ' BMSMassEmailContactCSVBatch', 'execute', ex, campaignId);
		}
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         22.Mar.2017        
	* @description  updates the campaign record
	* @revision     
	*******************************************************************************/
	private List<List<String>> retrieveCSVLines(List<String> scope) {
		List<List<String>> csvLines = new List<List<String>>();
		String csvFile = '';
		
		for(String row : scope) {
        	csvFile += row + '\r\n';
       	}

       	if (csvFile != '') {
       		csvLines = CSVReader.readIETFRFC4180CSVFile(csvFile);
       	}

       	return csvLines;
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         22.Mar.2017        
	* @description  retrieves contact from the CSV file using the defined field headers
	* @revision     
	*******************************************************************************/
	private Map<String, Contact> buildCampaignMembersUsingEmail(List<List<String>> csvLines) {
		//Dynamic fields - users can put any fields they like
       	//note: email and last name is required
       	List<Contact> contactCSVList = new List<Contact>();
   		Map<String, Contact> contactOnCSVMap = new Map<String,Contact>();
		if(csvLines != null && !csvLines.isEmpty()) {
			//Note: make sure the field is in Contact object
			for(Integer i=0; i<csvLines.size(); i++){
				List<String> csvLine = csvLines[i];
				Contact contactRecord = new Contact();
				if (!fieldHeaderList.isEmpty()) {
					for (Integer j=0; j<csvLine.size(); j++) {
						if (csvLine[j] != '' && csvLine[j] != null) {
							contactRecord.put(fieldHeaderList[j], csvLine[j]);
						}
					}
					contactCSVList.add(contactRecord);
				} else {
					fieldHeaderList.addAll(csvLine);
				}
			}
			for (Contact csvContactRecord: contactCSVList) {
				contactOnCSVMap.put(csvContactRecord.Email.toLowerCase(), csvContactRecord);
			}
		}
		return contactOnCSVMap;
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         22.Mar.2017        
	* @description  retrieves contact from the CSV file using person Id
	* @revision     ACUSTODIO, 23.Mar.2017 - Updated the logic build the person Id
						String set
	*******************************************************************************/
	private Set<String> buildCampaignMembersUsingPersonId(List<List<String>> csvLines) {
		Set<String> personIds = new Set<String>();
		
		if(csvLines != null && !csvLines.isEmpty()) {
			//known bug sent to salesforce - CSV cannot be split sometimes
			if (csvLines.size() == 1) {
				List<String> csvLine = csvLines[0];
				List<String> csvLineIteratable = csvLine[0].normalizeSpace().split(' ');

				for(String stringValue: csvLineIteratable) {
					if(!String.isEmpty(stringValue)) {
                        if(stringValue != 'PERSON_ID') {
                        	personIds.add(stringValue);
                        }
                    }
				}

			} else {
				for(Integer i=0; i<csvLines.size(); i++) {
					List<String> csvLine = csvLines[i];
					for(String stringValue: csvLine) {
						if(!String.isEmpty(stringValue)) {
	                        if(stringValue != 'PERSON_ID') {
	                        	personIds.add(stringValue);
	                        }
	                    }
					}
				}
			}
		}
		
		return personIds;
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         22.Mar.2017        
	* @description  find the contacts listed on the CSV
	* @revision     
	*******************************************************************************/
	private List<Contact> retrieveOrInsertContactsListedInCSV(Map<String, Contact> contactOnCSVMap) {
		
		List<Contact> contactSearchList = new List<Contact>();
		List<Contact> contactToInsertList = new List<Contact>();
		Map<String, Contact> contactFoundMap = new Map<String,Contact>();
   		
   		for (Contact contactRecord: [	SELECT	Id,FirstName, LastName, Email, Monash_Email_Address__c
   										FROM 	Contact 
   										WHERE 	Email IN: contactOnCSVMap.keySet() 
											OR 	Monash_Email_Address__c IN: contactOnCSVMap.keySet() ]) {
   			Boolean addContactToList = false;
   			//get the list of contacts already in org and put it on the map
   			if (contactRecord.Email != null) {
   			    if (contactOnCSVMap.containsKey(contactRecord.Email.toLowerCase())) {
       				contactFoundMap.put(contactRecord.Email.toLowerCase(), contactRecord);
       				addContactToList = true;
       			} 
   			}
   			
   			if (contactRecord.Monash_Email_Address__c != null) {
   			    if (contactOnCSVMap.containsKey(contactRecord.Monash_Email_Address__c.toLowerCase())) {
       				contactFoundMap.put(contactRecord.Monash_Email_Address__c.toLowerCase(), contactRecord);
       				addContactToList = true;
   			    }
   			}
   			if (addContactToList) {
   			    contactSearchList.add(contactRecord);
   			}
   		}
   		
   		//insert the new contacts found
   		for (String newContactEmails: contactOnCSVMap.keySet()) {
   			//if the email is not found on the map of existing emails, insert it as a new record
   			if (!contactFoundMap.containsKey(newContactEmails)) {
   				contactToInsertList.add(contactOnCSVMap.get(newContactEmails));
   			}
   		}
   		if (!contactToInsertList.isEmpty()) {
   			List<Contact> validatedContactList = new List<Contact>();
   			for (Contact contactRecord: contactToInsertList) {
   				if (CommonUtilities.validateEmail(contactRecord.Email)) {
   					validatedContactList.add(contactRecord);
   				} else {
   					invalidContactEmails.add(contactRecord.Email);
   				}
   			}

   			//updated the code to insert only when email is valid.
   		    //insert contactToInsertList;
   		    insert validatedContactList;

   			contactSearchList.addAll(validatedContactList);
   		}

   		return contactSearchList;
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         22.Mar.2017        
	* @description  builds the contacts to be inserted as a campaign member on the 
						campaign
	* @revision     
	*******************************************************************************/
	private List<CampaignMember> createCampaignMembersFromContactList(List<Contact> contactSearchList) {
		List<CampaignMember> campaignMemberToInsertList = new List<CampaignMember>();
		if(!contactSearchList.isEmpty()){
			for (Contact contactRecord: contactSearchList) {
				CampaignMember campaignMemberRec = new CampaignMember();
				campaignMemberRec.ContactId = contactRecord.Id;
				campaignMemberRec.Status = 'Pending Approval';
				campaignMemberRec.CampaignId = campaignId;
				if (!alreadyInsertedCMMap.containsKey(contactRecord.Id)) {
					campaignMemberToInsertList.add(campaignMemberRec);
					alreadyInsertedCMMap.put(contactRecord.Id, campaignMemberRec);
				}
			}
		}

		return campaignMemberToInsertList;
	}

	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         10.Jan.2017         
	* @description  Batch finish - update campaign status 
	* @revision     
	*******************************************************************************/
	global void finish(Database.BatchableContext BC) {
		List<Campaign> campaignRecord = [SELECT	Id, Status
											FROM 	Campaign
											WHERE 	Id =: campaignId];
		
		if (!campaignRecord.isEmpty()) {
			campaignRecord[0].Batch_Finished__c = true;
			campaignRecord[0].Status = 'On Hold';
			update campaignRecord;	
		}		

		if (!invalidContactEmails.isEmpty()) {
			//add exception - collect invalid emails
			ExLog.add('Batch Class', ' BMSMassEmailContactCSVBatch', 'retrieveOrInsertContactsListedInCSV', 'Number of Invalid Emails: '+invalidContactEmails.size());
		}					
	}
}