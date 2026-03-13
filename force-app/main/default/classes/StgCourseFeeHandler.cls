/**
 * @author          David Browaeys
 * @description     Trigger class to delegate trigger logic to services class
 * @revision        02/09/2019 - David browaseys - Initial version
 */
public inherited sharing class StgCourseFeeHandler {
    /**
    * @author David Browaeys
    * @date 07/11/2019
    * @group SF offer
    * @description This class transform a stg course fee fed by Callista via mulesoft into Course Fee base on some defind business rules. 
    */
    public inherited sharing class CourseFeeGenerator extends TriggerAbstract{
        Map<String,OrgUnitBundleMapping__c>  orgUnitMap;
        Map<String,Fee_Category_Pricebook_Mapping__mdt> feeCatMappings;
        Map<String,String> pricebooks;
        Map<String,Course_Duration__c[]> courseDurations;
        Map<String,Course_Fee__c> courseFees;
        /**
        * @description Filter out record for insert 
        * @author David Browaeys
        * @param rec New record to evaluate
        * @return void
        */
        public override void process(SObject rec){
            process(rec,null);
        }
        /**
        * @description Filter out record for update
        * @author David Browaeys
        * @param rec New record to evaluate
        * @param rec Old record to evaluate
        * @return void
        * @example 
        */
        public override void process(SObject rec, SObject oldRec){
            Stg_Course_Fee__c record = (Stg_Course_Fee__c) rec;
            Stg_Course_Fee__c old = (Stg_Course_Fee__c) oldRec;
            if (record.Sync_Status__c == 'RESYNC' || (record.Sync_Status__c == 'NOT SYNC' && (old == null ||
                old.Sync_Status__c == 'ERROR' ||                                        
                record.Year_One_Fee__c != old.Year_One_Fee__c ||
                record.Standard_Course_Point_Annual_Load__c != old.Standard_Course_Point_Annual_Load__c  ||
                record.Course_Deposit_Amount__c != old.Course_Deposit_Amount__c ||
                record.Base_Total_Course_Fee__c != old.Base_Total_Course_Fee__c || 
                record.Course_Status__c != old.Course_Status__c ||
                record.Fee_Band_Course_Fee__c != old.Fee_Band_Course_Fee__c ||
                record.Fee_Band_Code__c != old.Fee_Band_Code__c || 
                record.Fee_Category__c != old.Fee_Category__c
            ))){
                records.add(rec);
            }else if (record.Sync_Status__c == 'NOT SYNC') {    //no sync required, can I update record without adding to records list? 
                record.Sync_Status__c = 'SYNC';
            }
        }
        /**
        * @description This method kick off the transformation.
        * @author David Browaeys
        * @return void
        */
        public override void execute(){
            init();

            if (this.loadTransformationData() == true){	

                for (Stg_Course_Fee__c stg : (Stg_Course_Fee__c[])records){
                    handleStgCourseFee(stg);

                }
                commitAll();
            }
            LogUtilityException.publishAll();
        }
        /**
        * @description Initialise all variables before loading transformation data.
        * @author David Browaeys
        * @return void
        */
        private void init(){
            this.courseFees = new Map<String,Course_Fee__c>();
            this.courseDurations = new Map<String,Course_Duration__c[]>();
            for (Stg_Course_Fee__c stg : (Stg_Course_Fee__c[])records){
                courseDurations.put(stg.Course_Code__c, new Course_Duration__c[0]);
            }
        }
        /**
        * @description Load all transformation data such as feeband vs unitset mapping, pricebooks, fee cat pricebook mapping
        * @author David Browaeys
        * @return Boolean
        */
        public Boolean loadTransformationData(){
            try{
                getCourseDurations();
                getPricebooks();
                this.orgUnitMap = (Map<String,OrgUnitBundleMapping__c>) CustomMetadataService.getAll(OrgUnitBundleMapping__c.sObjectType, OrgUnitBundleMapping__c.Org_Unit_Code__c);
                this.feeCatMappings = (Map<String,Fee_Category_Pricebook_Mapping__mdt>) CustomMetadataService.getAll(Fee_Category_Pricebook_Mapping__mdt.sObjectType);
                return true;
            }catch(Exception e){
                LogUtilityException.addLogEvent('Stg_Course_Fee__c','',e.getMessage(),'Stg Course Fee Transformation');
            }
            return false;
        }
        /**
        * @description Retrieve all course duration overwrite base on course code (i.e.: Monash English)
        * @author David Browaeys
        * @return void
        */
        //TODO : move to selector layer
        private void getCourseDurations(){
            for (Course_Duration__c rec : [SELECT ID, Course_Code__c, Unit_Set_Code__c, Duration__c FROM Course_Duration__c WHERE Course_Code__c IN: courseDurations.keySet()]){
                courseDurations.get(rec.Course_Code__c).add(rec);
            }
        }
        /**
        * @description Retrieve all active price books. 
        * @author David Browaeys
        * @return void
        */
        //TODO : move to selector layer
        private void getPricebooks(){
            this.pricebooks = new Map<String, String>();
            for (Pricebook2 pb : [SELECT Id, External_ID__c, isStandard FROM Pricebook2 WHERE isActive = true AND isStandard = false]){
                pricebooks.put(pb.External_ID__c, pb.id);
            }
        }
        /**
        * @description This method process a single stg course fee transformation
        * @author David Browaeys
        * @param stg Course Fee to transform
        * @return void
        */
        private void handleStgCourseFee(Stg_Course_Fee__c stg){
            stg.Sync_Message__c = '';
            try{//validate we have all the right information
                if (stg.Responsible_Org_Unit_Code__c == null) {//do we have a org unit code bundle ? 
                    throw new LogUtilityException('The following fields are mandatory: Responsible_Org_Unit_Code__c,');
                }
                OrgUnitBundleMapping__c orgUnit;
                if (stg.Unit_Set_Code__c != null && orgUnitMap.get(stg.Responsible_Org_Unit_Code__c + '_' + stg.Course_Code__c + '_' + stg.Unit_Set_Code__c) != null){   //test with org unit code + course code (i.e.: Monash English)
                    orgUnit = orgUnitMap.get(stg.Responsible_Org_Unit_Code__c + '_' + stg.Course_Code__c + '_' + stg.Unit_Set_Code__c);
                } else if (stg.Unit_Set_Code__c != null && orgUnitMap.get(stg.Responsible_Org_Unit_Code__c + '_' + stg.Unit_Set_Code__c) != null){   //test with org unit code + course code (i.e.: Monash English)
                    orgUnit = orgUnitMap.get(stg.Responsible_Org_Unit_Code__c + '_' + stg.Unit_Set_Code__c);
                } else if (orgUnitMap.get(stg.Responsible_Org_Unit_Code__c + '_' + stg.Course_Code__c) != null){   //test with org unit code + course code (i.e.: Monash English)
                    orgUnit = orgUnitMap.get(stg.Responsible_Org_Unit_Code__c + '_' + stg.Course_Code__c);
                }else if (orgUnitMap.get(stg.Responsible_Org_Unit_Code__c ) != null){   //test with org unit code only (most of the cases)
                    orgUnit = orgUnitMap.get(stg.Responsible_Org_Unit_Code__c);
                }else{  //ooops, not found 
                    throw new LogUtilityException('The speficied org unit code do not have a matching product bundle.');
                }
                // dispatch to right transformation
                switch on orgUnit.Product_Bundle__c {
                    when 'BUNUNI' , 'BUNCOL' , 'BUNDIP', 'BUNFOU' {
                        processDefault(stg, orgUnit);
                    }when 'BUNENG', 'BUNIAP','BUNMEC'{
                        processByCourseDurations(stg, orgUnit);
                    }when else {    //oops no process found for this product bundle 
                        throw new LogutilityException('Product Bundle not defined for this org unit code.');
                    }
                }
                //yeah, everything went well
                stg.Sync_Status__c = 'SYNC';
                stg.Sync_Message__c = 'SUCCESSFUL';
            }catch(LogutilityException e){//oops, something went wrong
                stg.Sync_Status__c = 'ERROR';
                stg.Sync_Message__c = e.getMessage();
            }catch(Exception e){ //oops, something went really wrong
                LogutilityException.logException(e,stg);
                LogUtilityException.addLogEvent('Stg_Course_Fee__c',stg,e.getLineNumber()+'::'+e.getStackTraceString(),'Stg Course Fee Transformation');
                stg.Sync_Status__c = 'ERROR';
                stg.Sync_Message__c = e.getMessage();
            }  
        }
        /**
        * @description Set price book on course fee base on fee category
        * @author David Browaeys
        * @param fee transformed fee
        * @param stg fee to transform
        * @return void
        */
        private void setPricebook(Course_Fee__c fee, Stg_Course_Fee__c stg){
            if (this.feeCatMappings.get(stg.Fee_Category__c) == null){
                throw new LogUtilityException('No fee category mapping found : '+stg.Fee_Category__c);
            }
            if (this.pricebooks.get(this.feeCatMappings.get(stg.Fee_Category__c).Pricebook_External_ID__c) == null) {
                throw new LogUtilityException('No pricebook found for this particular Fee Category : '+stg.Fee_Category__c);
            }
            fee.Pricebook__c = this.pricebooks.get(this.feeCatMappings.get(stg.Fee_Category__c).Pricebook_External_ID__c);
        }
        /**
        * @description Transform base on fee band code. Should be a 1 to 1 transformation but code allow for 1 to many. 
        * @author David Browaeys
        * @param fee transformed fee
        * @param stg fee to transform
        * @param bundle api name of the product bundle
        * @return void
        */
        private void processDefault(Stg_Course_Fee__c stg, OrgUnitBundleMapping__c bundle){
            Course_Fee__c fee = newCourseFee(stg, bundle);
            this.setPricebook(fee,stg);
            if (stg.Unit_Set_Code__c != null) {
                fee.Unit_Set_Code__c = stg.Unit_Set_Code__c;
                fee.Product_Options__c = bundle.Product_Options__c;
                fee.Product_Sub_Family__c = bundle.Product_Sub_Family__c;

                fee.Unit_Set_Version__c = Integer.valueOf(stg.Unit_Set_Version__c);
                fee.Unit_Set__r = new Course__c(Course_Code__c = stg.Unit_Set_Code__c + '_'+ stg.Unit_Set_Version__c);
                fee.External_ID__c = stg.Course_Code__c+'_'+stg.Course_Version__c +'_'+fee.Fee_Category__c+'_'+stg.Unit_Set_Code__c + '_'+ stg.Unit_Set_Version__c+'_'+(Integer)fee.Fee_Band_Code_Year__c;
            }else{
            	fee.External_ID__c = stg.Course_Code__c+'_'+stg.Course_Version__c +'_'+fee.Fee_Category__c+'_'+(Integer)fee.Fee_Band_Code_Year__c;
            }
            fee.Name = fee.External_ID__c;
            courseFees.put(fee.External_ID__c, fee);
        }
        /**
        * @description Transform base on course durations
        * @author David Browaeys
        * @param fee transformed fee
        * @param stg fee to transform
        * @param bundle api name of the product bundle
        * @return void
        */
        private void processByCourseDurations(Stg_Course_Fee__c stg, OrgUnitBundleMapping__c bundle){
            Course_Fee__c fee = newCourseFee(stg, bundle);
            this.setPricebook(fee,stg);
            Boolean isValid = false;
            if (courseDurations.get(stg.Course_Code__c) != null && courseDurations.get(stg.Course_Code__c).isEmpty() == false) {
                for (Course_Duration__c duration : courseDurations.get(stg.Course_Code__c) ){
                    Course_Fee__c f = fee.clone(false, false);
                    f.Unit_Set_Code__c = duration.Unit_Set_Code__c;
                    f.External_ID__c = stg.Course_Code__c+'_'+stg.Course_Version__c+'_'+f.Unit_Set_Code__c+'_'+f.Fee_Category__c+'_'+(Integer)f.Fee_Band_Code_Year__c;
                    f.Name = f.External_ID__c;
                    f.Base_Total_Course_Fee__c = stg.Base_Total_Course_Fee__c / stg.Standard_Course_Point_Annual_Load__c * duration.Duration__c;
                    f.Course_Deposit_Amount__c = f.Base_Total_Course_Fee__c;  
                    f.Year_One_Fee__c = stg.Year_One_Fee__c / stg.Standard_Course_Point_Annual_Load__c * duration.Duration__c;
                    f.Standard_Course_Point_Annual_Load__c = duration.Duration__c;
                    //map currencycode from Currency field on Stg Course Fee
                    f.CurrencyIsoCode = stg.Currency__c;
                    courseFees.put(f.External_ID__c, f);
                    isValid = true;
                }
            }
            if (isValid == false){
                throw new LogUtilityException('No course duration records found for specified course code('+stg.Course_Code__c+') and price book('+stg.Fee_Category__c+').');
            }
        }
        /**
        * @description Create new instance of course fee and mapped basic from stg course fee.
        * @author David Browaeys
        * @param fee transformed fee
        * @param stg fee to transform
        * @return void
        */
        private Course_Fee__c newCourseFee(Stg_Course_Fee__c stg, OrgUnitBundleMapping__c bundle){
            return new Course_Fee__c(
                Product_Bundle__c = bundle.Product_Bundle__c,
                Product_Family__c = bundle.Product_Family__c,
                Course_Code__c = stg.Course_Code__c,
                Course_Code_Version__c = Integer.valueOf(stg.Course_Version__c),
                Course__r = new Course__c(Course_Code__c = stg.Course_Code__c + '_'+ stg.Course_Version__c),
                Source_ID__c = stg.External_ID__c,
                Fee_Category__c = stg.Fee_Category__c,
                CP_Required__c = stg.CP_Required__c, 
                Standard_Course_Point_Annual_Load__c = stg.Standard_Course_Point_Annual_Load__c,
                Year_One_Fee__c = stg.Year_One_Fee__c,
                Fee_Band_Code_Year__c = stg.Fee_Band_Code_Year__c,
                Base_Total_Course_Fee__c = stg.Base_Total_Course_Fee__c,
                Course_Deposit_Amount__c = stg.Course_Deposit_Amount__c, 
                Status__c = stg.Course_Status__c,
                X48_CP_FEE__c = stg.Fee_Band_Course_Fee__c,
                //map currencycode from Currency field on Stg Course Fee
                CurrencyIsoCode= stg.Currency__c
            );
        }
        /**
        * @description Commit all and upsert course fee and stg course fee
        * @author David Browaeys
        * @return void
        */
        private void commitAll(){
            Map<String, String> errorsByCourseFee = new Map<String, String>();
            Course_Fee__c[] fees = courseFees.values();
            Database.UpsertResult[] result1 = Database.upsert(fees, Course_Fee__c.External_ID__c, false);
            for (Integer i = 0 ; i < fees.size(); i++){
                if (result1[i].isSuccess() == false){ //use Source ID (as stg External ID), could have more than one error per stg course fee(i.e.: monash english)
                    LogUtilityException.addLogEvent('Course_Fee__c',fees[i],result1[i].getErrors(),'Stg Course Fee Transformation');
                    String error = errorsByCourseFee.get(fees[i].Source_ID__c) == null ? '' : errorsByCourseFee.get(fees[i].Source_ID__c);
                    
                    for (Database.Error e : result1[i].getErrors()){
                            error += e.getMessage() + '\n\n';
                    }
                    errorsByCourseFee.put(fees[i].Source_ID__c, error);
                }
            }
            for (Stg_Course_Fee__c stg : (Stg_Course_Fee__c[])records){
                if (errorsByCourseFee.get(stg.External_ID__c) != null){
                    stg.Sync_Status__c = 'ERROR';
                    stg.Sync_Message__c = errorsByCourseFee.get(stg.External_ID__c);
                }
            }
        }
    }
}