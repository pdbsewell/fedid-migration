/* eslint-disable dot-notation */
import { LightningElement, api, track, wire } from 'lwc';
import * as util from 'c/util';
import getProductByIdHiddenPricing from '@salesforce/apex/OfferLightningEnabledClass.getProductByIdHiddenPricing';
import Offer_No_Deposit_Clause from '@salesforce/label/c.Offer_No_Deposit_Clause';

export default class OfferFinancialSummary extends LightningElement {
    @api quoteClauseList;
    @api parent;
    @api content;
    @api offerRecord;
    @track quotelineItems = [];
    @track quote;
    @track urlParam;
    @track elements = [];
    @track quoteTotal = '';
    isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);


    connectedCallback()
    {
        this.reloadOfferDetails();
    }

    reloadOfferDetails()
    {
         let details = { parentElementId: this.parent.Id, offerId: this.offerRecord.Id.value};
         getProductByIdHiddenPricing(details)
         .then((data) => this.wiredFormPageList(data))
         .catch((error) => this.handleError(error));

    }
    get offerId(){
        return this.offerRecord.Id.value;
    }

    get noDepositClause()
    {
        return Offer_No_Deposit_Clause;
    }

    handleError(errorResult)
    {
        console.error(errorResult);
    }

    wiredFormPageList(data) {
        if (data) {            
            let products = JSON.parse(data);
            for(let i=0; i<products.length; i++){
                let product = products[i];
                let ql = product.quoteLine;
                if(product.element){
                    let subFamily = '';
                    let content = product.element.description;
                    let startDate = new Date(ql.Course_Start_Date__c);
                    let netTotal = util.formattedCurrency(ql.SBQQ__NetTotal__c);
                    let packageTotal = util.formattedCurrency(ql.SBQQ__PackageTotal__c);
    
                    ql.SBQQ__NetTotal__c = netTotal;
                    ql.SBQQ__PackageTotal__c = packageTotal;
                    this.quoteTotal = util.formattedCurrency(ql.SBQQ__Quote__r.Net_Deposit__c);
                    ql['showPackageTotal'] = product.productType === 'BUNDIP';
                    ql['isScholarship'] = product.productType === 'Scholarship';
                    ql['isAdminFee'] = product.productType === 'Admin Fee';
                    ql['showNetTotal'] = true;//!ql['showPackageTotal'] && !ql['isScholarship'];
                    ql['showDeposit'] = !ql['isAdminFee'] && !ql['isScholarship'];
                    ql['showNoDepositClause'] = ql.SBQQ__NetTotal__c === "0" && product.productType === 'BUNUNI';

                    content = util.replaceAllString(content, '#COURSE_TITLE#', ql.Course_Title__c);
                    content = util.replaceAllString(content, '#COURSE_CODE#', ql.Course_Code__c);
                    content = util.replaceAllString(content, '#LOCATION#', ql.Location__c);
                    content = util.replaceAllString(content, '#DURATION_FT#', ql.Course_Duration__c);
                    content = util.replaceAllString(content, '#ANNUAL_LOAD#', ql.Standard_Course_Point_Annual_Load__c);
                    content = util.replaceAllString(content, '#PRODUCT_NAME#', ql.SBQQ__ProductName__c);
                    content = util.replaceAllString(content, '#CLAUSE_TEXT#', product.clauseText);
                    content = util.replaceAllString(content, '#START_DATE#', (ql.Course_Start_Date__c ? util.dateFormatted(startDate) : '') );
                    content = util.replaceAllString(content, '#LIST_TOTAL#', util.formattedCurrency(ql.SBQQ__ListTotal__c));
                    content = util.replaceAllString(content, '#PACKAGE_LIST_TOTAL#', util.formattedCurrency(ql.SBQQ__PackageListTotal__c));
                    content = util.replaceAllString(content, '#UPDATED_COURSE_DURATION#', ql.Course_Duration_Updated__c);
                    content = util.replaceAllString(content, '#NET_TOTAL_TUITION#', util.formattedCurrency(ql.Net_Total_Tuition_Fee__c));
                    content = util.replaceAllString(content, '#VALUE_DEDUCTABLE#', util.formattedCurrency( ql.Value_Deductable__c)); 
                    content = util.replaceAllString(content, '#GRANT_VALUE_CLASS#', ql.Value_Deductable__c <= 0 ? 'hide-content' : ''); 
                    product.quoteLine['hasDeductable'] = (ql.Value_Deductable__c != 0);
                    if(ql.SBQQ__Product__r.Sub_Family__c === 'FAMILY'){
                        subFamily = 'Multi Family';
                    }else if(ql.SBQQ__Product__r.Sub_Family__c === 'FAMILY-DUA'){
                        subFamily = 'Dual Family';
                    }else if(ql.SBQQ__Product__r.Sub_Family__c === 'SINGLE'){
                        subFamily = 'Single';
                    }

                    if(ql.Application_Course_Preference__c){
                        if(ql.Application_Course_Preference__r.Approved_Credit_Points__c){               
                            content = util.replaceAllString(content, '#NO_RPL_STYLE#', 'none');  
                            content = util.replaceAllString(content, '#WITH_RPL_STYLE#', 'contents'); 
                        }else{
                            content = util.replaceAllString(content, '#NO_RPL_STYLE#', 'contents');  
                            content = util.replaceAllString(content, '#WITH_RPL_STYLE#', 'none');  
                        }
                        
                    }else{
                        content = util.replaceAllString(content, '#NO_RPL_STYLE#', 'contents');  
                        content = util.replaceAllString(content, '#WITH_RPL_STYLE#', 'none');  
                    }

                    content = util.replaceAllString(content, '#SUB_FAMILY#', subFamily);
                    product.element.description = content; 
                    this.quotelineItems.push(product);
                }
                
            }

            console.log('elements', this.quotelineItems);
        } 
    
    }

    get hasRendered(){
        return this.offerRecord && this.quotelineItems;
    }
}