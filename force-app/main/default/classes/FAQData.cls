/**
 * @author                      Kristian Vegerano
 * @created                     February 02, 2018
 * @description                 Class that would contain the logic for FAQDataService. Retrieves all published articles and formats it on JSON
 */
public without sharing class FAQData {
    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Updates the case Email_To__c field with the ToAddress field of EmailMessage
     * @return                      List<ArticleData> - list of published FAQ articles
     */
    public static List<ArticleData> retrievePublishedFAQArticles(){
        //Initialize Variables
        List<ArticleData> publishedFAQList = new List<ArticleData>();
        Map<String, Knowledge_Article__kav> faqMap = new Map<String, Knowledge_Article__kav>();
        
        //Query published articles whole library
        for(Knowledge_Article__kav loopFAQ : [SELECT Id, RecordType.Name, PublishStatus, Authorised_by__c, Owning_Org_Unit__c,
                                       Summary, Title, Australia_Student__c, Legacy_Keywords__c, 
                                       CreatedDate, LastModifiedDate, Category_One__c,
                                       Category_Two__c, UrlName, Answer__c, Australia_Staff__c
                                FROM Knowledge_Article__kav
                                WHERE RecordType.Name = 'FAQ'  
                                ORDER BY UrlName DESC]){
            if(loopFAQ.UrlName != null){
                faqMap.put(loopFAQ.UrlName.toLowerCase(), loopFAQ);
            }
        }
        
        //Query published articles available to customer or public
        for(Knowledge_Article__kav loopFAQ : [SELECT Id, RecordType.Name, PublishStatus, Authorised_by__c, Owning_Org_Unit__c,
                                       Summary, Title, Australia_Student__c, Legacy_Keywords__c, 
                                       CreatedDate, LastModifiedDate, Category_One__c,
                                       Category_Two__c, UrlName, Answer__c, Australia_Staff__c
                                FROM Knowledge_Article__kav 
                                WHERE PublishStatus = 'Online'
                                    AND RecordType.Name = 'FAQ'   
                                    AND (IsVisibleInPkb = true OR IsVisibleInCsp = true)
                                ORDER BY UrlName DESC]){
            if(loopFAQ.Answer__c != null || loopFAQ.Australia_Student__c != null){
                //Data to list
                publishedFAQList.add(new ArticleData(loopFAQ, faqMap));
            }
        }
        
        return publishedFAQList;
    }
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Method for retrieving Article Data in JSON format with ordered attributes
     */
    public static String generateArticleJSONContent(List<ArticleData> articleDataList) {
        // Create a JSONGenerator object.
        // Pass true to the constructor for not pretty print formatting.
        JSONGenerator generator = JSON.createGenerator(false);
        
        //Create a set for ordering the attributes on the json
        Set<String> orderedFormat = new Set<String>();
        orderedFormat.add('id');
        orderedFormat.add('content_author');
        orderedFormat.add('owning_unit');
        orderedFormat.add('summary');
        orderedFormat.add('question');
        orderedFormat.add('answer');
        orderedFormat.add('keywords');
        orderedFormat.add('authorisedby');
        orderedFormat.add('date_created');
        orderedFormat.add('last_updated');
        orderedFormat.add('solved_count');
        orderedFormat.add('l2category');
        orderedFormat.add('l3category');
        orderedFormat.add('status');
        orderedFormat.add('access');
        orderedFormat.add('url');
        
        //Write start of array
        generator.writeStartArray();
        
        //Iterate through each article records
        for(ArticleData loopArticle : articleDataList){
            //Get field to value map of the wrapper
            Map<String, Object> dataFieldMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(loopArticle));
            
            //Write start of object
            generator.writeStartObject();
            
            for(String dataField : orderedFormat){
                //Write each fields of the ArticleData
                if(dataFieldMap.get(dataField) != null){
                    //Do logic if the field is not blank
                    if(dataFieldMap.get(dataField) instanceof Integer){

                        generator.writeNumberField(dataField, Integer.valueOf(dataFieldMap.get(dataField))); 
                        
                    }else if(dataFieldMap.get(dataField) instanceof String){
                        
                        generator.writeStringField(dataField, String.valueOf(dataFieldMap.get(dataField)));
                        
                    }else if(dataFieldMap.get(dataField) instanceof DateTime){
                        
                        generator.writeDateTimeField(dataField, DateTime.valueOf(dataFieldMap.get(dataField)));
                        
                    }
                }else{
                    //Default the summary field with the question value
                    if(dataField == 'summary'){
                        generator.writeStringField(dataField, String.valueOf(dataFieldMap.get('question')));
                    }else{
                        //Add empty string if blank
                        generator.writeStringField(dataField, '');
                    }
                }
            }
            
            //Write end of object
            generator.writeEndObject();
        }
        
        //Write end of array
        generator.writeEndArray();
        
        //Close the generator to ensure nothing can be written on the generator
        generator.close();
        
        // Get the JSON string.
        return generator.getAsString();
    }
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Wrapper class for the JSON format of the article records used on the web slider
     */
    public class ArticleData{
        public String id {get; set;}
        public String content_author {get; set;}
        public String owning_unit {get; set;}
        public String summary {get; set;}
        public String question {get; set;}
        public String answer {get; set;}
        public String keywords {get; set;}
        public String authorisedby {get; set;}
        public DateTime date_created {get; set;}
        public DateTime last_updated {get; set;}
        public Integer solved_count {get; set;}
        public String l2category {get; set;}
        public String l3category {get; set;}
        public String status {get; set;}
        public String access {get; set;}
        public String url {get; set;}
        
        /**
         * @author                      Kristian Vegerano
         * @created                     February 02, 2018
         * @description                 Constructor
         */
        public ArticleData(Knowledge_Article__kav transformFAQ, Map<String, Knowledge_Article__kav> referenceFaqMap){
            id = transformFAQ.Id;
            content_author = transformFAQ.Authorised_by__c;
            owning_unit = transformFAQ.Owning_Org_Unit__c;
            summary = transformFAQ.Summary;
            question = transformFAQ.Title;
            
            //Add data-url-id
            if(transformFAQ.Answer__c != null || transformFAQ.Australia_Student__c != null || transformFAQ.Australia_Staff__c != null){
                Set<String> matchSet = new Set<String>();
                //Set the answer from staff only field
                if(transformFAQ.Australia_Staff__c != null){
                    answer = transformFAQ.Australia_Staff__c;
                }
                //Set the answer from public facing only field
                if(transformFAQ.Answer__c != null){
                    answer = transformFAQ.Answer__c;
                }
                //Set the answer from australian student & staff field
                if(transformFAQ.Australia_Student__c != null){
                    answer = transformFAQ.Australia_Student__c;
                }
                
				//Remove FAQData from links
                answer = answer.replace('/FAQData', '');
                answer = answer.replace('s/Knowledge_Article', '');
                
                Pattern p = Pattern.compile('(?<=/FAQ-).\\d+'); 
                Matcher mo = p.matcher(answer); 
                while (mo.find()) { 
                    //Add the match to the set
                    matchSet.add('FAQ-' + mo.group());
                }
                
                //Replace all matches with Ids
                for(String loopMatch : matchSet){
                    if(referenceFaqMap.containsKey(loopMatch.tolowerCase())){
                        answer = answer.replaceAll('/article/' + loopMatch + '\\"', '/article/' + loopMatch + '\\" data-url-id=\\"' + referenceFaqMap.get(loopMatch.tolowerCase()).Id + '\\"');
                    }
                }
            }
            
            keywords = transformFAQ.Legacy_Keywords__c;
            authorisedby = transformFAQ.Authorised_by__c;
            date_created = transformFAQ.CreatedDate;
            last_updated = transformFAQ.LastModifiedDate;
            l2category = transformFAQ.Category_One__c;
            l3category = transformFAQ.Category_Two__c;
            url = transformFAQ.UrlName;
            
            //Default to 1
            solved_count = 1;
            //Default to public since we are only retrieving published online articles
            status = 'Public';
            //Default to Students since there are currently no mapping for the access field
            access = 'Students';
        }
    }
}