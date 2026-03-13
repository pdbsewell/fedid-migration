/* eslint-disable no-loop-func */
/* eslint-disable no-undef */
import * as util from 'c/util';
import { LightningElement, api, track, wire } from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import getBundlePageMap from '@salesforce/apex/OfferLightningEnabledClass.getBundlePageMap';

export default class Offerdetailscomponent extends LightningElement {
    @api quoteClauses;
    @api parent;
    @track productBundle;
    @track elements = [];
    @track location = 'Course notes';

    loading = true;
    
    get offerId(){
        this.urlParam = util.urlParameter(window.location.href);
        return this.urlParam.get('id');
    }

    @wire(getBundlePageMap, { parentElementId: '$parent.Id', offerId: '$offerId'})
    wiredBundlePageMap({ error, data }) {
        if (data) {
            let clauses = JSON.parse(JSON.stringify(this.quoteClauses));
            this.loading = true;
            let products = JSON.parse(data);
            for(let i=0; i<products.length; i++){
                let clauseNotes = '';
                let clauseDisplay = 'none';
                let product = products[i];
                let ql = product.quoteLine;
                let annualTuition = '';
                if(product.element){
                    let content = product.element.description;                    
                    let isGrant = (product.productType == 'Grant' || product.productType == 'Scholarship');
                    if(ql.Offer_Primary_Quote_Line__c == null && !isGrant ){
                        continue;
                    }

                    if(ql.Offer_Primary_Quote_Line__c){ 
                        if(ql.Offer_Primary_Quote_Line__r.Additional_Clause_Notes__c != undefined)
                            clauseNotes += ql.Offer_Primary_Quote_Line__r.Additional_Clause_Notes__c + '<br/><br/>';
                        clauseDisplay = (clauseNotes != undefined ? '' : 'none');
                        let startDate = new Date(ql.Offer_Primary_Quote_Line__r.Course_Start_Date__c); 
                        let endDate = new Date(ql.Offer_Primary_Quote_Line__r.Course_End_Date__c);
                        annualTuition = (ql.Offer_Primary_Quote_Line__r.Annual_Tuition_Fee__c > 0 ? 'A$ ' + util.formattedCurrency(ql.Offer_Primary_Quote_Line__r.Annual_Tuition_Fee__c) : '-')
                        console.log(content);
                        content = util.replaceAllString(content, '#COURSE_TITLE#', ql.Offer_Primary_Quote_Line__r.Course_Title__c);
                        content = util.replaceAllString(content, '#COURSE_CODE#', ' (' + ql.Offer_Primary_Quote_Line__r.Course_Code__c +')');
                        content = util.replaceAllString(content, '#COURSE_HEADER#', ql.Offer_Primary_Quote_Line__r.Course_Title__c);
                        content = content.replace('#START_DATE#', (ql.Offer_Primary_Quote_Line__r.Course_Start_Date__c ? util.dateFormatted(startDate) : '') );
                        content = content.replace('#END_DATE#', (ql.Offer_Primary_Quote_Line__r.Course_End_Date__c ? util.dateFormatted(endDate) : ''));
                        content = util.replaceAllString(content, '#LOCATION#', ql.Offer_Primary_Quote_Line__r.Location__c);
                        content = util.replaceAllString(content, '#MODE_OF_STUDY#', this.modeOfStudy(ql.Offer_Primary_Quote_Line__r.Mode_of_Study__c));
                        content = util.replaceAllString(content, '#CREDIT_POINTS_UPDATED#', ql.Offer_Primary_Quote_Line__r.Credit_Points_Required_Updated__c);
                        content = util.replaceAllString(content, '#TOTAL_TUITION_FEE#', util.formattedCurrency(ql.Offer_Primary_Quote_Line__r.Total_Tuition_Fee__c));
                        content = util.replaceAllString(content, '#ANNUAL_TUITION_FEE#', annualTuition);
                        content = util.replaceAllString(content, '#NET_TOTAL_TUITION_FEE#', util.formattedCurrency(ql.Offer_Primary_Quote_Line__r.Net_Total_Tuition_Fee__c));
                        content = util.replaceAllString(content, '#COURSE_DURATION#', ql.Offer_Primary_Quote_Line__r.Course_Duration_Updated__c);
                        content = util.replaceAllString(content, '#ANNUAL_LOAD#', ql.Offer_Primary_Quote_Line__r.Standard_Course_Point_Annual_Load__c);
                        content = util.replaceAllString(content, '#DURATION_FT#', ql.Offer_Primary_Quote_Line__r.Course_Duration__c);
                        content = util.replaceAllString(content, '#CREDIT_POINTS#', ql.Offer_Primary_Quote_Line__r.Credit_Points_Required__c);                   
                        content = util.replaceAllString(content, '#PRIMARY_SUB_FAMILY#', ql.Offer_Primary_Quote_Line__r.SBQQ__Product__r.Sub_Family__c);

                    }
                    if(ql.Offer_Option_Quote_Line__c){
                        annualTuition = (ql.Offer_Option_Quote_Line__r.Annual_Tuition_Fee__c > 0 ? 'A$ ' + util.formattedCurrency(ql.Offer_Option_Quote_Line__r.Annual_Tuition_Fee__c) : '-')
                        content = util.replaceAllString(content, '#OPTIONAL_COURSE_TITLE#', (ql.Offer_Option_Quote_Line__c ? ql.Offer_Option_Quote_Line__r.Course_Title__c : ''));
                        content = util.replaceAllString(content, '#OPTION_SUB_FAMILY#', (ql.Offer_Option_Quote_Line__c ? ql.Offer_Option_Quote_Line__r.SBQQ__Product__r.Sub_Family__c : ''));                        
                        content = util.replaceAllString(content, '#OPTION_ANNUAL_TUITION_FEE#', annualTuition);
                    }

                    let bundleStartDate = new Date(ql.Course_Start_Date__c);
                    let bundleEndDate = new Date(ql.Course_End_Date__c);      
                    let expiryDate = new Date(ql.Expiry_Date__c);  
                    product.element['SBQQ__Number__c'] = ql.SBQQ__Number__c;
                    content = content.replace('#BUNDLE_START_DATE#', (ql.Course_Start_Date__c ? util.dateFormatted(bundleStartDate) : '') );
                    content = content.replace('#BUNDLE_END_DATE#', (ql.Course_End_Date__c ? util.dateFormatted(bundleEndDate) : '')); 
                    content = util.replaceAllString(content, '#BUNDLE_LOCATION#', ql.Location__c);
                    content = util.replaceAllString(content, '#BUNDLE_MODE_OF_STUDY#', this.modeOfStudy(ql.Mode_of_Study__c));
                    content = util.replaceAllString(content, '#BUNDLE_COURSE_DURATION#', ql.Updated_Course_Duration__c);
                    content = util.replaceAllString(content, '#BUNDLE_CREDIT_POINTS_UPDATED#', ql.Credit_Points_Required_Updated__c);
                    content = util.replaceAllString(content, '#BUNDLE_TOTAL_TUITION_FEE#', util.formattedCurrency(ql.Total_Tuition_Fee__c));
                    content = util.replaceAllString(content, '#BUNDLE_NET_TOTAL_TUITION_FEE#', util.formattedCurrency(ql.Net_Total_Tuition_Fee__c));
                    content = util.replaceAllString(content, '#ADMIN_FEE#', util.formattedCurrency(ql.Admin_Fee__c));
                    content = util.replaceAllString(content, '#BUNDLE_DURATION_FT#', ql.Course_Duration__c);
                    content = util.replaceAllString(content, '#BUNDLE_CREDIT_POINTS#', ql.Credit_Points_Required__c);    
                    content = util.replaceAllString(content, '#PRODUCT_NAME#', ql.SBQQ__ProductName__c); 
                    content = util.replaceAllString(content, '#PRODUCT_FACE_VALUE#', 'A$ ' + util.formattedCurrency(ql.Total_Grant_Scholarship_Value__c)); 
                    content = util.replaceAllString(content, '#PRODUCT_CLAUSE#', ql.SBQQ__Product__r.Description); 
                    content = util.replaceAllString(content, '#QL_EXPIRY#', (ql.Expiry_Date__c ? util.dateFormatted(expiryDate) : '')); 

                    content = util.replaceAllString(content, '#GRANT_VALUE_CLASS#', ql.Total_Grant_Scholarship_Value__c <= 0 ? 'hide-content' : ''); 
                    content = util.replaceAllString(content, '#VALUE_DEDUCTIBLE#', util.formattedCurrency( ql.Value_Deductable__c)); 
                    content = util.replaceAllString(content, '#CRICOS_CODE#', ql.CRICOS_Code__c);   
                    //console.log(ql.Application_Course_Preference__r);

                    let specialisation = '';
                    let condition = '';
                    if(ql.Application_Course_Preference__r != undefined){
                        condition = ql.Application_Course_Preference__r.Offer_Condition__c;
                        
                        if(ql.Application_Course_Preference__r.Approved_Credit_Points__c){               
                            content = util.replaceAllString(content, '#NO_RPL_STYLE#', 'none');  
                            content = util.replaceAllString(content, '#WITH_RPL_STYLE#', 'block'); 
                        }else{
                            content = util.replaceAllString(content, '#NO_RPL_STYLE#', 'block');  
                            content = util.replaceAllString(content, '#WITH_RPL_STYLE#', 'none');  
                        }
                        if(ql.Application_Course_Preference__r.Unit_Set_Description__c) {
                            specialisation = ql.Application_Course_Preference__r.Unit_Set_Description__c;
                            content = util.replaceAllString(content, '#SHOW_SPECIALISATION_PROGRAM_STYLE#', 'block');  
                        } else {
                            content = util.replaceAllString(content, '#SHOW_SPECIALISATION_PROGRAM_STYLE#', 'none');  
                        }
                    }else{
                        content = util.replaceAllString(content, '#SHOW_SPECIALISATION_PROGRAM_STYLE#', 'none'); 
                        content = util.replaceAllString(content, '#NO_RPL_STYLE#', 'block');  
                        content = util.replaceAllString(content, '#WITH_RPL_STYLE#', 'none');  
                    }
                    content = util.replaceAllString(content, '#OFFER_CONDITION#', condition);
                    content = util.replaceAllString(content, '#SPECIALISATION_PROGRAM#', specialisation);

                    let courseDurationClause = '';
                    let creaditPointsClause = '';
                    let tuitionFeeClause = '';
                    if(clauses){
                        clauses.forEach(clause=>{
                            if(clause.SBQQ_QuoteLine__c == ql.Id && clause.APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Location_in_Offer__c == this.location){
                                clauseNotes += clause.APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.APXT_Redlining__Text__c;
                                clauseNotes += '<br/><br/>';
                                clauseDisplay = '';
                            }
                            if(clause.SBQQ_QuoteLine__c == ql.Id && clause.APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Location_in_Offer__c == 'Course duration'){
                                courseDurationClause += '<br/>'+ clause.APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.APXT_Redlining__Text__c + '<br/>';
                            }
                            if(clause.SBQQ_QuoteLine__c == ql.Id && clause.APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Location_in_Offer__c == 'Credit points'){
                                creaditPointsClause += '<br/>'+ clause.APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.APXT_Redlining__Text__c + '<br/>';
                            }
                            if(clause.SBQQ_QuoteLine__c == ql.Id && clause.APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Location_in_Offer__c == 'Calendar tuition fee'){
                                tuitionFeeClause += '<br/>'+ clause.APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.APXT_Redlining__Text__c + '<br/>';
                            }
                        });
                    }

                    content = content.replace('#CLAUSE_NOTES#', clauseNotes);  
                    content = content.replace('#NOTES_DISPLAY#', clauseDisplay);  
                    content = content.replace('#COURSE_DURATION_CLAUSE_NOTES#', courseDurationClause);  
                    content = content.replace('#CREDIT_POINTS_CLAUSE_NOTES#', creaditPointsClause);  
                    content = content.replace('#TUITION_FEE_CLAUSE_NOTES#', tuitionFeeClause);  
                    product.element.description = content; 
                    this.elements.push(product.element); 
                    this.loading = false;
                    this.sortData('SBQQ__Number__c', 'asc');
                }else{                    
                    this.loading = false;   
                }
            }

        } else if (error) {
            console.log('wiredQuoteLineBundles');
            util.logJson(error);
        }else{
            this.loading = false;
        }
    }

    modeOfStudy(mode){
        if(mode == 'FT'){
            return 'Full Time.';
        }else if(mode == 'PT'){
            return 'Part Time.';
        }
        return '';
    }

    sortData(fieldName, sortDirection){
        let data = JSON.parse(JSON.stringify(this.elements));
        //function to return the value stored in the field
        const key = (a) => {
            let fieldValue = a[fieldName] ? a[fieldName] : '';
           return fieldValue; 
        }
        let reverse = sortDirection === 'asc' ? 1: -1;

        //set sorted data to elements
        this.elements = data.sort((a,b) => {
            return reverse * ((key(a) > key(b)) - (key(b) > key(a)));
        });          
        
    }

    get hasRendered(){
        fireEvent(this.pageRef, 'setPageTitle', ''); 
        return this.parent && this.elements;
    }
}