/**
 * @author       Ajitabh
 * @date         22.Nov.2016
 * @description  Service class for Affiliation creation
 * @revision     22.Nov.2016    Ajitabh,  - Initial version
 *               17.Aug.2022   Inderpal      added row lock handling PENGAGE-2392
 */
public class AffiliationService {
     public static void createAffiliationforCDCExp(list<sObject> sobjectList, List<Affiliation__c> affliationList, Integer retryCount){
        if(retryCount == 0){
			Schema.SObjectType sObjectType = sobjectList.getSObjectType();
			Id recordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByName().get('Alumni').getRecordTypeId();
			id monashAccGlobalId= Global_Monash_Account__c.getOrgDefaults().id__c;
			
			affliationList = new List<Affiliation__c>();
			set<string>accIds = new set<string>();
			set<string>conIds = new set<string>();
			if(String.valueOf(sObjectType) =='Contact_Qualification__c'){
				List<Contact_Qualification__c> conQualList = (List<Contact_Qualification__c>) sobjectList;    	
				for(Contact_Qualification__c cq: conQualList){
					if(cq.Faculty__c ==null){
						accIds.add(monashAccGlobalId);                    
					}
					else{
						accIds.add(cq.Faculty__c); 
					}
					conIds.add(cq.Contact__c);
				}
			}  
			if(String.valueOf(sObjectType) =='Course_Attempt__c'){
				List<Course_Attempt__C> caList = (List<Course_Attempt__c>) sobjectList;    	
				for(Course_Attempt__c cq: caList){
					if(cq.Course__r.Faculty__c !=null){
						accIds.add(cq.Course__r.Faculty__c);
					}
					else{
						accIds.add(monashAccGlobalId); 
					}
					conIds.add(cq.Contact__c);
				}    
			}
			list<Affiliation__c> existingAff=[select id,Account__c,Contact__c,
											  Position_Level__c from Affiliation__c 
											  where Account__c IN:accIds and Contact__c IN: conIds ];
			Map<String,Affiliation__c> mapAff = new Map<String,Affiliation__c>();
			for(Affiliation__c eA : existingAff)
			{
				String key = eA.Account__c+'_'+eA.Contact__c;
				mapAff.put(key,eA);
			}
			for(sObject sobj: sobjectList){
				if(string.valueOf(sobj.getSObjectType())=='Contact_Qualification__c'){
					Contact_Qualification__c cq= (Contact_Qualification__c) sobj ;
					String key = cq.Faculty__c ==null ? monashAccGlobalId+'_'+cq.Contact__c : cq.Faculty__c+'_'+cq.Contact__c;
					if (!mapAff.containsKey(key)){
						Affiliation__c af = new Affiliation__c();
						af.Account__c = cq.Faculty__c !=null ? cq.Faculty__c : monashAccGlobalId;
						af.RecordTypeId=recordTypeId;
						af.Contact__c= cq.Contact__c;
						af.Position_Level__c='Alumni';
						af.Start_Date__c =system.today();
						affliationList.add(af); 
						af.Start_Date__c =cq.Date_Achieved__c !=null ? cq.Date_Achieved__c : system.today();
						mapAff.put(key,af);
					}
				}
				
				if(string.valueOf(sobj.getSObjectType())=='Course_Attempt__c'){
					Course_Attempt__c cq= (Course_Attempt__c) sobj ;
					String key = cq.Course__r.Faculty__c ==null ? monashAccGlobalId+'_'+cq.Contact__c  : cq.Course__r.Faculty__c+'_'+cq.Contact__c;
					if (!mapAff.containsKey(key)){
						Affiliation__c af = new Affiliation__c();
						af.RecordTypeId=recordTypeId;
						af.Account__c = cq.Course__r.Faculty__c !=null ? cq.Course__r.Faculty__c : monashAccGlobalId ;
						af.Contact__c= cq.Contact__c;
						af.Position_Level__c='Alumni No Degree';
						af.Start_Date__c =system.today();
						affliationList.add(af);  
						mapAff.put(key,af);
					}
				}
			}
		}
		try {
            Database.SaveResult[] insertResults = Database.insert(affliationList, false);

            Database.SaveResult aResult = null;
            List<Affiliation__c> retryAffliationList = new List<Affiliation__c>();
            for (Integer i=0; i<insertResults.size(); i++) {
                aResult = insertResults[i];
                if (!aResult.isSuccess()) {
                    for (Database.Error err : aResult.getErrors()) {
                        Switch on (err.getStatusCode()) {
                            when UNABLE_TO_LOCK_ROW {
                                if (retryCount < 3) {
                                    retryAffliationList.add(affliationList[i]);
                                } else {
                                    LogUtilityException.addLogEvent('createAffiliationforCDCExp','Affiliation', err, 'AffiliationsService.createAffiliationforCDCExp() [Retry Post Insert]');  
                                }
                            }
                            when else {
                                LogUtilityException.addLogEvent('createAffiliationforCDCExp','Affiliation', err, 'AffiliationsService.createAffiliationforCDCExp() [Retry Post Insert]');  
                            }
                        }
                    } 
                } 
            }

            if (retryAffliationList.size() > 0) {
                createAffiliationforCDCExp(null, retryAffliationList, retryCount++);
            }

        } catch(Exception exc) {
            LogUtilityException.addLogEvent('createAffiliationforCDCExp','Affiliation', exc, 'AffiliationsService.createAffiliationforCDCExp() [Retry Post Insert]');
        }
    }

   /**
    * @author          Ajitabh
    * @method     perform Alumni no degree logic
    * @revision        
    */
    public static void performAlumniNoDegreeLogic(set<String>caIds){
        List<Course_Attempt__C> eligibleCaList= new List<Course_Attempt__C>();
        List<Course_Attempt__C> caList= new List<Course_Attempt__C>();
        List<String> contactProfile = new List<String>();          
        List<Contact> updateContactList = new List<Contact>();
        set<string> conIds= new set<string>();
        
        //query all the course attempt where parent Course has sublevel in ('41','42','77','78')
        //calculate total achieved credit points for completed unit attempts for a Course attempt
        If(!caIds.isEmpty()){
            for(Course_Attempt__C ca : [select id,Contact__c,(select id, Achieved_Credit_Points__c from Unit_Attempts__r where 
                                                              Status__c='Completed'),Course__c,Course__r.Faculty__c,Course__r.Type__c,
                                        Course__r.Sub_Level__c from Course_Attempt__C where (id IN: CAIds) and 
                                        (Course__r.Type__c='Course-All' and Course__r.Sub_Level__c IN ('41','42','77','78'))]){
                                            decimal creditScore=0;
                                            for(Unit_Attempt__c  ua : ca.Unit_Attempts__r){
                                                creditScore=creditScore+ua.Achieved_Credit_Points__c;
                                            }    
                                            if(creditScore >= 18){
                                                eligibleCaList.add(ca);  
                                                conIds.add(ca.Contact__c);
                                            }   
                                        }
        }
        if(eligibleCaList.size()>0){
            createAffiliationforCDCExp(eligibleCaList, null, 0);
        }
        Map<Id,Contact> contactDetails = new Map<Id,Contact>([SELECT Id, Contact_Profile__c FROM Contact WHERE Id in :conIds]);   
        for(Contact con : contactDetails.values()){
            if(con.Contact_Profile__c != null){
                contactProfile.addAll(con.Contact_Profile__c.split(';'));
            }
            if(!contactProfile.contains('Alumni No Degree')){
                contactProfile.add('Alumni No Degree');
                con.Contact_Profile__c='';
                for(integer i=0;i< contactProfile.size();i++){
                    con.Contact_Profile__c=con.Contact_Profile__c+contactProfile[i]+';';         
                }
                updateContactList.add(con);
            }
            contactProfile.clear();    
        } 
        if(updateContactList.size()>0){
            update updateContactList;
        }           
    }
    
    /**
    * @author     Mac Domingo
    * @method     Set Default Values in Affiliation
    * @revision        
    */
    public void setDefaults(Affiliation__c rec){
        populateCompositeKey(rec);    //compositeKey
    }
    /**
    * @author     Mac Domingo
    * @method     Updates the value of the Composite Key field in the Affiliation object
    * @revision        
    */
    public void generateNewCompositeKey(Affiliation__c rec){
        populateCompositeKey(rec);    //compositeKey
    }
    /**
    * @author     Mac Domingo
    * @method     Set Default Values of CompositeKey field in Affiliation object
    * @revision        
    */
    public void populateCompositeKey(Affiliation__c rec){
        Id applicantrecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByName().get('Applicant').getRecordTypeId();
        if(applicantrecordTypeId == rec.RecordTypeId){
            rec.Composite_Key__c = ContactPointUtility.getAffiliationKey(rec);
        }        
    }
}