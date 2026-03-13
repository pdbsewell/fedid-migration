/**
 * @File Name          : ManagedClauseService.cls
 * @Description        : Handles business process for Managed Clause object
 * @Author             : Jasmin Joy Rudio
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 2/27/2020, 10:03:38 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    12/12/2019   Jasmin Joy Rudio     Initial Version
**/
public without sharing class ManagedClauseService {
    public static String getManagedClauseByQuoteLineLocation(String quoteLineId, String location){
        return JSON.serialize(new ManagedClausesSelector().selectByQuoteLineLocation(new Set<String>{quoteLineId}, location));
    }

    public static String getManagedClauseByQuoteId(String quoteId){
        return JSON.serialize(new ManagedClausesSelector().selectByQuoteId(new Set<String>{quoteId}));
    }
    
}