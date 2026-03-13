/**
* @author           Nick Guia
* @date             02/08/2017
* @description      - Apex Controller for BMSEmailReviewV2 page
* @revision
*           23.06.2025 - Ibrahim Rumi - Limiting the buildQueryString method to return only the campaigns in the last 365 days
**/
global with sharing class BMSEmailReviewCCV2 {

    //public variables
    public List<String> campaignStatusList {
        get {
            if(campaignStatusList == null) {
                campaignStatusList = BMSUtils.campaignStatusList;
            }
            return campaignStatusList;
        }
        set;
    }

    public List<String> campaignTypeList {
        get {
            if(campaignTypeList == null) {
                campaignTypeList = BMSUtils.campaignTypeList;
            }
            return campaignTypeList;
        }
        set;
    }

    public Boolean isAdmin {
        get {
            if(isAdmin == null) {
                isAdmin = BMSUtils.checkIfAdmin(UserInfo.getProfileId());
            }
            return isAdmin;
        }
        set;
    }

    /**
    * @author       Nick Guia
    * @date         02/08/2017
    * @description  - Remote Action method for retrieving table data.
    *                 will be invoked by page's javascript
    * @return       - JSON string of wrapper class
    **/
    @RemoteAction
    global static String initializeTableData() {
        String sJSON;

        //build query string based on business rules
        String queryString = buildQueryString();
        //retrieve records and build the wrapper class to be displayed in the table
        List<BMSUtils.TableDataWrapper> tdwList = retrieveMassEmails(queryString);

        if(!tdwList.isEmpty()) {
            sJSON = JSON.serializePretty(tdwList);
        }
        return sJSON;
    }

    /**
    * @author       Nick Guia
    * @date         02/08/2017
    * @description  - Remote Action method for updating campaign status
    **/
    @RemoteAction
    global static void updateCampaignStatus(List<String> cmpIds, Boolean isApproved) {
        List<Id> campaignIdSet = new List<Id>();
        List<Campaign> cmpUpdateList = new List<Campaign>();
        String status = (isApproved) ? Label.Campaign_Status_Approved : Label.Campaign_Status_Cancelled;
        try {
            for(Campaign cmpLoop : [SELECT Id, Status
                                    FROM Campaign
                                    WHERE Id IN :cmpIds])
            {
                cmpLoop.Status = status;
                campaignIdSet.add(cmpLoop.Id);
                cmpUpdateList.add(cmpLoop);
            }
            update cmpUpdateList;
            
            //call new Queueable batch to update campaign Member status to "Ready to Send"
            BMSUpdateCampaignMemStatusQueueable campaignMemberJob = new BMSUpdateCampaignMemStatusQueueable(campaignIdSet);
            System.enqueueJob(campaignMemberJob);
        } catch (Exception e) {
            
            nebula.logger.exception(e.getMessage(), e);
        }
    }

    /**
    * @author       Nick Guia
    * @date         02/08/2017
    * @description  - method for building query String based on business rules
    * @param        - profileId = Id of current user's profile
    * @return       - SOQL string
    **/
    private static List<BMSUtils.TableDataWrapper> retrieveMassEmails(String queryString) {
        List<BMSUtils.TableDataWrapper> tdwList = new List<BMSUtils.TableDataWrapper>();
        try {
            for (Campaign cmpLoop: Database.query(queryString)) {
                BMSUtils.TableDataWrapper tdw = new BMSUtils.TableDataWrapper(cmpLoop);
                tdwList.add(tdw);
            }   
        } catch (Exception e) {
            
            nebula.logger.exception(e.getMessage(), e);
        }
        
        return tdwList;
    }

    /**
    * @author       Nick Guia
    * @date         02/08/2017
    * @description  - method for building query String based on business rules
    * @return       - SOQL string
    **/
    private static String buildQueryString() {
        String sObjectName = 'Campaign';
        //add fields here as required
        String fields =  'Id, Name, SMS_Count__c, Status, Total_Members__c, ' + 
                        'Owner_Name__c, CreatedDate, Email_Template__c, ' +
                        'Batch_Finished__c, SMS_Body__c, Type ';

        /**add filters as required :
           - show only On Hold, Approved, or Cancelled
           - sharing rules apply on record visibility
        **/
        String filter = '(Status = \'' + Label.Campaign_Status_On_Hold + '\'' +
                        'OR Status = \'' + Label.Campaign_Status_Approved + '\'' +
                        'OR Status = \'' + Label.Campaign_Status_Cancelled + '\')';

        
        //filter by record type ID to norrow down resultset
        filter += ' AND RecordTypeId = \'' + String.valueOf(BMSUtils.bmsRecordTypeId) + '\'';
        filter += ' AND CreatedDate = LAST_N_DAYS:365';

        /** add query limit based on 'rowLimit' variable (200 at the moment) 
        *    - remove this for now to see how much to see volume of records that the page can take
        **/
        //filter += ' ORDER BY CreatedDate DESC LIMIT ' + BMSUtils.BMS_EMAIL_REVIEW_ROW_LIMIT;
		filter += ' ORDER BY CreatedDate DESC' ;
        //build query string and return
        return String.format(
                    'SELECT {0} ' +
                    'FROM {1} ' +
                    'WHERE {2}',
            new List<String> {
                fields,
                sObjectName,
                filter
            });
    }
}