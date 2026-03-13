/**
* @author Jasmin Joy Rudio
* @description Apex class that handles offer summary page queries
* @group SF Offers
*
**/
public with sharing class FormPageService{
    /**
    * @description get all Form Pages 
    * @return the list of Form_Page__c
    **/
    //@AuraEnabled(cacheable = true)
    public static List<FormPage> getFormPage(){
        MyApp_Settings__c myAppInstance = MyApp_Settings__c.getInstance();

        //Contruct the mapping between parent and child form pages
        Map<String, List<FormPage>> formPageMap = new Map<String, List<FormPage>>();
        for(FormPage__mdt loopFormPage : [SELECT Id, DeveloperName, MasterLabel, API_Name__c, Display_Order__c,
                                                 Label__c, Parent_Page__c, Type__c, Version__c
                                          FROM FormPage__mdt
                                          WHERE Parent_Page__c != null AND Version__c = :myAppInstance.Offer_Navigation_Version__c
                                          ORDER BY Display_Order__c
                                          LIMIT 100]){
            //contruct the mapping between parent and child form pages
            if(!formPageMap.containsKey(loopFormPage.Parent_Page__c)){
                formPageMap.put(loopFormPage.Parent_Page__c, new List<FormPage>());
            }
            FormPage formPageItem = new FormPage();
            formPageItem.Id = loopFormPage.Id;
            formPageItem.name = loopFormPage.MasterLabel;
            formPageItem.api_Name = loopFormPage.api_Name__c;
            formPageItem.display_Order = loopFormPage.Display_Order__c;
            formPageItem.label = loopFormPage.Label__c;
            formPageItem.parent_Page = loopFormPage.Parent_Page__c;
            formPageItem.Type = loopFormPage.Type__c;
            formPageItem.Version = loopFormPage.Version__c;
            formPageMap.get(loopFormPage.Parent_Page__c).add(formPageItem);
        }

        //Contruct the mapping between form page and form element
        Map<String, List<FormElement>> formElementMap = new Map<String, List<FormElement>>();
        for(FormElement__mdt loopFormElement : [SELECT Id, DeveloperName, MasterLabel, API_Name__c, Component_Name__c, Description__c, Display_Type__c, Form_Page__c,
                                                    Label__c, Parent_Element__c, Sort_Order__c 
                                                FROM FormElement__mdt 
                                                ORDER BY Sort_Order__c ASC
                                                LIMIT 100]){
            if(!formElementMap.containsKey(loopFormElement.Form_Page__c)){
                formElementMap.put(loopFormElement.Form_Page__c, new List<FormElement>());
            }
            FormElement loopElementItem = new FormElement();   
            loopElementItem.Id = loopFormElement.Id;      
            loopElementItem.api_Name = loopFormElement.API_Name__c;               
            loopElementItem.parent_Element = loopFormElement.Parent_Element__c;
            loopElementItem.display_Type = loopFormElement.Display_Type__c;
            loopElementItem.name = loopFormElement.MasterLabel;
            loopElementItem.label = loopFormElement.Label__c;
            loopElementItem.description = loopFormElement.Description__c;
            loopElementItem.component_Name = loopFormElement.Component_Name__c;
            loopElementItem.sort_Order = loopFormElement.Sort_Order__c;
            formElementMap.get(loopFormElement.Form_Page__c).add(loopElementItem);
        }

        //Retrieve custom metadata for form page
        List<FormPage> formPageList = new List<FormPage>();
        for(FormPage__mdt loopFormPage : [SELECT Id, DeveloperName, MasterLabel, API_Name__c, Display_Order__c,
                                                 Label__c, Parent_Page__c, Type__c, Version__c
                                          FROM FormPage__mdt
                                          WHERE Parent_Page__c = null AND Version__c = :myAppInstance.Offer_Navigation_Version__c
                                          ORDER BY Display_Order__c
                                          LIMIT 100]){

            FormPage formPageItem = new FormPage();
            formPageItem.Id = loopFormPage.Id;      
            formPageItem.name = loopFormPage.MasterLabel;
            formPageItem.api_Name = loopFormPage.api_Name__c;
            formPageItem.display_Order = loopFormPage.Display_Order__c;
            formPageItem.label = loopFormPage.Label__c;
            formPageItem.parent_Page = loopFormPage.Parent_Page__c;
            formPageItem.type = loopFormPage.Type__c;
            formPageItem.version = loopFormPage.Version__c;
            //child elements
            if(formElementMap.containsKey(loopFormPage.Id)){
                formPageItem.form_Elements = formElementMap.get(loopFormPage.Id); 
            }else{
                formPageItem.form_Elements = new List<FormElement>();
            }
            //child forms
            if(formPageMap.containsKey(loopFormPage.API_Name__c)){
                formPageItem.form_Pages = formPageMap.get(loopFormPage.API_Name__c); 
            }else{
                formPageItem.form_Pages = new List<FormPage>();
            }      
            //add to list  
            formPageList.add(formPageItem);
        }

        return formPageList;
        //return [SELECT  Id, Name, API_Name__c, Display_Order__c, Label__c, Parent_Page__c,
        //        (SELECT Id, Parent_Element__c, Display_Type__c, Name, Label__c, Description__c,
        //        Component_Name__c, Sort_Order__c, API_Name__c
        //         FROM Form_Elements__r ORDER BY Sort_Order__c asc),
        //         (SELECT Id, Name, API_Name__c, Display_Order__c, Label__c, Parent_Page__c
        //         FROM Form_Pages__r ORDER BY Display_Order__c asc)
        //        FROM Form_Page__c WHERE Parent_Page__c = null
        //        ORDER BY Display_Order__c];
    }
    
    /**
    * @description get all Form Pages 
    * Revision Shalini Mendu - 20/07/2022 - Uses Checkmarx DynamicSoqlBuilder
    * @param apiName - filter form page by API_Name__c (external field)
    * @return the list of Form_Page__c
    **/
    //@AuraEnabled(cacheable = true)
    public static List<FormPage> getFormPageList(String apiName){
        MyApp_Settings__c myAppInstance = MyApp_Settings__c.getInstance();
        Decimal navigationVersion = myAppInstance.Offer_Navigation_Version__c;
        //Contruct the mapping between parent and child form pages
        Map<String, List<FormPage>> formPageMap = new Map<String, List<FormPage>>();
        for(FormPage__mdt loopFormPage : [SELECT Id, DeveloperName, MasterLabel, API_Name__c, Display_Order__c,
                                                 Label__c, Parent_Page__c, Type__c, Version__c
                                          FROM FormPage__mdt
                                          WHERE Parent_Page__c != null AND Version__c = :myAppInstance.Offer_Navigation_Version__c
                                          ORDER BY Display_Order__c
                                          LIMIT 100]){
            //contruct the mapping between parent and child form pages
            if(!formPageMap.containsKey(loopFormPage.Parent_Page__c)){
                formPageMap.put(loopFormPage.Parent_Page__c, new List<FormPage>());
            }
            FormPage formPageItem = new FormPage();
            formPageItem.Id = loopFormPage.Id;      
            formPageItem.name = loopFormPage.MasterLabel;
            formPageItem.api_Name = loopFormPage.api_Name__c;
            formPageItem.display_Order = loopFormPage.Display_Order__c;
            formPageItem.label = loopFormPage.Label__c;
            formPageItem.parent_Page = loopFormPage.Parent_Page__c;
            formPageItem.type = loopFormPage.Type__c;
            formPageItem.version = loopFormPage.Version__c;
            formPageMap.get(loopFormPage.Parent_Page__c).add(formPageItem);
        }       

        //Contruct the mapping between form page and form element
        Map<String, List<FormElement>> formElementMap = new Map<String, List<FormElement>>();
        for(FormElement__mdt loopFormElement : [SELECT Id, DeveloperName, MasterLabel, API_Name__c, Component_Name__c, Description__c, Display_Type__c, Form_Page__c,
                                                    Label__c, Parent_Element__c, Sort_Order__c 
                                                FROM FormElement__mdt 
                                                WHERE Parent_Element__c = null 
                                                ORDER BY Sort_Order__c ASC
                                                LIMIT 100]){
            if(!formElementMap.containsKey(loopFormElement.Form_Page__c)){
                formElementMap.put(loopFormElement.Form_Page__c, new List<FormElement>());
            }
            FormElement loopElementItem = new FormElement();  
            loopElementItem.Id = loopFormElement.Id;             
            loopElementItem.api_Name = loopFormElement.API_Name__c;               
            loopElementItem.parent_Element = loopFormElement.Parent_Element__c;
            loopElementItem.display_Type = loopFormElement.Display_Type__c;
            loopElementItem.name = loopFormElement.MasterLabel;
            loopElementItem.label = loopFormElement.Label__c;
            loopElementItem.description = loopFormElement.Description__c;
            loopElementItem.component_Name = loopFormElement.Component_Name__c;
            loopElementItem.sort_Order = loopFormElement.Sort_Order__c;
            formElementMap.get(loopFormElement.Form_Page__c).add(loopElementItem);
        }

        //Retrieve custom metadata for form page
        String strWhereClause = ' Version__c =:navigationVersion  ORDER BY Display_Order__c LIMIT 100';
        if(!String.isEmpty(apiName)){
            strWhereClause = ' Version__c = :navigationVersion AND API_Name__c = :apiName  ORDER BY Display_Order__c LIMIT 100';
        }

        String dynamicSearchQuery = DynamicSoqlBuilder.getInstance()
        .showSOQLStatement(true)
        .setEnforced(false)
        .querySObject('FormPage__mdt')
        .queryFields(new Set<String> {'Id', 'DeveloperName', 'MasterLabel' , 'API_Name__c' ,'Display_Order__c', 'Label__c', 'Parent_Page__c', 'Type__c', 'Version__c'})
        .getQuery(strWhereClause);

        List<FormPage> formPageList = new List<FormPage>();
        for(FormPage__mdt loopFormPage : Database.query(dynamicSearchQuery)){
            FormPage formPageItem = new FormPage();
            formPageItem.Id = loopFormPage.Id;       
            formPageItem.name = loopFormPage.MasterLabel;
            formPageItem.api_Name = loopFormPage.api_Name__c;
            formPageItem.display_Order = loopFormPage.Display_Order__c;
            formPageItem.label = loopFormPage.Label__c;
            formPageItem.parent_Page = loopFormPage.Parent_Page__c;
            formPageItem.type = loopFormPage.Type__c;
            formPageItem.version = loopFormPage.Version__c;
            //child elements
            if(formElementMap.containsKey(loopFormPage.Id)){
                formPageItem.form_Elements = formElementMap.get(loopFormPage.Id); 
            }else{
                formPageItem.form_Elements = new List<FormElement>();
            }
            //child forms
            if(formPageMap.containsKey(loopFormPage.API_Name__c)){
                formPageItem.form_Pages = formPageMap.get(loopFormPage.API_Name__c); 
            }else{
                formPageItem.form_Pages = new List<FormPage>();
            }      
            //add to list  
            formPageList.add(formPageItem);
        }

        return formPageList;
        //String queryString = 'SELECT  Id, Name, API_Name__c, Display_Order__c, Label__c, Parent_Page__c,' +
        //                    'Parent_Page__r.Display_Order__c, ' +
        //                      '(SELECT Id, Parent_Element__c, Display_Type__c, Name, Label__c, Description__c, ' +
        //                      'Component_Name__c, Sort_Order__c, API_Name__c FROM Form_Elements__r ' + 
        //                      'WHERE Parent_Element__c = null ' +
        //                      'ORDER BY Sort_Order__c asc), ' +                                 
        //                      '(SELECT Id, Name, API_Name__c, Display_Order__c, Label__c, Parent_Page__c, ' +
        //                      'Parent_Page__r.Display_Order__c ' + 
        //                      'FROM Form_Pages__r ORDER BY Display_Order__c asc)' +
        //                    'FROM Form_Page__c ';
        //String filter = (!String.isEmpty(apiName) ? 'WHERE API_Name__c = \'' + apiName +'\'' : '');

        //queryString += filter + ' ORDER BY Display_Order__c';
        //System.debug('** QUERY: ' + queryString);
        //return Database.query(queryString);
    }

    /**
    * @description get all child Form Elements
    * @param parentElementId - filter form element by parent element id
    * @return the list of Form_Element__c
    **/
    //@AuraEnabled(cacheable = true)
    public static List<FormElement> getChildFormElement(String parentElementId){
        FormElement__mdt parentFormElement = new FormElement__mdt();
        if(parentElementId != ''){
            parentFormElement = [SELECT Id, API_Name__c FROM FormElement__mdt WHERE Id = :parentElementId LIMIT 1];
        }else{
            parentFormElement.API_Name__c = '';
        }
        //Retrieve FormElement Items
        List<FormElement> formElementList = new List<FormElement>();
        for(FormElement__mdt loopFormElement : [SELECT Id, DeveloperName, MasterLabel, api_Name__c, Component_Name__c, Description__c, Display_Type__c, Form_Page__c,
                                                    Label__c, Parent_Element__c, Sort_Order__c 
                                                FROM FormElement__mdt 
                                                WHERE Parent_Element__c = :parentFormElement.API_Name__c
                                                ORDER BY Sort_Order__c ASC
                                                LIMIT 100]){
            FormElement loopElementItem = new FormElement();  
            loopElementItem.Id = loopFormElement.Id;             
            loopElementItem.api_Name = loopFormElement.API_Name__c;               
            loopElementItem.parent_Element = loopFormElement.Parent_Element__c;
            loopElementItem.display_Type = loopFormElement.Display_Type__c;
            loopElementItem.name = loopFormElement.MasterLabel;
            loopElementItem.label = loopFormElement.Label__c;
            loopElementItem.description = loopFormElement.Description__c;
            loopElementItem.component_Name = loopFormElement.Component_Name__c;
            loopElementItem.sort_Order = loopFormElement.Sort_Order__c;
            formElementList.add(loopElementItem);
        }
        return formElementList;
        //return [SELECT Id, Parent_Element__c, Display_Type__c, Name, Label__c, 
        //        Component_Name__c, Sort_Order__c, API_Name__c, Description__c
        //        FROM Form_Element__c WHERE Parent_Element__c =: parentElementId
        //        ORDER BY Sort_Order__c asc];
    }

    //@AuraEnabled(cacheable = true)
    public static List<Contact> getPrimaryContact(String contactId){
        Set<Id> contactIdSet = new Set<Id>{id.valueOf(contactId)};
        return new ContactsSelector().selectById(contactIdSet); 

    }

    /**
    * @description get all Bundle product
    * @param parentElementId - filter form element by parent element id
    * @param offerId parent Quote Id
    * @return the list of wrapper class as String
    **/
    //@AuraEnabled(cacheable = true)
    public static String getBundlePageMap(String parentElementId, String offerId){
        List<ProductBundleWrapper> bundleWrapper = new List<ProductBundleWrapper>();
        Map<String, FormElement> elements = new Map<String, FormElement>();
        System.debug('** parentId: ' + parentElementId);
        for(FormElement elem: FormPageService.getChildFormElement(parentElementId)){
            System.debug('** elem: ' + elem);
            elements.put(elem.api_Name, elem);
        }
        for(SBQQ__QuoteLine__c ql: QuoteLineService.getQuoteLineBundles(offerId)){
            ProductBundleWrapper wrapper = new ProductBundleWrapper();
            wrapper.productType = (ql.Offer_Primary_Quote_Line__r.SBQQ__ProductFamily__c == 'English Course' ? 
                                        ql.Offer_Primary_Quote_Line__r.SBQQ__ProductFamily__c :
                                        ql.SBQQ__ProductCode__c);
            wrapper.quoteLine = ql;
            wrapper.element = (elements.containsKey(wrapper.productType) ? 
                                elements.get(wrapper.productType) : null);
            bundleWrapper.add(wrapper);
        }

        for(SBQQ__QuoteLine__c ql: QuoteLineService.getQuoteLineList(offerId)){
            if(ql.SBQQ__ProductFamily__c == 'Grant' || ql.SBQQ__ProductFamily__c == 'Scholarship'){
                ProductBundleWrapper wrapper = new ProductBundleWrapper();
                wrapper.productType = ql.SBQQ__ProductFamily__c;
                wrapper.quoteLine = ql;
                wrapper.element = (elements.containsKey(wrapper.productType) ? 
                                    elements.get(wrapper.productType) : null);
                bundleWrapper.add(wrapper);
            }
            
        }
        System.debug('** bundleWrapper: ' + bundleWrapper);
        return JSON.serialize(bundleWrapper);
    }

    /**
    * @description get all child line items with pricing
    * @param parentElementId - filter form element by parent element id
    * @param offerId parent Quote Id
    * @return the list of wrapper class as String
    **/
    //@AuraEnabled(cacheable = false)
    public static String getProductByIdHiddenPricing(String parentElementId, String offerId){
        List<ProductBundleWrapper> bundleWrapper = new List<ProductBundleWrapper>();
        Map<String, FormElement> elements = new Map<String, FormElement>();
        for(FormElement elem: FormPageService.getChildFormElement(parentElementId)){
            elements.put(elem.api_Name, elem);
        }
        for(SBQQ__QuoteLine__c ql: QuoteLineService.selectByIdHiddenPricing(offerId)){
            ProductBundleWrapper wrapper = new ProductBundleWrapper();
            wrapper.productType = ql.SBQQ__Product__r.Quote_Document_Group__c;
            if(ql.SBQQ__ProductFamily__c == 'Grant' || ql.SBQQ__ProductFamily__c == 'Scholarship'){
                wrapper.productType = 'Scholarship';

            }else if(ql.SBQQ__ProductFamily__c == 'English Course'){
                wrapper.productType = ql.SBQQ__ProductFamily__c;

            }
            wrapper.quoteLine = ql;
            wrapper.clauseText = ql.SBQQ__Product__r.Description;
            wrapper.element = (elements.containsKey(wrapper.productType) ? 
                                elements.get(wrapper.productType) : null);
            bundleWrapper.add(wrapper);
        }

        System.debug('** getBundlePageMap: ' + bundleWrapper);
        return JSON.serialize(bundleWrapper);
    }

    public class ProductBundleWrapper{
        public String productType;
        public String clauseText;
        public SBQQ__QuoteLine__c quoteLine;
        public FormElement element;
        public ProductBundleWrapper(){}
    }

/**
 * @description Simple class to map objects to a name value par for lightning-combobox and other LWC controls in FormPage
 */ 
    public virtual class Option
    {
        @AuraEnabled
        public string label {get; private set;}
        @AuraEnabled
        public string value {get; private set;}
        public option(string label, string value)
        {
            if(label == null || value == null)
            {
                throw new IllegalArgumentException('Null sent to constructor class: option');
            }
            this.label = label;
            this.value = value;
        }
    }

/**
 * @description Simple class to map objects to a name value par for custom lists which display both a value and a seperate price and other LWC controls in FormPage
 */ 
    public virtual class PriceOption
    {
        @AuraEnabled
        public string label {get; private set;}
        @AuraEnabled
        public decimal price {get; private set;}        
        @AuraEnabled
        public string value {get; private set;}
        @AuraEnabled
        public string description {get; private set;}
        public priceOption(string label, string value, decimal price, string description)
        {
            if(label == null || value == null || price == null)
            {
                throw new IllegalArgumentException('Null sent to constructor class: PriceOption');
            }            
            this.label = label;
            this.value = value;
            this.price = price;
            this.description = description;
        }
    }    

/**
 * @description Contains values required to modify quote and select specific quote line
 */ 
    public class HeathQuoteRequest
    {
        @AuraEnabled
        public Id healthBundleId {get; set;}
        @AuraEnabled
        public Id quoteId {get; set;}
        @AuraEnabled
        public String subStatus {get; set;}
        @AuraEnabled
        public Boolean isLocked {get; set;}
        @AuraEnabled
        public String selectedProvider {get; set;}
        @AuraEnabled
        public String selectedProviderName {get; set;}
        @AuraEnabled
        public String selectedHealthOption {get; set;}

    }

    /*
     * @description form page custom metadata wrapper
     */
    public class FormPage{
        @AuraEnabled
        public String Id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String api_Name {get; set;}
        @AuraEnabled
        public Decimal display_Order {get; set;}
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String parent_Page {get; set;}
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public Decimal version {get; set;}
        @AuraEnabled
        public List<FormElement> form_Elements {get; set;}
        @AuraEnabled
        public List<FormPage> form_Pages {get; set;}
    }

    /*
     * @description form page custom metadata wrapper
     */
    public class FormElement{
        @AuraEnabled
        public String Id {get; set;}
        @AuraEnabled
        public String api_Name {get; set;}
        @AuraEnabled
        public String parent_Element {get; set;}
        @AuraEnabled
        public String display_Type {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String description {get; set;}
        @AuraEnabled
        public String component_Name {get; set;}
        @AuraEnabled
        public Decimal sort_Order {get; set;}
    }
}