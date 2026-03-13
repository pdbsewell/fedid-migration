import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getManualClauses from '@salesforce/apex/BulkAddManualClauseController.getManualClauses';
import saveBDPmanualClauses from '@salesforce/apex/BulkAddManualClauseController.saveBDPmanualClauses';

export default class OfferRequestTransfer extends NavigationMixin(LightningElement) {
    @api selectedOffers;
    isLoading = true;
    displayClauses = false;
    selectedClauses = [];
    manualClauses = [];
    bulkDataProcessingManualClauses = {};

    @wire(getManualClauses, {bdpIds: '$selectedOffers'})
    wiredFormPageList({ error, data }) {
        if(data){
            let results = JSON.parse(data);
            this.bulkDataProcessingManualClauses = results;
            //console.log('bulkDataProcessingManualClauses', JSON.parse(JSON.stringify(this.bulkDataProcessingManualClauses)));
            results.manualClausesWrapper.forEach(element => {
                let title = element.parentName + (element.parentObject ? ' - ' + element.parentObject.Transfer_Course_Title__c : '');
                element["title"] = title;
                element["hasClauses"] = element.clauses.length > 0;
                
                element.clauses.forEach(elem =>{
                    elem["selected"] = false;
                    elem["uniqueId"] = element.parentName+elem.Id;
                    elem["viewUrl"] = "/"+elem.Id;
                    elem["notesPosition"] = (elem.Notes__c && elem.Notes__c.length >= 300 ? 'top:-130px' : 'top:-50px');
                    elem["textPosition"] = (elem.Text__c && elem.Text__c.length >= 300 ? 'top:-130px' : 'top:-50px');

                });          
                this.manualClauses.push(element);
            });
            this.displayClauses = true;            
            this.isLoading = false;
        }else if(error){
            console.log('error:', error);
        }
    }

    selectClause(evt){
        const selectedId = evt.currentTarget.id.split('-');
        let clauses = JSON.parse(JSON.stringify(this.manualClauses));
        clauses.forEach(element => {
            element.clauses.forEach(elem =>{
                if(elem.uniqueId == selectedId[0]){
                    elem.selected = !elem.selected;
                }
            })     
        });
        this.manualClauses = clauses;
    }

    get selectedManualCLauses(){
        //find selected clauses
        let mirrorClauses;
        let selectedClauseList;  
        let selectedClauseMap = {};
        this.selectedClauses = [];      
        this.manualClauses.forEach(element => {             
            selectedClauseList = [];
            mirrorClauses = {}
            element.clauses.forEach(elem =>{
                if (elem.selected){
                    selectedClauseList.push(elem);
                }
            })
            selectedClauseMap[element.parentName] = selectedClauseList;
            mirrorClauses["clauses"] = selectedClauseList;
            mirrorClauses["parentName"] = element.parentName;
            mirrorClauses["parentId"] = element.parentId;
            mirrorClauses["parentObject"] = element.parentObject;
            this.selectedClauses.push(mirrorClauses);
        });

        this.bulkDataProcessingManualClauses.manualClausesWrapper = this.selectedClauses;
        this.bulkDataProcessingManualClauses.clauseListMapByCourseCode = selectedClauseMap;
        return this.bulkDataProcessingManualClauses;
    }

    saveManualClause(evt){           
        this.isLoading = true;
        console.log('on click save');
        saveBDPmanualClauses({BDPSelectedManualCLauses: JSON.stringify(this.selectedManualCLauses)})
            .then(result => {
                console.log('assoc clauses', JSON.parse(result));  
                this.backToListView();         
                //this.isLoading = false;
            })
            .catch(error => {
                console.log('error', error);      
                this.isLoading = false;
            });
    }

    backToListView(evt){
        this.dispatchEvent(new CustomEvent('pageRedirect', {
            detail: { data:  true},
            bubbles: true,
            composed: true,
        }));
    }

}