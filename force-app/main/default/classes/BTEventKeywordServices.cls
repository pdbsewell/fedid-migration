/**
 * @author RANAND
 * @date 2022-05-10
 * @group Event Keyword Management
 * @description Service class for Blackthorn Event Keyword Trigger
 * @revision
 *         2022-05-10 -   RANAND           -EPBBS-2629 Validate Event Keyword Selection on Events
 *         2022-06-01 -   Ibrahim Rumi     -EPBBS-2643 Manage event keywords cascading from event groups to related events
 **/
public with sharing class BTEventKeywordServices {
    /**
     * @description EPBBS-2629 Validate the selection of Keywords against an Event
     **/
    Set<String> singlecategorySet = new Set<String>{'Activity Type', 'Interest Areas', 'Location'};
    public void validateCategory(List<conference360__Event_Keyword__c> keywordList){

        Set<Id> eventIds = new Set<Id>();
        Set<String> existingKeywords = new Set<String>();
        Set<String> newRecordsSet = new Set<String>();
        //Check if new records contains duplicates, then throe an error
        for(conference360__Event_Keyword__c objKeyword : keywordList){
            String key = objKeyword.conference360__Event__c +'_'+objKeyword.conference360__Keyword_Category__c;
            if(singlecategorySet.contains(objKeyword.conference360__Keyword_Category__c) && newRecordsSet.contains(key)){
                objKeyword.addError(System.Label.BT_ERR_MSG_KEYWORD_VALIDATION);
            }
            newRecordsSet.add(key);
            eventIds.add(objKeyword.conference360__Event__c);
        }
        //Checks for exusting keywords against selected category
        for(conference360__Event_Keyword__c objK : [SELECT conference360__Event__c,
                                                    conference360__Keyword__c,conference360__Keyword_Category__c 
                                                    FROM conference360__Event_Keyword__c 
                                                    WHERE conference360__Event__c IN: eventIds 
                                                    AND conference360__Keyword_Category__c IN: singlecategorySet
                                                    AND Id NOT IN: keywordList]){
            existingKeywords.add(objK.conference360__Event__c+'_'+objK.conference360__Keyword_Category__c);
        }

        for(conference360__Event_Keyword__c objKeyword : keywordList){
            String key = objKeyword.conference360__Event__c +'_'+objKeyword.conference360__Keyword_Category__c;
            if(existingKeywords.contains(key)){
                objKeyword.addError(System.Label.BT_ERR_MSG_KEYWORD_VALIDATION);
            }
        }
    }
    
    /*
* Manage event Keywords automatically when an Event Group is added/updated/deleted
*/
public void manageEventKeywordsForGroup(Set<Id> eventGroupIds){

    Map<Id, List<conference360__Event_Keyword__c>> groupEventKeywordMap = new Map<Id, List<conference360__Event_Keyword__c>>();
    Map<String, conference360__Event_Keyword__c> evtKeywordRecMap = new Map<String, conference360__Event_Keyword__c>();
    List<conference360__Event_Keyword__c> newEventKeywordList =  new List<conference360__Event_Keyword__c>();
	
    //Get all the keywords related to Event Group or Events related to list of Ids
    for (conference360__Event_Keyword__c evtKeywordRec: [SELECT Id,conference360__Keyword__c, conference360__Event__c, 
                                                            Event_Group__c, Event_Group_Event_Keyword_Id__c  
                                                         FROM 
                                                            conference360__Event_Keyword__c 
                                                         WHERE 
                                                            Event_Group__c IN :eventGroupIds 
                                                            OR (conference360__Event__r.conference360__Event_Group__c IN: eventGroupIds)])
    {
        if(evtKeywordRec.conference360__Event__c == null){
            if(groupEventKeywordMap.containsKey(evtKeywordRec.Event_Group__c)){
                List<conference360__Event_Keyword__c> tempSet = groupEventKeywordMap.get(evtKeywordRec.Event_Group__c);
                tempSet.add(evtKeywordRec);
                groupEventKeywordMap.put(evtKeywordRec.Event_Group__c, tempSet);
            }
            else{
                groupEventKeywordMap.put(evtKeywordRec.Event_Group__c, new List<conference360__Event_Keyword__c>{evtKeywordRec});
            }
        }
        else if(evtKeywordRec.conference360__Event__c != null && evtKeywordRec.Event_Group_Event_Keyword_Id__c != null){
            evtKeywordRecMap.put(String.valueOf(evtKeywordRec.conference360__Event__c)+'-'+String.valueOf(evtKeywordRec.conference360__Keyword__c), evtKeywordRec);
        }
        
    }

    
    for(conference360__Event__c event : [SELECT Id,conference360__Event_Group__c FROM conference360__Event__c WHERE conference360__Event_Group__c IN :eventGroupIds]){
        if(groupEventKeywordMap.containsKey(event.conference360__Event_Group__c)){
            for(conference360__Event_Keyword__c EventKeyword : groupEventKeywordMap.get(event.conference360__Event_Group__c)){
                if(evtKeywordRecMap.containsKey(String.valueOf(event.Id)+'-'+String.valueOf(EventKeyword.conference360__Keyword__c))){
                    //Remove the EventKeyword record from map if already present
                    evtKeywordRecMap.remove(String.valueOf(event.Id)+'-'+String.valueOf(EventKeyword.conference360__Keyword__c));
                }else{
                    //Create a new instance for EventKeyword record for Event
                    newEventKeywordList.add(new conference360__Event_Keyword__c(conference360__Keyword__c = EventKeyword.conference360__Keyword__c,
                                                                conference360__Event__c = event.Id,
                                                                Event_Group_Event_Keyword_Id__c = event.conference360__Event_Group__c));
                }
            }
        }
    }
    
    if(!evtKeywordRecMap.isEmpty()){
        delete evtKeywordRecMap.values();
    }
    if(!newEventKeywordList.isEmpty()){
        for(Integer i=0;i<newEventKeywordList.size();i++){
            system.debug('EK'+i+'======'+newEventKeywordList[i]);
        }
        Database.insert(newEventKeywordList, false);
    }
}

}