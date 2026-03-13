/*
 * Copyright (c) 2019, UC Innovation, Inc.  All Rights Reserved.
 *                     http://www.ucinnovation.com
 *
 * This source code is licensed, not sold, and is subject to a written
 * license agreement.  Among other things, no portion of this source
 * code may be copied, transmitted, disclosed, displayed, distributed,
 * translated, used as the basis for a derivative work, or used, in
 * whole or in part, for any program or purpose other than its intended
 * use in compliance with the license agreement as part of UC Innovation's
 * software.  This source code and certain of the algorithms contained
 * within it are confidential trade secrets of UC Innovation, Inc.
 * and may not be used as the basis for any other
 * software, hardware, product or service.
 */
 
 /**
 * Handles methods related to getting news data from the NewsAPI
 *
 * @author:  Ken Tang
 * @version: 1.0
 * @since:   1.0
 */

public without sharing class PORTAL_News {

    /**
     * Get news data for all the possible categories.
     *
     * @since: 	1.0
     */
    
    public static void getNewsFromAllCategories() {
        Map<String, Schema.RecordTypeInfo> recordTypeList = Schema.SObjectType.Listing__c.getRecordTypeInfosByName();
        
        for (String key : recordTypeList.keySet())
        {
            getNewsFromCategory('us', key);
        }
    }

    /**
     * Get news data based on the country for all categories associated with the 'News' listing type.
     *
     * @param: country     	The country that the news is associated with.
     * @param: listingType  Should be 'News' only.
     * @since: 				1.0
     */
    
    public static void getNewsFromCategory(String country, String listingType) {
        Id devRecordTypeId = Schema.SObjectType.Listing__c.getRecordTypeInfosByName().get(listingType).getRecordTypeId();
        
        List<Listing__c> listingList = [SELECT Id, Recommend_Type_1__c
                                        FROM Listing__c
                                        WHERE RecordTypeId = :devRecordTypeId];
        
        Set<String> categorySet = new Set<String>();
                
        for (Listing__c lst : listingList) {
            categorySet.add(lst.Recommend_Type_1__c);
        }
                
        for (String cat : categorySet) {
            getNewsFromNewsAPI(country, cat);
        }
    }
    
    /**
     * Get news data based on the categories defined within the method.
     *
     * @since: 	1.0
     */
    
    public static void getNews() {
        // Predefined categories
        getNewsFromNewsAPI('us', 'General');
    }


    /**
     * Get news data based on the country and category specified.
     *
     * @param: country     	The country that the news is associated with.
     * @param: category  	Category of the news we want.
     * @since: 				1.0
     */
    
    @future(callout=true)
    // Test functions for getting news from News API
    public static void getNewsFromNewsAPI(String country, String category) {        
        String apiKey = 'b0cb9b363ce24dcc954b52d776385076';
        HttpRequest req = new HttpRequest();
        
        String endpointStr = 'https://newsapi.org/v2/top-headlines?country=' + country + '&category=' + category.toLowerCase() + '&apiKey=' + apiKey;

        if (String.isNotEmpty(category)) {
            req.setEndpoint(endpointStr);
        }
        else {
            req.setEndpoint('https://newsapi.org/v2/everything?q=' + category.toLowerCase() + '&sortBy=publishedAt&apiKey=' + apiKey);
        }

        req.setMethod('GET');

        // Specify the required user name and password to access the endpoint
        // As well as the header and header information

        // Create a new http object to send the request object
        // A response object is generated as a result of the request

        Http http = new Http();
        HTTPResponse res = http.send(req);
        String result = res.getBody();

        JSON2Apex tmp = (JSON2Apex)JSON.deserialize(result, JSON2Apex.class);

        insertIntoListing(tmp, category);
    }

    /**
     * Creating Listing records based no the news data.
     *
     * @param: target     	Contains the news data.
     * @param: category  	Category of the news data.
     * @since: 				1.0
     */
    
    public static void insertIntoListing(JSON2Apex target, String category) {
        Id devRecordTypeId = Schema.SObjectType.Listing__c.getRecordTypeInfosByName().get('News').getRecordTypeId();        
        if (target.articles != null && target.articles.size() != 0) {
            List<Listing__c> lstToBeInserted = new List<Listing__c>();

            for (Articles art : target.articles) {
                
                String dtStr = art.publishedAt;
                dtStr = dtStr.replace('T', ' ').replace('Z', '');
              
                Listing__c toBeInserted = new Listing__c(
                    RecordTypeId = devRecordTypeId,
                    Title_URL__c = art.url,
                    Header_Image_from_URL__c = art.urlToImage,
                    Header_Content__c = art.description,
                    Body_Content__c = art.content,
                    Author__c = art.author,
                    Source__c = art.source.name,
                    Start_Date_Time__c = DateTime.valueOf(dtStr),
                    Is_Publicly_Available__c = true,
                    Portal_Zone__c = 'All'
                );
                
                if (art.title.length() > 80) {
                    toBeInserted.Name = art.title.substring(0, 80);
                }                

                if ( String.isEmpty(toBeInserted.Header_Image_from_URL__c) || String.isEmpty(toBeInserted.Body_Content__c)) {
                  	continue;
                } else {
                    toBeInserted.Name = art.title;
                }

                toBeInserted.Recommend_Type_1__c = category;
                
                lstToBeInserted.add(toBeInserted);
            }

            // AllOrNone to false so that it will ignore those who are duplicates
             Database.SaveResult[] results = Database.insert(lstToBeInserted, false);
        }
    }

    /**
     * Data structures used by the NewsAPI
     *
     * @author:  Ken Tang
     * @version: 1.0
     * @since:   1.0
     */
    public class JSON2Apex {

        String status;
        Integer totalResults;
        List<Articles> articles;
    }

    public class Articles {
        Source source;
        String author;
        String title;
        String description;
        String url;
        String urlToImage;
        String publishedAt;
        String content;
    }

    public class Source {
        String id;
        String name;
    }
}