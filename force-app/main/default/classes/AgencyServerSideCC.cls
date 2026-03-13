/*******************************************************************************
* @author:		K Liew
* @date:		17.July.2018
* @description:	Server side controller for the AgenciesController Lightning 
*				Component.  Purpose is to Get and Return Agency records back to
*				client-side controller.
* @revision:
*				17.July.2018 KL > Initial class creation.
*******************************************************************************/
public without sharing class AgencyServerSideCC {

    
/*******************************************************************************
* @author:		K Liew
* @date:		19.October.2018
* @description:	Modified method to return all Agencies but with Pagination for 
*				performance improvement, invoked by client-side controller's
*				doInit method.  Takes no input args, and returns list of
*				Accounts.
* @revision:
* 				19.October.2018 KL > Initial method creation.
*******************************************************************************/
    @AuraEnabled
    public static PageResult getAllAgenciesWithPagination (Decimal pageNumber) {
        
        try {
            
            Agent_Onboarding_Settings__c cs = Agent_Onboarding_Settings__c.getOrgDefaults();

            Schema.DescribeSObjectResult d = Schema.SObjectType.Account; 
            Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtByName = rtMapByName.get('Agency');

            Integer pSize = (Integer)cs.RecordPerPage__c;

            PageResult res = new PageResult();
            Integer offset = ((Integer)pageNumber - 1) * pSize;
            Integer totalRows = 0;

            res.pageSize = pSize;

            res.agencies = [SELECT 
                            Id, 
                            Name, 
                            Phone,
                            Email__c,
                            Website,
                            ShippingAddress,
                            ShippingStreet,
                            ShippingCity,
                            ShippingState,
                            ShippingCountry,
                            ShippingPostalCode,
                            Principal_Agent__r.Name,
                            Branch_Manager__r.Name,
                            Legal_Entity_Name__c,
                            RecordType.Name 
                            FROM Account 
                            WHERE RecordTypeId = :rtByName.getRecordTypeId()
                            AND Monash_AM_Web_Status__c = true
                            ORDER BY Name
                            LIMIT :pSize
                            OFFSET :offset
                           ];

            res.total = [SELECT count()
                            FROM Account 
                            WHERE RecordTypeId = :rtByName.getRecordTypeId()
                            AND Monash_AM_Web_Status__c = true];

            if (res.total != 0) {
                res.page = (Integer)pageNumber;
            } else {
                res.page = 0;
            }

            return res;
            
        } catch (Exception ex) {
            
            System.debug(logginglevel.DEBUG, 'Class: AgencyServerSideCC, Method: getAllAgenciesWithPagination, Message: ' + ex.getMessage());
            ExLog.add('AgencyServerSideCC','Account / Agent Management','getAllAgenciesWithPagination', ex);
            return null;
            
            // investigate why unable to perform some server side error handling + throw AuraHandledException back to client-side controller...
            // throw new AuraHandledException('Error from server-side controller: ' + ex.getMessage());
            
        } finally {
            
            // Something executed whether there was an error or not
            
        }  
    }

    
/*******************************************************************************
* @author:		K Liew
* @date:		24.Oct.2018
* @description:	Variation of the original method to support pagination, see Jira
*				ticket AM-160
* @revision:
* 				24.Oct.2018 KL > Initial method creation.
*******************************************************************************/
    @AuraEnabled
    public static PageResult searchAgenciesWithPagination (String searchTerm, Decimal pageNumber) {
        String soslStatement;        
        String soslStatementTotal;
        String escapedSearchTerm;
        
        try {
            
            Agent_Onboarding_Settings__c CS = Agent_Onboarding_Settings__c.getOrgDefaults();

            Schema.DescribeSObjectResult d = Schema.SObjectType.Account; 
            Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtByName = rtMapByName.get('Agency');

            Integer pSize = (Integer)cs.RecordPerPage__c;

            PageResult res = new PageResult();
            Integer offset = ((Integer)pageNumber - 1) * pSize;
            Integer totalRows = 0;

            res.pageSize = pSize;

            escapedSearchTerm = escapeSOSLTerm(searchTerm);
            
            soslStatement = 'FIND {' + escapedSearchTerm + '} IN ALL FIELDS RETURNING Account (Id, Name, Phone, Email__c, Website, ShippingAddress, ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingPostalCode, Principal_Agent__r.Name, Branch_Manager__r.Name, Legal_Entity_Name__c WHERE RecordTypeId = \''+ rtByName.getRecordTypeId() + '\' AND Monash_AM_Web_Status__c = true ORDER BY Name LIMIT :pSize OFFSET :offset)';
            System.debug('MJC: ' + soslStatement);

			// wondering if this make performance worse, double query.
            soslStatementTotal = 'FIND {' + escapedSearchTerm + '} IN ALL FIELDS RETURNING Account (Id WHERE RecordTypeId = \''+ rtByName.getRecordTypeId() + '\' AND Monash_AM_Web_Status__c = true)';
            
            List<List<SObject>> soslResult = search.query(soslStatement);
            res.agencies = soslResult.get(0);

            List<List<SObject>> soslResult2 = search.query(soslStatementTotal);
            res.total = soslResult2.get(0).size();
            
            if (res.total != 0) {
                res.page = (Integer)pageNumber;
            } else {
                res.page = 0;
            }

            return res;
            
        } catch (Exception ex) {
            
            System.debug(logginglevel.DEBUG, 'Class: AgencyServerSideCC, Method: searchAgenciesWithPagination, Message: ' + ex.getMessage());
            System.debug(logginglevel.DEBUG, 'Class: AgencyServerSideCC, Method: searchAgenciesWithPagination, Search String: ' + soslStatement);
            System.debug(logginglevel.DEBUG, 'Class: AgencyServerSideCC, Method: searchAgenciesWithPagination, Search String Total: ' + soslStatementTotal);
            ExLog.add('AgencyServerSideCC','Account / Agent Management','searchAgenciesWithPagination ', ex);
            
            return null;
            
        } finally {
            
            // Something executed whether there was an error or not
            
        }
    }

    
/*******************************************************************************
* @author:		K Liew
* @date:		23.Oct.2018
* @description:	A variation to the method above, modified ti support pagination
*				of results returned.
* @revision:
* 				23.Oct.2018 KL > Initial method creation.
*******************************************************************************/
    @AuraEnabled
    public static PageResult searchAgenciesByCountryWithPagination (String chosenCountry, Decimal pageNumber) {
        
        try {

			system.debug('!@#$% chosenCountry = ' + chosenCountry);            
            Agent_Onboarding_Settings__c cs = Agent_Onboarding_Settings__c.getOrgDefaults();

            Schema.DescribeSObjectResult d = Schema.SObjectType.Account; 
            Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtByName = rtMapByName.get('Agency');

            Integer pSize = (Integer)cs.RecordPerPage__c;

            PageResult res = new PageResult();
            Integer offset = ((Integer)pageNumber - 1) * pSize;
            Integer totalRows = 0;

            res.pageSize = pSize;

            res.agencies = [SELECT 
                            Id, 
                            Name, 
                            Phone,
                            Email__c,
                            Website,
                            ShippingAddress,
                            ShippingStreet,
                            ShippingCity,
                            ShippingState,
                            ShippingCountry,
                            ShippingPostalCode,
                            Principal_Agent__r.Name,
                            Branch_Manager__r.Name,
                            Legal_Entity_Name__c,
                            RecordType.Name 
                            FROM Account 
                            WHERE RecordTypeId = :rtByName.getRecordTypeId()
                            AND Monash_AM_Web_Status__c = true
                            AND ShippingCountry = :chosenCountry
                            ORDER BY Name
                            LIMIT :pSize
                            OFFSET :offset
                           ];

            res.total = [SELECT count()
                         FROM Account 
                         WHERE RecordTypeId = :rtByName.getRecordTypeId()
                         AND ShippingCountry = :chosenCountry
                         AND Monash_AM_Web_Status__c = true
                        ];

            if (res.total != 0) {
                res.page = (Integer)pageNumber;
            } else {
                res.page = 0;
            }
            
            return res;
            
        } catch (Exception ex) {
            
            System.debug(logginglevel.DEBUG, 'Class: AgencyServerSideCC, Method: searchAgenciesByCountryWithPagination, Message: ' + ex.getMessage());
            ExLog.add('AgencyServerSideCC','Account / Agent Management','searchAgenciesByCountryWithPagination', ex);
            return null;
            
            // investigate why unable to perform some server side error handloing + throw AuraHandledException back to client-side controller...
            // throw new AuraHandledException('Error from server-side controller: ' + ex.getMessage());
            
        } finally {
            
            // Something executed whether there was an error or not
            
        }
    }
    
    
/*******************************************************************************
* @author:		K Liew
* @date:		24.Oct.2018
* @description:	Modified version of the original method to enable pagination
*				for AM-160
* @revision:
* 				24.Oct.2018 KL > Initial method creation.
*******************************************************************************/
    @AuraEnabled
    public static PageResult searchAgenciesBy1stAlphabetWithPagination (String chosenLetter, Decimal pageNumber) {
        
        try {
            
            Agent_Onboarding_Settings__c cs = Agent_Onboarding_Settings__c.getOrgDefaults();

            Schema.DescribeSObjectResult d = Schema.SObjectType.Account; 
            Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtByName = rtMapByName.get('Agency');

            String likeClause = chosenLetter + '%';

            Integer pSize = (Integer)cs.RecordPerPage__c;

            PageResult res = new PageResult();
            Integer offset = ((Integer)pageNumber - 1) * pSize;
            Integer totalRows = 0;

            res.pageSize = pSize;
            
            res.agencies = [SELECT 
                            Id, 
                            Name, 
                            Phone,
                            Email__c,
                            Website,
                            ShippingAddress,
                            ShippingStreet,
                            ShippingCity,
                            ShippingState,
                            ShippingCountry,
                            ShippingPostalCode,
                            Principal_Agent__r.Name,
                            Branch_Manager__r.Name,
                            Legal_Entity_Name__c,
                            RecordType.Name 
                            FROM Account 
                            WHERE RecordTypeId = :rtByName.getRecordTypeId()
                            AND Monash_AM_Web_Status__c = true
                            AND Name LIKE :likeClause
                            ORDER BY Name
                            LIMIT :pSize
                            OFFSET :offset
                           ];
            
            res.total = [SELECT count()
                         FROM Account 
                         WHERE RecordTypeId = :rtByName.getRecordTypeId()
                         AND Monash_AM_Web_Status__c = true
                         AND Name LIKE :likeClause];

            if (res.total != 0) {
                res.page = (Integer)pageNumber;
            } else {
                res.page = 0;
            }

            return res;
            
        } catch (Exception ex) {
            
            System.debug(logginglevel.DEBUG, 'Class: AgencyServerSideCC, Method: searchAgenciesBy1stAlphabetWithPagination, Message: ' + ex.getMessage());
            ExLog.add('AgencyServerSideCC','Account / Agent Management','searchAgenciesBy1stAlphabetWithPagination', ex);
            return null;
            
        } finally {
            
        }
        
    }   
    
    public static String escapeSOSLTerm(String term){
        term = String.escapeSingleQuotes(term.replace('\'', '\\'));
        Pattern reservedPattern = pattern.compile('[\\?&\\|!{}\\[\\]\\(\\)\\^~\\*:\\\"\\+-]');
        Matcher myMatcher = reservedPattern.matcher(term);
        List<Integer> escapeIndexs = new List<Integer>();
        while(true){
            if(myMatcher.find()){
                escapeIndexs.add(myMatcher.start());
            }else{
                break;
            }
        }
        escapeIndexs.sort();
        for(Integer i = escapeIndexs.size()-1; i>=0; i--){
            Integer escapeIndex = escapeIndexs[i];
            term = term.substring(0, escapeIndex) + '\\' + term.substring(escapeIndex);
        }
        return term; 
	} 
    
}