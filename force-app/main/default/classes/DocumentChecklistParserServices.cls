/**
 * @author Trent De Laney
 * @date 28 Mar 2019 at 3:14:11 pm
 * @group Services
 * @description Allows the replacement of values within a given string to be dynamically populated with valeus from the Salesforce Database
 */
public with sharing class DocumentChecklistParserServices {
    //Variables to further configure word cases
    public static Set<String> alwaysSmallCaps{
        get { 
            if(alwaysSmallCaps == null){
                alwaysSmallCaps = new Set<String>();
                for(Document_Checklist_Parser_Keyword__mdt loopKeyword : [SELECT MasterLabel, Case__c FROM Document_Checklist_Parser_Keyword__mdt WHERE Case__c = 'Lower']){
                    alwaysSmallCaps.add(loopKeyword.MasterLabel.toUpperCase());
                }
            }
            return alwaysSmallCaps; 
        }
        set;
    }
    public static Set<String> alwaysBigCaps{
        get { 
            if(alwaysBigCaps == null){
                alwaysBigCaps = new Set<String>();
                for(Document_Checklist_Parser_Keyword__mdt loopKeyword : [SELECT MasterLabel, Case__c FROM Document_Checklist_Parser_Keyword__mdt WHERE Case__c = 'Upper']){
                    alwaysBigCaps.add(loopKeyword.MasterLabel.toUpperCase());
                }
            }
            return alwaysBigCaps; 
        }
        set;
    }

    /**
     * @author Trent De Laney
     * @description
     * @date 28 Mar 2019 at 3:15:29 pm
     * @param
     * @return
     */
    public static Map<String, List<Document_Checklist_Parser_Setting__mdt>> querySetup(){
        Map<String, List<Document_Checklist_Parser_Setting__mdt>> objectField = new Map<String, List<Document_Checklist_Parser_Setting__mdt>>();

        List<Document_Checklist_Parser_Setting__mdt> settings = [
                SELECT
                        DeveloperName,
                        Field__c,
                        Field_Name__c,
                        Id,
                        Label,
                        Language,
                        MasterLabel,
                        NamespacePrefix,
                        Object_Name__c,
                        QualifiedApiName
                FROM Document_Checklist_Parser_Setting__mdt
                WHERE Active__c = true];

        //Setup the Parser in Memory
        for(Document_Checklist_Parser_Setting__mdt setting :settings){
            if(!objectField.containsKey(setting.Object_Name__c)) {
                //Add to the map
                objectField.put(setting.Object_Name__c, new List<Document_Checklist_Parser_Setting__mdt>());
            }
            objectField.get(setting.Object_Name__c).add(setting);
        }

        return objectField;
    }

    /**
     * @author Trent De Laney
     * @description Takes in a list of settings (relating to a single object) and returns the set for addition into the query
     * @date 3 Apr 2019 at 10:33:05 am
     * @param List<Parser_Setting_mdt>
     * @return
     */
    public static Set<String> buildSoql(List<Document_Checklist_Parser_Setting__mdt> settings)
    {
        Set<String>  soqlValues = new Set<String>();
        for(Document_Checklist_Parser_Setting__mdt s : settings)
        {
            soqlValues.add(s.Field_Name__c);
        }
        return soqlValues;
    }

    /**
     * @author Trent De Laney
     * @description Parses a string with a single object parameter to be replaced into the source string
     * @date 3 Apr 2019 at 1:31:52 pm
     * @param
     * @return 
     */
    public static String parseString(List<Document_Checklist_Parser_Setting__mdt> parser, 
                                    Map<String, Schema.DisplayType> parserDetailsObjectFieldDataType, 
                                    SObject o, 
                                    String source)
    {
        for(Document_Checklist_Parser_Setting__mdt p : parser){
            Schema.DisplayType dataTyValue = parserDetailsObjectFieldDataType.get(p.Object_Name__c+''+p.Field_Name__c);
            if(source.contains(p.Field__c) && o.get(p.Field_Name__c) != null){
                if(dataTyValue == Schema.DisplayType.DATE || dataTyValue == Schema.DisplayType.DATETIME){
                    //Handle Date fields properly
                    source = source.replace(p.Field__c, ((DateTime)o.get(p.Field_Name__c)).format('MMMM dd, YYYY'));
                }else{
                    //As else for now
                    if(!String.isBlank(o.get(p.Field_Name__c).toString())){
                        source = source.replace(p.Field__c, DocumentChecklistParserServices.capitalCase(o.get(p.Field_Name__c).toString().toLowerCase().capitalize()));
                    }
                }
            }
        }

        return source;
    }

    /**
     * @author Trent De Laney
     * @description Capital cases a whole sentance as opposed to a single word at the start of the string
     * @date 5 Apr 2019 at 12:01:52 pm
     * @param String input
     * @return String output
     */
    public static String capitalCase(String input){
        String output = '';
        if(!String.isBlank(input)){
            String[] values = input.toLowerCase().split(' ');
            for(String s : values){
                if(s.length() == 1){
                    //Keep case if its a single letter
                    output += s + ' ';
                }else if(DocumentChecklistParserServices.alwaysBigCaps.contains(s.toUpperCase())){
                    //Change the String to all caps
                    output += s.toUpperCase() + ' ';
                }else if(DocumentChecklistParserServices.alwaysSmallCaps.contains(s.toUpperCase())){
                    //Change the string to lower case
                    output += s.toLowerCase() + ' ';
                }else{                
                    //if not found on the parser keywords change the first letter to capital letter
                    output += s.capitalize() + ' ';
                }
            }
        }else{
            output = input;
        }

        return output;
    }
}