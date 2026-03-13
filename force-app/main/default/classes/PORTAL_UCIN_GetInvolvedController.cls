global without sharing class PORTAL_UCIN_GetInvolvedController {
	

    
    @AuraEnabled
    global static list<Volunteer_Job__c> SERVER_getVolunteerJobs(String scope,
                                                                 String sharing,
                                                                 String relevance,
                                                                 String maxItems) {
                                                              
		Integer maxItemsInt = Integer.valueOf(maxItems);                                                              
        Map<String, List<String>> volPrefMap;

        Id userId = UserInfo.getUserId();
		User u = [select id, contactId, Recommend_Type_1__c from User where id = : userId];
		id getContactId = u.contactId;
        volPrefMap = getPreferenceMap(getContactId);
		system.debug('getContactId: ' + getContactId);
                                                              
        system.debug('sharing: ' + sharing);
        DateTime dtNow = system.Now().addHours(-1);
        Date today = Date.today();

        string volunteerQuery = 'select Id, Name, Description__c, Location_Information__c, Number_of_Shifts__c, Skills_Needed__c, '
        + 'Start_Date__c, End_Date__c, Areas_of_Interest__c, Volunteer_Type__c, '
        + 'Location_Street__c, Location_City__c, Country__c, Location__c, Location_Zip_Postal_Code__c, Header_Image__c, Header_Content__c, '
        + 'Footer_Content__c, Title_URL__c, Header_Image_from_URL__c, Recommend_Type_1__c, Recommend_Type_2__c, Recommend_Type_3__c ';

        if(sharing == 'Me') {
            volunteerQuery += ', (Select Id, Name, User__c, Contact__c, Status__c, Shift_Start_Date_Time__c, Planned_Start_Date_Time__c, '
            + 'Start_Date__c, End_Date__c, Hours_Worked__c, Volunteer_Shift__r.Description__c '
            + 'From Volunteer_Hours__r Where Contact__c = :getContactId AND Status__c in '
            + '(\'Web Sign Up\', \'In Progress\', \'Completed\') LIMIT 100) ';
        } else {
            volunteerQuery += ', (Select Id, Status__c '
            + 'From Volunteer_Hours__r Where Contact__c = :getContactId AND Status__c in '
            + '(\'Web Sign Up\', \'In Progress\', \'Completed\') LIMIT 100) ';
        }
        volunteerQuery +=  'from Volunteer_Job__c ';
        
        if (sharing != 'Me') {
            volunteerQuery += 'where Campaign__r.IsActive = true and Externally_Visible__c = true AND (End_Date__c >= :today OR End_Date__c = null) AND Inactive__c = false AND '
            + 'ID NOT IN (SELECT Volunteer_Job__c FROM Volunteer_Hours__c WHERE Contact__c = :getContactId)  ORDER BY End_Date__c ASC LIMIT 999';
        } else {
            volunteerQuery += 'where ID IN (SELECT Volunteer_Job__c FROM Volunteer_Hours__c WHERE Contact__c = :getContactId AND '
            + 'Status__c in (\'Web Sign Up\', \'In Progress\', \'Completed\')) ORDER BY End_Date__c ASC LIMIT 999';
        }

		if(sharing == 'Me') {
            List<Volunteer_Job__c> beforeToday = new List<Volunteer_Job__c>();
            List<Volunteer_Job__c> afterToday = new List<Volunteer_Job__c>();
            Boolean isBefore = true;
            for(Volunteer_Job__c volJob : database.query(volunteerQuery)) {
                if(isBefore && (volJob.End_Date__c < today)) {
                    beforeToday.add(volJob);
                } else {
                    isBefore = false;
                    afterToday.add(volJob);
                }
            }  
            List<Volunteer_Job__c> tempList = organizeVolunteerJobs(afterToday, volPrefMap);
            tempList.addAll(organizeVolunteerJobs(beforeToday, volPrefMap));
            return tempList;
        } else {
            return organizeVolunteerJobs(database.query(volunteerQuery), volPrefMap);
        }
    }

    
    
    @AuraEnabled
    global static Contact SERVER_getContactInfo() {
    	
    	// Can't call PORTAL_UCIN_CommunityUtils.getContactInfoFromUser and put the Volunteers
    	// fields in there.  Otherwise, package would include the Volunteer fields and will
    	// conflict with installation of Volunteers for Salesforce.
        Id userId = UserInfo.getUserId();
        
        User usr = [SELECT Id,
                    	   ContactId,
                           AccountId,
                    	   FirstName,
                    	   LastName,
                    	   Recommend_Type_1__c,
                    	   Recommend_Type_2__c,
                    	   Recommend_Type_3__c
                    FROM User
                    WHERE Id = :userId];  
        
        Id contactId = usr.ContactId;
        
        Contact cont = null;
        
        if (contactId != null) {        
        	cont = [SELECT Id,
                    	   Name,
                    	   FirstName,
                    	   LastName,
                           Email,
                           Phone,
                           HomePhone,
                           MobilePhone,
                           Volunteer_Organization__c,
                           Volunteer_Skills__c,
                           Volunteer_Availability__c
                    FROM Contact
                    WHERE Id = :contactId];
            
         	System.debug('Util cont: ' + cont);
        }     
        
        return cont;
    }	    

    @AuraEnabled
    public static List<Volunteer_Job__c> SERVER_searchVolunteerJob(String searchTerms){
        List<Volunteer_Job__c> listVolunteerJobs = new List<Volunteer_Job__c>();
        List<Volunteer_Job__c> returnList = new List<Volunteer_Job__c>();
        Id contactId;
        Date today = Date.today();
        Set<String> aoiSetToQuery = new Set<String>();
        Set<String> nameSetToQuery = new Set<String>();
        Contact cont = SERVER_getContactInfo();
        if(cont != null) {
            contactId = cont.Id;
        }
        
        Map<String, List<String>> volPrefMap = getPreferenceMap(contactId);
        searchTerms = searchTerms.replaceAll(',', '');
        searchTerms = String.escapeSingleQuotes(searchTerms);
        searchTerms = searchTerms.toLowerCase();
        String[] splitTerms = searchTerms.split(' ');

        List<Schema.PicklistEntry> pleList = Contact.Volunteer_Areas_of_Interest__c.getDescribe().getPicklistValues();

        for(String searchTerm : splitTerms) {
            for(Schema.PicklistEntry picklistEntry : pleList) {
                if(picklistEntry.getLabel().containsIgnoreCase(searchTerm)) {
                    aoiSetToQuery.add('\'' + picklistEntry.getLabel() + '\'');
                }
            }
            nameSetToQuery.add('%' + searchTerm + '%');
        }

        String whereClause = 'Campaign__r.IsActive = true AND Externally_Visible__c = true  AND (End_Date__c >= :today OR End_Date__c = null) AND Inactive__c = false AND  ';
        whereClause += '(Name LIKE :nameSetToQuery ';
        if(!aoiSetToQuery.isEmpty()){
            whereClause += ' OR Areas_of_Interest__c includes (' + String.join(new List<String>(aoiSetToQuery), ',') + ')';
        }
        whereClause += ')';
        
        String volunteerListQuery = 'SELECT Id, Name, Description__c, Skills_Needed__c, Start_Date__c, End_Date__c, Areas_of_Interest__c, '
                                    +'Location_Street__c, Location_City__c, Country__c, Header_Image_from_URL__c, Volunteer_Type__c '
                                    + 'FROM Volunteer_Job__c WHERE '
                                    + whereClause
                                    + ' ORDER BY End_Date__c ASC LIMIT 999';


        listVolunteerJobs = Database.query(volunteerListQuery);

        return organizeVolunteerJobs(listVolunteerJobs, volPrefMap);
    }

    @AuraEnabled
    public static void SERVER_expressInterest(Id jobId){
        System.debug('Job: '+jobId);
        List<Volunteer_Job__c> volJob = [SELECT Id, Start_Date__c FROM Volunteer_Job__c where Id = :jobId LIMIT 1];
        List<Volunteer_Job__c> voJobs = [SELECT Id, Name FROM Volunteer_Job__c  LIMIT 1];
        Contact cont = SERVER_getContactInfo();
        System.debug('voJobs: '+voJobs);
        System.debug('Express Interest Contact: ' + cont);
        if(cont != null && volJob.size() > 0) {
             Volunteer_Hours__c hours = new Volunteer_Hours__c(Contact__c = cont.Id, Volunteer_Job__c = jobId, Status__c = 'Web Sign Up', 
                                                                Start_Date__c = volJob[0].Start_Date__c, Number_of_Volunteers__c = 1);
            insert hours;
        }
    }

    private static List<Volunteer_Job__c> organizeVolunteerJobs(List<Volunteer_Job__c> jobs, Map<String, List<String>> volPrefMap) {
        //Sorts by Role then Skills and then AOI within those
        List<Volunteer_Job__c> displayFirstJobList = new List<Volunteer_Job__c>();
        List<Volunteer_Job__c> displayLastJobList = new List<Volunteer_Job__c>();
        List<Volunteer_Job__c> returnList = new List<Volunteer_Job__c>();
        List<String> areasOfInterest;
        List<String> volunteerRoles;
        List<String> volunteerSkills;
        

        for(Volunteer_Job__c job : jobs) {
            job.Description__c = PORTAL_UCIN_Utils.replaceSelectedText(job.Description__c);
        }

        if(volPrefMap == null) {
            return jobs;
        }
        if(volPrefMap.containsKey('areasOfInterest')) {
            areasOfInterest = volPrefMap.get('areasOfInterest');
        }
        if(volPrefMap.containsKey('volunteerRoles')) {
            volunteerRoles = volPrefMap.get('volunteerRoles');
        }
        if(volPrefMap.containsKey('volunteerSkills')) {
            volunteerSkills = volPrefMap.get('volunteerSkills');
        }

        if(volunteerRoles != null) {
            for(Volunteer_Job__c job : jobs) {
                Boolean isRoleFound = false;
                for(String role : volunteerRoles) {
                    if(job.Volunteer_Type__c != null && job.Volunteer_Type__c.containsIgnoreCase(role)){
                        displayFirstJobList.add(job);
                        isRoleFound = true;
                        break;
                    }
                }
                if(!isRoleFound) {
                    displayLastJobList.add(job);
                }
            }
        }
        
        if(volunteerSkills != null) {
            List<Volunteer_Job__c> jobsToSort = jobs;
            List<Volunteer_Job__c> noSkillFoundList = new List<Volunteer_Job__c>();

            if((displayLastJobList.size() > 0) || (displayFirstJobList.size() > 0)) {
                jobsToSort = displayLastJobList;
            }
            for(Volunteer_Job__c job : jobsToSort) {
                Boolean isSkillFound = false;
                for(String skill : volunteerSkills) {
                    if(job.Skills_Needed__c != null && job.Skills_Needed__c.containsIgnoreCase(skill)){
                        displayFirstJobList.add(job);
                        isSkillFound = true;
                        break;
                    }
                }
                if(!isSkillFound) {
                    noSkillFoundList.add(job);
                }
            }
            displayLastJobList = noSkillFoundList; 
        }

        displayFirstJobList = organizeByAreaOfInterest(displayFirstJobList, areasOfInterest);
        displayLastJobList = organizeByAreaOfInterest(displayLastJobList, areasOfInterest);
        returnList.addAll(displayFirstJobList);
        returnList.addAll(displayLastJobList);

        if(returnList.size() < 1) {
            returnList.addAll(jobs);
        }

        return returnList;
    }

    private static List<Volunteer_Job__c> organizeByAreaOfInterest(List<Volunteer_Job__c> jobs, List<String> areasOfInterest) {
        Map<String, List<Volunteer_Job__c>> areaOfInterestToJobListMap = new Map<String, List<Volunteer_Job__c>>();
        List<Volunteer_Job__c> noAreaOfInterestJobs = new List<Volunteer_Job__c>();
        List<Volunteer_Job__c> returnList = new List<Volunteer_Job__c>();

        if(areasOfInterest != null) {
            for(String area : areasOfInterest) {
                areaOfInterestToJobListMap.put(area, new List<Volunteer_Job__c>());
            }     

            for(Volunteer_Job__c job : jobs) {
                Boolean isAreaOfInterestFound = false;
                for(String area : areasOfInterest) {
                    if(job.Areas_of_Interest__c != null && job.Areas_of_Interest__c.containsIgnoreCase(area)){
                        areaOfInterestToJobListMap.get(area).add(job);
                        isAreaOfInterestFound = true;
                        break;
                    }
                }
                if(!isAreaOfInterestFound) {
                    noAreaOfInterestJobs.add(job);
                }
            }

            for(String area : areasOfInterest) {
                returnList.addAll(areaOfInterestToJobListMap.get(area));
            }
            returnList.addAll(noAreaOfInterestJobs);
            return returnList;
        } else {
            return jobs;
        }
    }

    private static Map<String, List<String>> getPreferenceMap(Id contactId) {
        List<String> areasOfInterest;
        List<String> volunteerSkills;
        List<String> volunteerRoles;
        Map<String, List<String>> returnMap = new Map<String, List<String>>();
        if(contactId != null) {
            Contact cont = [SELECT Id, Volunteer_Areas_of_Interest__c, Volunteer_Roles__c, Volunteer_Skills__c  FROM Contact WHERE Id = :contactId];
            if(cont.Volunteer_Areas_of_Interest__c != null) {
                areasOfInterest = cont.Volunteer_Areas_of_Interest__c.split(';');
                returnMap.put('areasOfInterest', areasOfInterest);
            }
            if(cont.Volunteer_Skills__c != null) {
                volunteerSkills = cont.Volunteer_Skills__c.split(';');
                returnMap.put('volunteerSkills', volunteerSkills);
            }
            if(cont.Volunteer_Roles__c != null) {
                volunteerRoles = cont.Volunteer_Roles__c.split(';');
                returnMap.put('volunteerRoles', volunteerRoles);
            }
        }
        return returnMap;

    }
}