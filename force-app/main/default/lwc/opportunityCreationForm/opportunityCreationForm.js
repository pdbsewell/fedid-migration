import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 

export default class OpportunityCreationForm extends LightningElement {
    @track opportunityRecord  = new Object(); 
    @api accountRecordId;
    defaultClosedate;   
    defaultPrivate = false;
    
    connectedCallback(){ 
        // Set Default Close Date
        let date = new Date();
        var newDate = new Date(date.setMonth(date.getMonth()+3));
        let localTime = newDate.getTime();
        let localOffset = newDate.getTimezoneOffset() * 60000;
        let utc = localTime - localOffset;
        utc = new Date(utc);
        // return time as a string
        this.defaultClosedate = utc.toISOString();

        const field = this.template.querySelectorAll(`lightning-input-field[data-id="accountLookup"]`);
        field.value = this.accountRecordId;
        this.opportunityRecord["CloseDate"] = this.defaultClosedate;
        this.opportunityRecord["IsPrivate"] = this.defaultPrivate; 
        this.opportunityRecord["AccountId"] = this.accountRecordId;
		this.opportunityRecord["VisibilityCategory"] = 'Default';	
		this.opportunityRecord["TeamMember"] = false;	
    }

    @api
    retrieveOpportunityRecord(){ 
        let opportunityValid = this.validateOpportunity(); 
        if(opportunityValid){
            return this.opportunityRecord; 
        }else{
            return null;
        }        
    }

    @api
    validateOpportunity(){
        // Check for Name
        if(this.opportunityRecord.Name === undefined || this.opportunityRecord.Name === null || 
           this.opportunityRecord.Name === '' || (this.opportunityRecord.Name.trim()).length === 0){
            // Display Error
            this.displayErrorToast('Please enter an Opportunity Name');
            return false;
        }
        // Check for Name
        if((this.opportunityRecord.AccountId === undefined || this.opportunityRecord.AccountId === null || this.opportunityRecord.AccountId === '') && 
            (this.opportunityRecord.PrimaryContactId === undefined || this.opportunityRecord.PrimaryContactId === null || this.opportunityRecord.PrimaryContactId === '')){
            // Display Error
            this.displayErrorToast('Please enter an Account Name');
            return false;
        }
        //ENGAGEIE-1750 Remove requirement on amount field
        // Check for Amount
        /*if(this.opportunityRecord.Amount === undefined || this.opportunityRecord.Amount === null || this.opportunityRecord.Amount === ''){
            // Display Error
            this.displayErrorToast('Please enter an Amount');
            return false;
        }*/
        // Check for CloseDate
        if(this.opportunityRecord.CloseDate === undefined || this.opportunityRecord.CloseDate === null){
            // Display Error
            this.displayErrorToast('Please enter a Close Date'); 
            return false;
        }
        //ENGAGEIE-1730 Remove Category and Visibility Category check
		// Check for Category
        /*if(this.opportunityRecord.Category === undefined || this.opportunityRecord.Category === null || this.opportunityRecord.Category === ''){
            // Display Error
            this.displayErrorToast('Please enter a Category'); 
            return false;
        }*/
		// Check for Visibility Category
        /*if(this.opportunityRecord.VisibilityCategory === undefined || this.opportunityRecord.VisibilityCategory === null || this.opportunityRecord.VisibilityCategory === ''){
            // Display Error
            this.displayErrorToast('Please enter a Visibility Category'); 
            return false;
        }*/
        return true;
    }

    displayErrorToast(errorMessage){
        this.dispatchEvent(
            new ShowToastEvent({
                title : 'ERROR',
                message : errorMessage,
                variant : 'error',
            }),
        )
    }
	//ENGAGEIE-1730 Remove aVisibility Category check
	/*handleVisibilityCatgChange(event){
        this.opportunityRecord.VisibilityCategory = event.target.value; 
    }*/
	
	handleTeamMemberChange(event){
        this.opportunityRecord.TeamMember = event.target.checked; 
    }
	 //ENGAGEIE-1730 Primary Contact Check
	/*handlePrimaryContactIdChange(event){
        this.opportunityRecord.PrimaryContactId = event.target.value; 
    }*/

    handleNameChange(event){
        this.opportunityRecord.Name = event.target.value; 
    }
    handleDescriptionChange(event){
        this.opportunityRecord.Description = event.target.value;
    }
    handleAccountIdChange(event){
        this.opportunityRecord.AccountId = event.target.value;
    }
    handleAmountChange(event){
        this.opportunityRecord.Amount = event.target.value;
        // Creates the event with the data.
        const amountChangeEvent = new CustomEvent('amountchange', {
            detail: { amount: event.target.value }
        });
        this.dispatchEvent(amountChangeEvent);
    }
    
    handleCloseDateChange(event){
        this.opportunityRecord.CloseDate = event.target.value;
    }
    
    handleIsPrivateChange(event){
        this.opportunityRecord.IsPrivate = event.target.value;
    }
	 //ENGAGEIE-1730 Remove Category check
	/*handleCategoryChange(event){
        this.opportunityRecord.Category = event.target.value;
    }*/
    
    //START OF ENGAGEIE-1730 event handles for the new fields added on the component
    handleServiceCatalogueChange(event){
        this.opportunityRecord.ServiceCatalogue = event.target.value; 
    }

    handleStrategicAlignmentChange(event){
        this.opportunityRecord.StrategicAlignment = event.target.value; 
    }

    handleAreasOfInterestChange(event){
        this.opportunityRecord.AreasOfInterest = event.target.value; 
    }
    //END OF ENGAGEIE-1730
}