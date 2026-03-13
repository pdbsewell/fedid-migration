/**
* @author          Ajitabh
* @description     Batch Class for Alumni Portal User onboarding
* @revision        Steffi Narang upsate on 18-03-21 - PENGAGE-1710
* @revision        Steffi   update on 2-06-2021 --    PENGAGE-1867
* @revision        ARivera     PENGAGE-2212     Update the Portal Onboarding process for MFA
*/
global class BatchAlumniPortalOnboarding implements Database.Batchable < SObject > {
    
    // reference data
    private static final Profile comProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].get(0);
    private static final PermissionSet alumniPermissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Alumni_Portal_Permission_Set' LIMIT 1].get(0);
    private static final PermissionSet mfaPermissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Experience_Custom_MFA' LIMIT 1].get(0);

    // permission set assignments (for existing users)
    List<PermissionSetAssignment> existingUserPermSetList = new List<PermissionSetAssignment>();     

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //get all the CampaignMember created a day days ago
        Date backDate = Date.today().addDays(-1);
        Id alumniWelcomeCampaignId = Alumni_Welcome_Campaign__c.getOrgDefaults().Id__c;
        String query;
        if(Test.isRunningTest()){
            query = 'SELECT Id,CreatedDate,ContactId FROM CampaignMember where CampaignId =: alumniWelcomeCampaignId';
        }else{
            query = 'SELECT Id,CreatedDate,ContactId FROM CampaignMember where DAY_ONLY(CreatedDate) =: backDate  and CampaignId =: alumniWelcomeCampaignId';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List < CampaignMember > scope) {
        try{
            Set < Id > conIds = new Set < Id > ();
            Set < Id > userIds = new Set < Id > ();
            Map < Id, User > conUserMap = new Map < Id, User > ();
            List < User > newUserList = new List < User > ();
            List <User> updateUserList = new List <User>();
            Map < Id, PermissionSetAssignment > userPSAMap = new Map < Id, PermissionSetAssignment > ();
            Map < Id, PermissionSetAssignment > mfaUserPSAMap = new Map < Id, PermissionSetAssignment > ();
            for (CampaignMember members: scope) {
                conIds.add(members.ContactId);
            }
            // get Contact and corresponding User
            for (User users: [SELECT Id, ContactId, Name, Email,Messaging_Opt_In__c FROM User WHERE ContactId IN: conIds]) {
                conUserMap.put(users.ContactId, users);
                userIds.add(users.Id);
            }
            
            //get permission set assignment for Alumni Portal permission set for existing user
            for (PermissionSetAssignment psa: [SELECT Id, PermissionSet.Id, PermissionSet.Name, AssigneeId
                                               FROM PermissionSetAssignment WHERE AssigneeId
                                               IN: userIds AND PermissionSet.Name = 'Alumni_Portal_Permission_Set'])
            {
                userPSAMap.put(psa.AssigneeId, psa);
            }

            //get permission set assignment for MFA Experience permission set for existing user
            for (PermissionSetAssignment psa: [SELECT Id, PermissionSet.Id, PermissionSet.Name, AssigneeId
                                                FROM PermissionSetAssignment
                                                WHERE AssigneeId IN: userIds
                                                AND PermissionSet.Name = 'Experience_Custom_MFA'])
            {
                mfaUserPSAMap.put(psa.AssigneeId, psa);
            }

            Integer i=0 ;
            for (Contact con: [SELECT Id, Name, FirstName, LastName, Email, Personal_Email__c FROM Contact WHERE Id IN :conIds]) {
                 // user already exists
                if (conUserMap.containsKey(con.Id)) {
                    User conUser = conUserMap.get(con.Id);
                    //Permission set already exits...
                    if (userPSAMap.containsKey(conUser.Id)) {
                        //nothing to do.
                    }else{
                        // create a permission set instead
                        PermissionSetAssignment psa = new PermissionSetAssignment();
                        psa.PermissionSetId = alumniPermissionSet.Id;
                        psa.AssigneeId = conUserMap.get(con.Id).Id;
                        existingUserPermSetList.add(psa);
                    }

                    if(!mfaUserPSAMap.containsKey(conUser.Id)){
                        // create a permission set instead
                        PermissionSetAssignment mfaPSA = new PermissionSetAssignment();
                        mfaPSA.PermissionSetId = mfaPermissionSet.Id;
                        mfaPSA.AssigneeId = conUser.Id;
                        existingUserPermSetList.add(mfaPSA);
                    }

                    // Opt in already exists
                    if (conUser.Messaging_Opt_In__c == false){
                        conUser.Messaging_Opt_In__c = true;
                        updateUserList.add(conUser);
                    }
                } else {
                    // create new user instead
                    String alias = CommonUtilities.createAliasForUser(con.FirstName,con.LastName);
                    String nickname = CommonUtilities.createNicknameForUser(con.FirstName,con.LastName,i);
                    if(con.Personal_Email__c == null){
                        LogUtilityException.logExceptionMSG('User' ,'Error while inserting an alumni user for their Contact record (Id: '+con.Id+', Name: '+con.Name+').','The required field Personal_Email__c is missing.');
                    }else{
                        User newUser = new User();
                        newUser.LastName = con.LastName;
                        newUser.FirstName = con.FirstName;
                        newUser.Username = con.Personal_Email__c;
                        newUser.CommunityNickname =nickname+Datetime.now().getTime();
                        newUser.ContactId = con.Id;
                        newUser.Email = con.Personal_Email__c;
                        newUser.ProfileId = comProfile.Id;
                        newUser.EmailEncodingKey = 'UTF-8';
                        newUser.TimeZoneSidKey = 'Australia/Sydney';
                        newUser.LanguageLocaleKey = 'en_US';
                        newUser.LocaleSidKey = 'en_AU';
                        newUser.Alias = alias;
                        newUser.Messaging_Opt_In__c = true;
                        newUserList.add(newUser);
                    }
                }
                i++;
            }
            Map<String,String> errorMap = new Map<String,String>();  
            if (newUserList.size() > 0) {
                Database.SaveResult[] srList = Database.insert(newUserList, false);
                List<Id> successIds = new List<Id>();
                for (Integer j =0 ; j < newUserList.size(); j++){
                        if (srList.get(j).isSuccess()){ 
                            successIds.add(srList[j].getId());
                             // after successfully user creation.
                            PermissionSetAssignment psa = new PermissionSetAssignment();
                            psa.PermissionSetId = alumniPermissionSet.Id;
                            psa.AssigneeId = newUserList[j].Id;
                            existingUserPermSetList.add(psa);

                            // create a MFA permission set assignment fot new users
                            PermissionSetAssignment mfaPSA = new PermissionSetAssignment();
                            mfaPSA.PermissionSetId = mfaPermissionSet.Id;
                            mfaPSA.AssigneeId = newUserList[j].Id;
                            existingUserPermSetList.add(mfaPSA);

                        }else if(!srList.get(j).isSuccess()){
                            Database.Error errors =  srList.get(j).getErrors().get(0);
                            if(errors.getMessage().contains('Duplicate Username')){
                        		LogUtilityException.addLogEvent('User' ,'UserName already exists while creating a user with ContactId :' + newUserList[j].ContactId,'Contact Personal_Email__c may be invalid or duplicate','Error');
                            }else{
                            	LogUtilityException.addLogEvent('User','ContactId :' + newUserList[j].ContactId, errors.getMessage(),'Error');
                            }
						}
                }
                LogUtilityException.publishAll();

            }
            //insert permission set when there is existing user..
            if (existingUserPermSetList.size() > 0) {
                Database.SaveResult[] srList = Database.insert(existingUserPermSetList, false);
                for (Database.SaveResult sr: srList) {
                    if (sr.isSuccess()) {
                        
                    }else {
                        // Operation failed, so get all errors                
                        for (Database.Error err: sr.getErrors()) {
                            System.debug('The following error has occurred.'+err.getMessage());
                        }
                    }
                }
            }
            // update users..
            if (updateUserList.size() > 0) {
                Database.SaveResult[] srList = Database.update(updateUserList, false);
                for (Database.SaveResult sr: srList) {
                    if (!sr.isSuccess()) {
                        // Operation failed, so get all errors                
                        for (Database.Error err: sr.getErrors()) {
                            System.debug('The following error has occurred.'+err.getMessage());
                        }
                    }
                }
            }
            
        } catch(Exception err) {
            LogUtilityException.logException('User',err.getMessage(),err,'BatchAlumniPortalOnboarding.execute()','Error');
        }
    }
    
    global void finish(Database.BatchableContext BC) {   
        BatchReferenceAccountPopulate b = new BatchReferenceAccountPopulate();
        Database.executeBatch(b, 200);    
        
    }
}