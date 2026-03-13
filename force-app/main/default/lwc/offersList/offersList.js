/* eslint-disable eqeqeq */
/* eslint-disable no-unused-vars */
/* eslint-disable dot-notation */
/* eslint-disable no-empty */
/* eslint-disable vars-on-top */
import { LightningElement, track, wire } from 'lwc';
import * as util from 'c/util';
import userId from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import Offer_Summary_URL from '@salesforce/label/c.Offer_Summary_URL';
import Offer_Render_Document_URL from '@salesforce/label/c.Offer_Render_Document_URL';
import static_resource from '@salesforce/resourceUrl/admission_assets'
import getOfferList from '@salesforce/apex/OfferLightningEnabledClass.getCurrentOfferList';
import selectQuoteByContactOwner from '@salesforce/apex/OfferLightningEnabledClass.getOfferList';
import getSigningUrl from '@salesforce/apex/OfferLightningEnabledClass.getSigningUrl';

/* assets */
import offerBanners from '@salesforce/resourceUrl/OfferBanners';
export default class OffersList extends LightningElement {
    
    //banner images paths
    fullOfferBanner = offerBanners + '/FullOfferBanner.jpg';
    conditionalOfferBanner = offerBanners + '/ConditionalConditionalBanner.jpg';
    rejectedOfferBanner = offerBanners + '/RejectedOfferBanner.jpg';
    @track offers;
    @track user;
    @track contactId;
    Id = userId;
    hasOffers = false;
    feeType = '';

    loading = true;
    count = 1;
    counter = 0;
    list_size = 3;
    total_size = 0;
    display_page = 3;
    pageNumbers = [];

    courseImageUrl = '';
    grantImageUrl = '';
    warningImageUrl = '';
    backgroundImg = '';

     
    @wire(getRecord, {recordId: '$Id', fields: ['User.ContactId', 'User.Contact.Name']})
    wiredUser({error, data}){
        if(data){
            this.user = data.fields;
            this.contactId = data.fields.ContactId.value;
            loadStyle(this, static_resource + '/css/desktop-style-sheet.css');
            loadStyle(this, static_resource + '/css/mobile-style-sheet.css');

            var isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
            if(isMobile){
                this.list_size = 1;
            }
            this.getOffers(this.list_size, this.counter);
            this.initializeAssetUrl();
        }else if(error){
            util.log(error);
        }
    }

    //SET TOTAL SIZE
    @wire(selectQuoteByContactOwner, {contactId: '$contactId', ownerId: '$Id'})
    wiredSelectQuoteByContactOwner({error, data}){
        if(data){
            this.total_size = data.length;
        }else if(error){
            console.log(error);
        }
    }

    nextPage(){
        this.counter += this.list_size;
        this.getOffers(this.list_size, this.counter);
    }
    previousPage(){
        this.counter -= this.list_size;
        if(this.count ==1){
            this.count++;
        }
        this.getOffers(this.list_size, this.counter);
    }

    onPageClick = (e)=>{
        let currentPage = parseInt(e.target.dataset.id,10);
        this.counter = (currentPage > 1 ? this.list_size * (currentPage-1) : 0);
        this.getOffers(this.list_size, this.counter);
        
    }

    get disabledNext(){
        if (this.counter + this.list_size < this.total_size){
            return false;
        }
        return true;
    }

    get disablePrevious(){
        if(this.counter >0){
            return false;
        }
        return true;
    }

    get pageNumber(){
        return this.counter/this.list_size + 1;
    }

    get totalPages(){
        let mod = this.total_size % this.list_size;
        if (mod > 0) {
            return parseInt(this.total_size/this.list_size) + 1;
        }
        return (this.total_size/this.list_size);
    }

    get pageList(){
        this.pageNumbers = [];
        for(let i =1; i<=this.totalPages; i++){
            this.pageNumbers.push(i);
        }
        
        let mid = Math.floor(this.display_page/2) + 1 ;
        let pageSizeCount = Math.floor(this.totalPages/this.display_page);

        for(let i =1; i<=pageSizeCount; i++){
            if(this.pageNumber == (i*this.display_page)+1){
                return this.pageNumbers.slice(this.pageNumber-1, (this.pageNumber+mid));

            }else if(this.pageNumber <= this.display_page){
                return this.pageNumbers.slice(0,this.display_page);

            }else if(this.pageNumber == (i*this.display_page)){
                return this.pageNumbers.slice((this.pageNumber-mid)-1, this.pageNumber);            
            }
        }
        return this.pageNumbers.slice(this.pageNumber-mid, (this.pageNumber+1));

        // let mid = Math.floor(this.display_page/3) + 1 ;
        // console.log('mid', mid);
        // console.log('(this.pageNumber+mid)-1', (this.pageNumber+mid)-1);
        // if(this.pageNumber > mid){
        //     return this.pageNumbers.slice(this.pageNumber-mid, (this.pageNumber+mid)-1);
        // } 
        //return this.pageNumbers.slice(0,this.display_page);
        

    }

    renderButtons = ()=>{
        this.template.querySelectorAll('button').forEach((btn)=>{
            btn.style.backgroundColor = this.pageNumber===parseInt(btn.dataset.id,10)?'#006dae':'white';
         });
    }

    renderedCallback(){
        this.renderButtons();   
    }

    initializeAssetUrl(){
        this.courseImageUrl = static_resource + '/screen-icons/course.png';
        this.grantImageUrl = static_resource + '/screen-icons/Scholarship_icn.png';
        this.warningImageUrl = static_resource + '/screen-icons/Warning_icn.png';
        let bgImg = static_resource + '/screen-icons/Group25.jpg';
        this.backgroundImg = '--image-url: url(\''+bgImg +'\')';
    }

    getOffers(limit, offset){
        this.loading = true;
        getOfferList({contactId: this.contactId, ownerId: this.Id, limitNum: limit, offset: offset})
            .then(result => {
                    this.error = undefined;
                    var offerList = JSON.parse(JSON.stringify(result));
                    var urlString = window.location.origin;
                    for(var i =0; i< offerList.length; i++){ //offerList.length
                        let offer = offerList[i];
                        let name = offer.quote.Course_Name__c.split("-");
                        let offerType = (offer.quote.Offer_Type__c == 'COND-OFFER' ? 'Conditional Offer' : 'Full Offer');
                        let ribbonClass = (offer.quote.Offer_Type__c == 'COND-OFFER' ? 'banner-ribbon offer-cond-ribbon' : 'banner-ribbon full-offer-ribbon');
                        let startDate = new Date(offer.quote.SBQQ__StartDate__c);
                        let monthDate = util.longMonthName(startDate) + ' ' + startDate.getFullYear();
                        let location = (offer.lastQuoteLine != null ? offer.lastQuoteLine.Location__c : '');
                        
                        //set banner - full / conditional
                        offer.quote['bannerStyle'] = (offer.quote.Offer_Type__c == 'COND-OFFER' ? 
                        'background-position: bottom; background-repeat: no-repeat; background-image: url(' + this.conditionalOfferBanner +');' : 
                        'background-position: bottom; background-repeat: no-repeat; background-image: url(' + this.fullOfferBanner +');');
                        //set banner - unsuccessful
                        if(offer.quote.SBQQ__Status__c == 'Expired and regenerated' || 
                           offer.quote.SBQQ__Status__c == 'Expired' ||
                           offer.quote.SBQQ__Status__c == 'Rejected'){
                            offer.quote['bannerStyle'] = 'background-position: bottom; background-repeat: no-repeat; background-image: url(' + this.rejectedOfferBanner +');';
                        }
                        if(offer.quote.SBQQ__Status__c == 'Rejected'){
                            offerType = 'Rejected Offer';
                        }
                        if(offer.quote.SBQQ__Status__c == 'Expired'){
                            offerType = 'Expired Offer';
                        }

                        if(offer.quote.SBQQ__PriceBook__r){
                            this.feeType = (offer.quote.SBQQ__PriceBook__r.Name == 'International' 
                                        ? 'International, Full-fee' : offer.quote.SBQQ__PriceBook__r.Name);
                        }
                        offer.quote.Course_Name__c = (name.length > 1 ? name[1] : name[0]);
                        offer.quote.Offer_Type__c = offerType;
                        offer.quote['Offer_Type_text'] = (offerType === 'Full Offer' ? ' of place' : '');
                         offer.quote['ribbonClass'] = ribbonClass;
                        offer.quote.SBQQ__StartDate__c = monthDate;
                        offer['Location'] = location;
                        

                        //use quote's expiry date only when the grant/scholarship is already expired
                        let furtherExpiryDate = offer.quote.SBQQ__ExpirationDate__c;
                        if(util.getDaysbetweenDates(new Date(), offer.quote.Calculated_Expiry_Date__c) >= 0){
                            furtherExpiryDate = offer.quote.Calculated_Expiry_Date__c;
                        }

                        offer['showOfferDetail'] = true;
                        offer['customerFullName'] = '';
                        offer['showBannerText'] = true;
                        if(offer.quote.Contact_Firstname__c) {
                            offer['customerFullName'] = 'Name: ' + offer.quote.Contact_Firstname__c + ' ' + offer.quote.Contact_Lastname__c;
                        }

                        offer['expiresOn'] = util.getDaysbetweenDates(new Date(), furtherExpiryDate);
                        
                        let quoteExpiryDates = new Date(offer.quote.SBQQ__ExpirationDate__c).toLocaleDateString().split('/');
                        offer['quoteExpiryDate'] = quoteExpiryDates[0] + ' ' + util.longMonthName(new Date(quoteExpiryDates[2], quoteExpiryDates[1]-1)) + ' ' + quoteExpiryDates[2];

                        let expiryDates = new Date(furtherExpiryDate).toLocaleDateString().split('/');
                        offer['expiryDate'] = expiryDates[0] + ' ' + util.longMonthName(new Date(expiryDates[2], expiryDates[1]-1)) + ' ' + expiryDates[2];
                        offer['isExpired'] = (offer.quote.SBQQ__Status__c == 'Expired and regenerated' || 
                                                offer.quote.SBQQ__Status__c == 'Expired' ||
                                                offer.quote.SBQQ__Status__c == 'Rejected');
                        offer['offerLinks'] = this.getButtonContent(offer, urlString, static_resource);
                        offer['uploadDocLink'] = '/admissions/s/offer-acceptance?opportunityId=' + offer.quote.SBQQ__Opportunity2__c;
                        offer['isPendingParent'] = false;
                        if(offer.quote.Recipient_Signature_Status__c === 'Signed Recipient 1' && offer['isExpired'] === false && offer.quote.SBQQ__PrimaryContact__r.Under_18__c){
                            offer['isPendingParent'] = true;
                        }
                        
                        if(offer.grantQuoteLine){
                            let amount = util.formattedCurrency(offer.grantQuoteLine.Total_Grant_Scholarship_Value__c);
                            offer.grantQuoteLine['hasTotalAmount'] = (offer.grantQuoteLine.Total_Grant_Scholarship_Value__c > 0);
                            offer.grantQuoteLine.Total_Grant_Scholarship_Value__c = amount;

                            let quoteLineIsExpired = util.getDaysbetweenDates(new Date(), offer.grantQuoteLine.Expiry_Date__c)
                            offer.grantQuoteLine['IsExpired'] = false;
                            if(quoteLineIsExpired < 0){
                                offer.grantQuoteLine['IsExpired'] = true;
                            }

                            let grantExpiry = new Date(offer.grantQuoteLine.Expiry_Date__c);
                            offer.grantQuoteLine.Expiry_Date__c = util.dateFormatted(grantExpiry);
                        }
                        
                        offerList[i] = offer;
                    }
                    this.offers = offerList;
                    this.loading = false;
                    this.hasOffers = this.offers.length;
                    console.log('offers', this.offers);
            })
            .catch(error => {
                console.log(error);
            });
    }

    getButtonContent(offer, urlString, assets){
        let offerRec = {};
        offerRec['hasError'] = true;
        offerRec['signOffer'] = false;
        offerRec['offerSigned'] = false;
        offerRec['showButton'] = true;
        if(offer.quote.Sub_Status__c){
            let hasError = (offer.quote.Sub_Status__c.toLowerCase().includes('error') || offer.quote.DocuSign_Signing_URL__c == null) && offer.quote.Acknowledged_by_applicant__c;
            offerRec['hasError'] = (hasError || offer.quote.Sub_Status__c == util.timedOutSubStatus );
        }

        if(offer.quote.SBQQ__Status__c == util.publishedStatus 
            && offer.quote.Sub_Status__c == util.previesReleasedSubStatus){
            offerRec['btnText'] = 'View Offer';
            offerRec['btnLink'] = urlString  + Offer_Summary_URL + '?id=' + offer.quote.Id;
            offerRec['bannerImg'] = assets + '/screen-icons/tile1.PNG';
            offerRec['linkTarget'] = '';
        }else if((offer.quote.SBQQ__Status__c == util.publishedStatus || offer.quote.SBQQ__Status__c== util.acceptedStatus)
                && offer.quote.Sub_Status__c == util.pendingSignatureSubStatus
                && offer.quote.Primary_DocuSign_Envelop_Id__c != null){
            offerRec['btnText'] = 'Sign Offer';
            offerRec['btnLink'] = offer.quote.DocuSign_Signing_URL__c;
            offerRec['signOffer'] = true;
            offerRec['showButton'] = false;
            offerRec['bannerImg'] = assets + '/screen-icons/tile2.PNG';
            offerRec['linkTarget'] = '_blank';
        }else if((offer.quote.SBQQ__Status__c== util.acceptedStatus || offer.quote.SBQQ__Status__c== util.signedStatus)
                && offer.quote.Final_Signed_Document_Id__c != null){
            let url = window.location.href.split('admissions');
            offerRec['btnText'] = 'Download Signed Contract';
            offerRec['offerSigned'] = true;
            offerRec['btnLink'] = '../sfc/servlet.shepherd/version/download/' + offer.quote.Final_Signed_Document_Id__c;
            offerRec['bannerImg'] = assets + '/screen-icons/tile3.PNG';
            offerRec['linkTarget'] = '_document';
        } else if(offer.quote.Opportunity_Name__c.includes('-GRSS-')) {
            let attendanceType, attendanceMode
            offerRec['btnText'] = 'View Outcome';
            offerRec['btnLink'] = '/admissions/s/grscholarshipoffer?id=' + offer.quote.Id;
            offerRec['bannerImg'] = assets + '/screen-icons/tile1.PNG';
            offerRec['linkTarget'] = '_document';
            offerRec['hasError'] = false;
            offer.showBannerText = false;
            offer['isGRScholarshipOffer'] = true;

            if(offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Attendance_Type__c == 'PT') {
                attendanceType = 'Part-Time'
            } else if(offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Attendance_Type__c == 'FT'){
                attendanceType = 'Full-Time'
            } else {
                attendanceType = offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Attendance_Type__c
            }

            if(offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Attendance_Mode__c == 'IN') {
                attendanceMode = 'Internal/On-campus'
            } else if(offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Attendance_Mode__c == 'EX'){
                attendanceMode = 'External/Off-campus'
            } else {
                attendanceMode = offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Attendance_Mode__c
            }

            offer['attendance'] = attendanceMode +' '+ attendanceType
            offer['commDate'] = offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Proposed_Commencement_Date__c
            offer['courseTitle'] = offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Course_Title__c
            offer['locationDesc'] = offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Location_Code__c
            offer['aou'] = offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.AOU_Name__c
            offer['faculty'] = offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Course__r?.Managing_Faculty__c
            offer['scholDecr'] = offer.quote?.SBQQ__Opportunity2__r?.Application_Course_Preference__r?.Scholarship_Round_Closing__c
        }
        else if(offer.isExpired){
            offerRec['showButton'] = false;
            offerRec['btnText'] = 'View Old Offer';
            offerRec['bannerImg'] = assets + '/screen-icons/tile3.PNG';
            offerRec['linkTarget'] = '';
        } else if ((offer.quote.Opportunity_Name__c.includes(util.gradResearchOppName) || offer.quote.Opportunity_Name__c === 'Graduate Research Offer Upload') && 
                offer.quote.SBQQ__Status__c === util.newStatus && 
                offer.quote.Final_Signed_Document_Id__c != null) { 
            offerRec['btnText'] = 'View Offer Letter';
            offerRec['btnLink'] = '../sfc/servlet.shepherd/document/download/' + offer.quote.Final_Signed_Document_Id__c;
            offerRec['bannerImg'] = assets + '/screen-icons/tile1.PNG';
            offerRec['linkTarget'] = '_document';
            offerRec['hasError'] = false;
            offer.quote.Offer_Type__c = 'Graduate Research Admissions';
        }
        else{
            offerRec['btnText'] = 'View Offer';
            offerRec['btnLink'] = urlString  + Offer_Summary_URL + '?id=' + offer.quote.Id;
            offerRec['bannerImg'] = assets + '/screen-icons/tile1.PNG';
            offerRec['linkTarget'] = '';
        }   
        
        return offerRec;
    }

    
    signOfferHandler(event){
        let offerId = event.target.dataset.id;
        this.loading = true;
        this.getSigningUrlMethod(offerId);
        
    }

    getSigningUrlMethod(offerId){
        getSigningUrl({quoteId: offerId})
            .then(result => {
                console.log('signing url'); 
                window.open(result, '_self');  
                this.loading = false;           
                
                })
            .catch(error => {
                console.log(error);
            }
        );
    }
    
}