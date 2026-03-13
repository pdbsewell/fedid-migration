import { LightningElement, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchSupportOptionMappings from '@salesforce/apex/CreateStudSupptOptionController.fetchSupportOptionMappings';
import saveMappings from '@salesforce/apex/CreateStudSupptOptionController.saveMappings';


export default class StudentSupportOptionCreation extends LightningElement {
    @track showSpinner = true;
    @track selectedSupportAreaPicklistOption;
    @track selectedSupportOption;
    @track mappingUpdated = true;
    @track supportAreaMapping = [];
    @track data = []; 
    @track isSaveDisabled = true;
    @api recordId;

    connectedCallback() {
        fetchSupportOptionMappings()
        .then(result => {
            if(result) {
                this.supportAreaMapping = result;  
            } else {
                console.log(result);
            }
        })
        .catch(error => {
            console.log(error);
            this.errorMessage = JSON.stringify(error, null, 2);
        })
        .finally(() => {
            this.showSpinner = false;
        });
    }

    get supportOptionPicklistOption(){
        let supportOptionOptions = [];
        for (let i = 0; i < this.supportAreaMapping.length; i++) {
            if(this.supportAreaMapping[i].supportArea === this.selectedSupportAreaPicklistOption){
                supportOptionOptions.push({ 
                    label: this.supportAreaMapping[i].supportOption, 
                    value: this.supportAreaMapping[i].supportOption
                });
            }
        }
        return supportOptionOptions;
    }

    /* support Area item */
    get supportAreaPicklistOption() {
        let supportAreaOptionsTemp = [];
        let uniqSupportAreaOptionsTemp = [];
        let supportAreaOptions = [];
        for (let i = 0; i < this.supportAreaMapping.length; i++) {
            supportAreaOptionsTemp.push(this.supportAreaMapping[i].supportArea);
        }
        uniqSupportAreaOptionsTemp = [...new Set(supportAreaOptionsTemp)];
        for (let i = 0; i < uniqSupportAreaOptionsTemp.length; i++) {
            supportAreaOptions.push({ 
                label: uniqSupportAreaOptionsTemp[i], 
                value: uniqSupportAreaOptionsTemp[i]
            });
        }
        return supportAreaOptions;
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    supportAreaMappingChange(event){
        this.mappingUpdated = false; 
        this.selectedSupportAreaPicklistOption = event.detail.value; 
        this.mappingUpdated = true;   
    }

    supportOptionMappingChange(event){
        this.selectedSupportOptionPicklistOption = event.detail.value; 
    }

    onClickAddtoTable(){
        if(this.selectedSupportAreaPicklistOption != undefined && this.selectedSupportOptionPicklistOption != undefined){
            let newKey = this.selectedSupportAreaPicklistOption + '-' + this.selectedSupportOptionPicklistOption;
        let duplicateRow = false;
        for (let i = 0; i < this.data.length; i++) {
            if(this.data[i].key == newKey){
                duplicateRow = true;
            }
        }
        if(!duplicateRow){
            let freshRow = [];
            freshRow.key = this.selectedSupportAreaPicklistOption + '-' + this.selectedSupportOptionPicklistOption;
            freshRow.supportArea = this.selectedSupportAreaPicklistOption;
            freshRow.supportOption = this.selectedSupportOptionPicklistOption;
            this.data.push(freshRow);
        }
        this.checkSaveButtonVisibility();
        }
    }

    checkSaveButtonVisibility(){
        if(this.data.length > 0){
            this.isSaveDisabled = false;
        }else{
            this.isSaveDisabled = true;
        }
    }
    
    // When User click on SAVE btn ..
    initiateSave(){
        let consolidatedKey= '';
        for (let i = 0; i < this.data.length; i++) {
            consolidatedKey = consolidatedKey + this.data[i].key + ';';
        }
        saveMappings({mapping : consolidatedKey , recordId : this.recordId})
        .then(result => {
            if(result) {
                this.showNotification('Records Successfully Submitted','Records created','success');
            } else {
                this.showNotification('Error','Failed To Upload Records','error');
                console.log(result);
            }
        })
        .catch(error => {
            console.log(error);
            this.errorMessage = JSON.stringify(error, null, 2);
        })
        .finally(() => {
            this.showSpinner = false;
            this.closeModal();
        });
    }

    // When User click on Delete Row ..
    remove(event) {        
        for(let i = 0; i < this.data.length; i++){
            if(event.currentTarget.name == this.data[i].key){
                this.data.splice(i, 1);
            }
        }
        this.checkSaveButtonVisibility();
    }

    showNotification(title, message, variant) {
        let mode = 'dismissible';
        if(variant == 'success')
            mode = 'sticky';
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}