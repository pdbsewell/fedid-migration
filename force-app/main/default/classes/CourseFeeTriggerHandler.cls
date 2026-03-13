/**
* @author David Browaeys
* @date 29/10/2019
* @group SF Offer
* @description Service class for course fee custom object
*/
public inherited sharing class CourseFeeTriggerHandler {
    /**
    * @author David Browaeys
    * @date 29/10/2019
    * @group SF Offer
    * @description this class sync course fee with product and pricebook entry 
    */
    public inherited sharing class ProductSync extends TriggerAbstract{
        public Map<String,String> errorsByCourseFee = new Map<String,String>();
        Map<ID,Course__c> courses;
        Map<String,Course__c> unitSets;
        Map<String,Product2> products;
        Map<String,Product2> productBundles;
        Map<String, String> feeCatMappings;
        Map<String,PricebookEntry> pbeToInsert;
        Map<String,PricebookEntry> stdPBEToInsert;
        Map<String,PricebookEntry> pbeToUpdate;
        String stdPricebookId; 
        /**
        * @description this method evaluate on insert if record can be processed or not
        * @author David Browaeys
        * @param rec record to evaluate
        * @return void
        */
        public override void process (SObject rec){
            process(rec,null);
        }
        /**
        * @description this method evaluate on update if record can be processed or not
        * @author David Browaeys
        * @param rec record to evaluate
        * @param rec previous state of the record
        * @return void
        */
        public override void process (SObject rec, SObject oldRec){
            Course_Fee__c record = (Course_Fee__c) rec, oldRecord = (Course_Fee__c) oldRec;
            if (String.isBlank(record.Course_Code__c) == false && String.isBlank(record.Fee_Category__c)== false){
                records.add(record);
            }
        }
        public String getProductKey(Course_Fee__c c){
            return  c.Course_Code__c + (c.Unit_Set_Code__c != null ? ('_' + c.Unit_Set_Code__c) : '');
        }
        /**
        * @description This method sync course fee with product2 and pricebook entries bases on well defined business rules. 
        * @author David Browaeys
        * @return void
        */
        public override void execute(){
            this.stdPricebookId = ProductsSelector.getStandardPricebook();
            this.products = new Map<String, Product2>();
            this.courses = new Map<ID, Course__c>();
            this.unitSets = new Map<String, Course__c>();
            for (Course_Fee__c c :(Course_Fee__c[]) records){
                String key = getProductKey(c);
                this.products.put(key, null);
                this.courses.put(c.Course__c, null);
                if (c.Unit_Set_Code__c != null){
                    unitSets.put(c.Unit_Set_Code__c, null);
                }
            }
            //load master objects
            this.feeCatMappings = getFeeCategoryMappings();
            System.debug(products);

            this.products 	= new ProductsSelector().selectProductByExternalId(products.keySet(), Product2.External_ID__c);
            this.productBundles = new ProductsSelector().selectProductByExternalId(new Set<string>(Constants.BUNDLE_PRODUCT_EXTERNAL_IDS), Product2.External_ID__c);
            this.courses 	= new CoursesSelector().selectMapById(courses.keySet());
            this.unitSets 	= new CoursesSelector().selectCourseByExternalId(unitSets.keySet(), Course__c.Name);
            this.pbeToUpdate = new PriceBookEntriesSelector().selectPricebookEntriesByExternalId(products.keySet());
            this.pbeToInsert = new Map<String,PricebookEntry>();
            this.stdPBEToInsert = new Map<String,PricebookEntry>();
			//process each course fee
            for (Course_Fee__c c : (Course_Fee__c[]) records){
                c.Sync_Message__c = Constants.COURSEFEE_SYNCINPROGRESS;
                createProduct(c);
            }
            //commit all to database
            commitAll();
        }
        private void commitAll(){
			//upsert product & log errors if any
            Product2[] productToUpsert = this.products.values();

            if (productToUpsert != null && productToUpsert.isEmpty() == false){
                handleDmlUpsertResults(Database.upsert(productToUpsert, Product2.External_ID__c, false),productToUpsert, 'Product2','Course Fee To Course Product Sync');
            }
            //upsert pricebook & log errors if any. Using upsert rather than insert so we can use product ext id 
            if (this.stdPBEToInsert != null && this.stdPBEToInsert.isEmpty() == false){
                PricebookEntry[] t = this.stdPBEToInsert.values();
                handleDmlUpsertResults(Database.upsert(t, false),t, 'PricebookEntry','Course Fee To Course Product Sync');
            }
            //upsert pricebook & log errors if any. Using upsert rather than insert so we can use product ext id 
            if (this.pbeToInsert != null && this.pbeToInsert.isEmpty() == false){
                PricebookEntry[] t = this.pbeToInsert.values();
                handleDmlUpsertResults(Database.upsert(t, false),t, 'PricebookEntry','Course Fee To Course Product Sync');
            }
			//upsert pricebook & log errors if any
            if (this.pbeToUpdate != null && this.pbeToUpdate.isEmpty() == false){
                PricebookEntry[] t = this.pbeToUpdate.values();
                handleDmlSaveResults(Database.update(t, false),t, 'PricebookEntry','Course Fee To Course Product Sync');
            }
            //enhance course fee with product id
            for (Course_Fee__c c : (Course_Fee__c[]) records){
                String key = getProductKey(c);
                if (this.products.get(key) != null){
	                c.Product__c = this.products.get(key).Id;
                }
                if (c.Sync_Message__c == Constants.COURSEFEE_SYNCINPROGRESS){   //all good so far
                    String errors = '';
                    if (errorsByCourseFee.get(key) != null) {   //any issue on product upsert ? 
                        errors += errorsByCourseFee.get(key);
                    }
                    if (errorsByCourseFee.get(key+'_'+c.Fee_Category__c) != null) {  //any issue on pricebook upsert ? 
                        errors += errorsByCourseFee.get(key+'_'+c.Fee_Category__c);
                    }
                    if (String.isBlank(errors) == true){    //still all good ? 
                        c.Sync_Message__c = Constants.COURSEFEE_SYNCCOMPLETED;
                    }else{  //oops :-( 
                        c.Sync_Message__c = errors;
                    }
                }
                System.debug(c.Sync_Message__c);
            }
        }
        /**
         * @description This method handles save results for course product sync
         * @param  results     list of save results
         * @param  record      list of records to insert/update
         * @param  objectName  Name of the object
         * @param  processName Name of the process
         */
        public void handleDmlSaveResults(Database.SaveResult[] results, SObject[] t, String objectName, String processName){
            for (Integer i = 0 ; i < t.size (); i++){
                if (results[i].isSuccess() == false) handleErrors(results[i].getErrors(), t[i], objectName, processName);
            }
        }
        /**
         * @description This method handles upsert results for course product sync
         * @param  results     list of upsert results
         * @param  record      list of records to insert/update
         * @param  objectName  Name of the object
         * @param  processName Name of the process
         */
        public void handleDmlUpsertResults(Database.UpsertResult[] results, SObject[] t, String objectName, String processName){
            for (Integer i = 0 ; i < t.size (); i++){
                if (results[i].isSuccess() == false) handleErrors(results[i].getErrors(), t[i], objectName, processName);
            }
        }
        /**
         * @description This method handles dml error for course product sync
         * @param  errors      list of error for a record
         * @param  record      record inserted/updated
         * @param  objectName  Name of the object
         * @param  processName Name of the process
         */
        public void handleErrors(Database.Error[] errors, SObject record, String objectName, String processName){
            LogUtilityException.addLogEvent(objectName,record,errors,processName);
            for (Database.Error e : errors){
                    String error = errorsByCourseFee.get((String)record.get('External_ID__c'));
                    if (error == null) error = '';
                    error += e.getMessage() + '\n';
                    errorsByCourseFee.put((String)record.get('External_ID__c'), error);
            }
        }
        /**
        * @description This method process a single course fee and convert it to a product2 and pricebook entry
        * @author David Browaeys
        * @param c course fee to process
        * @return void
        */
        private void createProduct(Course_Fee__c c){
            try{
                Course__c course = this.courses.get(c.Course__c);
                Course__c unitSet = c.Unit_Set_Code__c != null ? this.unitSets.get(c.Unit_Set_Code__c) : null;
                String key = getProductKey(c);
                if (this.feeCatMappings.get(c.Fee_Category__c) == null){
                    throw new LogUtilityException('No pricebook found for this particular Fee Category : '+c.Fee_Category__c);
                }
                Product2 p;
                if ( (p = this.products.get(key)) == null){
                    p = new Product2(
                        RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get(Constants.PRODUCT2_OFFER).getRecordTypeId(),
                        External_ID__c = key,
                        ProductCode = key, 
                        Family = c.Product_Family__c,
                		isActive = true,
                        CurrencyIsoCode = c.CurrencyIsoCode,
                        Product_Review_Required__c = true
                    );
                }
                //if no existing std price book entry, then create new and add to upsert map
                //no need to update std pricebook (always zero)
                //Indonesia offers - Add currency to the concatenation to create a new STD price book for MI_DOM opportunities
                String keyStr = key + Constants.STD_PRICE_BOOK_DELIMITER;
                 if( c.CurrencyIsoCode!=Constants.AUD_CURRENCY) 
                 {
                    keyStr = key + Constants.STD_PRICE_BOOK_DELIMITER+'_'+c.CurrencyIsoCode;
                 }

                if (this.pbeToUpdate.get(keyStr) == null){    
                    PricebookEntry stdPBE = new PricebookEntry(
                        isActive = true,
                        CurrencyIsoCode = c.CurrencyIsoCode,
                        External_ID__c = c.CurrencyIsoCode!=Constants.AUD_CURRENCY?( key + Constants.STD_PRICE_BOOK_DELIMITER+'_'+c.CurrencyIsoCode): (key + Constants.STD_PRICE_BOOK_DELIMITER),
                        Product2 = new Product2(External_ID__c = key),
                        Pricebook2Id = stdPricebookId,
                        Unitprice = 0
                    );
                    this.stdPBEToInsert.put(stdPBE.External_ID__c, stdPBE);
                }
                //sync other product fields
                p.Course__c = course.Id;
                p.Course_Code__c = c.Course_Code__c;
                p.Unit_Set__r = unitSet;
                p.Unit_Set_Code__c = c.Unit_Set_Code__c;                
                p.Sub_Family__c = c.Product_Sub_Family__c;
                p.Product_Bundle__c = productBundles.get(c.Product_Bundle__c).Id;
                p.Dynamic_Product_Option_Filter__c = c.Product_Bundle__c;

                p.Name = unitSet != null ? unitSet.Title__c : course.Title__c;
                //create pricebook for respective fee category where External ID is a combination of product ext id and pricebook ext id
                //add currencycode mapped from Course_Fee
                PricebookEntry pbe;
                if ( (pbe = this.pbeToUpdate.get(key + '_' + feeCatMappings.get(c.Fee_Category__c))) == null) { //if no existing price book entry, then create new and add to insert map
                    pbe = new PricebookEntry(
                        isActive = true,
                        CurrencyIsoCode = c.CurrencyIsoCode,
                        External_ID__c = key + '_' + feeCatMappings.get(c.Fee_Category__c),
                        Product2 = new Product2(External_ID__c = key),
                        Pricebook2Id = c.Pricebook__c, 
                        Unitprice = c.Base_Total_Course_Fee__c
                    );
                    this.pbeToInsert.put(pbe.External_ID__c, pbe);
                }else{  //if exist only update unit price
                    pbe.Unitprice = c.Base_Total_Course_Fee__c;
                }
                this.products.put(key, p);
            }catch(Exception err){ //log event for unexpected exception
                c.addError('Course Product Error - Something went wrong to create product and price book entry for this course : ' + err.getMessage());
                LogUtilityException.addLogEvent('Course_Fee__c',c,err.getMessage(),'Course Fee To Course Product Sync');
            }
        }
        private Map<String, String> getFeeCategoryMappings(){
            Map<String, String> tmp = new Map<String, String>();
            for (Fee_Category_Pricebook_Mapping__mdt mdt : [SELECT Id, DeveloperName, Pricebook_External_ID__c FROM Fee_Category_Pricebook_Mapping__mdt]){
                tmp.put(mdt.DeveloperName, mdt.Pricebook_External_ID__c);
            }
            System.debug('tmp=='+tmp);
            return tmp;
        }
    }

    public class ProductOptionCreate extends TriggerAbstract
    {
        //Map<Id,SBQQ__Quote__c> old = new Map<Id,SBQQ__Quote__c>();
        Set<Course_Fee__c> impactedRecords = new Set<Course_Fee__c>();
        public override void process(SObject rec){
            process(rec,null);
        }
        public override void process(SObject rec, SObject oldRec) {
            Course_Fee__c currentRecord = (Course_Fee__c) rec;
            if(String.isNotBlank( currentRecord.Product_Options__c ) == true) {
                impactedRecords.add(currentRecord);
            }
        }
        public override void execute() 
        {
            String[] externalIds = null;
            Map<String,SBQQ__ProductOption__c> poList = new Map<String,SBQQ__ProductOption__c>();
            for(Course_Fee__c rec : impactedRecords){
                try{
                    externalIds = rec.Product_Options__c.split(';');
                    for(String externalId : externalIds){
                        poList.put(externalId, createProductOption(externalId));
                    }
                }catch(Exception e){
                    rec.addError('DIPLOMA ERROR - Something went wrong to create diploma bundle: \n'+e.getMessage());
                }
            }
            List<SBQQ__ProductOption__c> t = poList.values();
            Database.UpsertResult[] result = Database.upsert(t, SBQQ__ProductOption__c.External_Id__c, false );
            for (Integer i = 0 ; i < t.size (); i++){
                if (result[i].isSuccess() == false){
                    LogUtilityException.addLogEvent('SBQQ__ProductOption__c',t[i],result[i].getErrors(),'Diploma Product Option Sync');
                }
            }
            LogUtilityException.publishAll();
        }    
    }  
    @TestVisible static SBQQ__ProductOption__c createProductOption(String externalId){
        if (externalId.contains(':') == false) throw new IllegalArgumentException('Dependency should have the following format : <coursecode>_<unitsetcodepart1>:<coursecode>_<unitsetcodepart2>');

        String[] POexternalIds = externalId.split(':');
        SBQQ__ProductOption__c newPO = new SBQQ__ProductOption__c();
        newPO.SBQQ__ConfiguredSKU__r = new PRoduct2(External_Id__c = POexternalIds[0]);
        newPO.SBQQ__OptionalSKU__r = new PRoduct2(External_Id__c = POexternalIds[1]);
        newPO.External_Id__c = externalId;
        newPO.SBQQ__Number__c = 10;
        newPO.SBQQ__Quantity__c = 1;
        newPO.SBQQ__Selected__c = true;
        newPO.SBQQ__Required__c = true;
        newPO.SBQQ__Bundled__c = false;
        newPO.SBQQ__System__c = true;
        return newPO;
    }
}