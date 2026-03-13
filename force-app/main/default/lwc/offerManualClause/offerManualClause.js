import * as util from 'c/util';
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

import { unregisterAllListeners, registerListener} from 'c/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {CurrentPageReference} from 'lightning/navigation';
import getManualClauses from '@salesforce/apex/MirrorClauseServices.getManualClauses';
export default class OfferManualClause extends LightningElement {
    @api selectedacpList;
    @api opportunityRecord;
    @api selectedClauses;
    @track acpNotes = {};
    @track acpBahasaNotes = {};
    @api offerTemplate;
    @track manualClauses;
    @track displayClauses = false;
    @api bdpRec;
    @api bahasaOfferCondition;
    bahasaSavedOfferCondition;
    @wire(CurrentPageReference) pageRef;
     mapData= new Map();

    //bahaOfferCondId;
    //@track isMonashAbroadOffer = false;



    connectedCallback(){     
        /*
        //SFTG-1960 For Monash Abroad offers, the Additional clause is mandatory apart from Manual Clauses  
        if (this.selectedacpList[0].Application__r.Type_of_Study__c == 'Study Abroad' 
            || this.selectedacpList[0].Application__r.Type_of_Study__c == 'Exchange') {
            this.isMonashAbroadOffer = true;
        } */
        registerListener('selectedacps', this.getSelectedACP, this);
        this.getSelectedACP(this.selectedacpList);
    }

    disconnectedCallback(){
        unregisterAllListeners(this);
    }  

    getSelectedACP(acp){
        this.manualClauses = [];
        this.displayClauses = false;        
        getManualClauses({selectedACPjson: JSON.stringify(acp)})
        .then(results => {                         
            let data = JSON.parse(results);
            data.forEach(element => {
                let title = element.parentName + (element.parentObject.Course_Title__c ? ' - ' + element.parentObject.Course_Title__c : '') +
                            (element.parentObject.Commencement_Period__c ? ' - ' + element.parentObject.Commencement_Period__c : '') + 
                            (element.parentObject.Course_Offering__r.Campus__c ? ' - ' + element.parentObject.Course_Offering__r.Campus__c : '')
                element["title"] = title;
                element["hasClauses"] = element.clauses.length > 0;
                if (this.bdpRec && this.bdpRec.Student_Notes__c && this.bdpRec.Transfer_To__c == element.parentId) {
                    element["manualISCAnotes"] = this.bdpRec.Student_Notes__c;
                } else {
                    element["englishNotes"] =  element.parentId+'eng';
                    element["bahaNotes"] =  element.parentId+'baha';
                    element["bahaOfferCondId"] =  element.parentId+'bahaCond';
                   
                    element["manualISCAnotes"] = this.acpNotes[element.parentId];
                    element["englishOfferCondition"] = element.parentObject.Offer_Condition__c;
                    element["bahasaOfferCondition"] = element.parentObject.Bahasa_Offer_Condition__c;
                    element["manualBahasaISCAnotes"] = this.acpBahasaNotes[element.parentId];
                    element["isConditional"] = element.parentObject.Offer_Condition__c!=null?true:false;
                    
                }
                
                element.clauses.forEach(elem =>{
                    elem["uniqueId"] = element.parentObject.Course_Code__c+elem.Id;
                    elem["viewUrl"] = "/"+elem.Id;
                    elem["notesPosition"] = (elem.Notes__c && elem.Notes__c.length >= 300 ? 'top:-130px' : 'top:-50px');
                    elem["textPosition"] = (elem.Text__c && elem.Text__c.length >= 300 ? 'top:-130px' : 'top:-50px');
                    //keep/flag selected clauses
                    console.log(this.selectedClauses);
                    this.selectedClauses.forEach(contents =>{
                        contents.clauses.forEach(clause =>{
                            if(clause.uniqueId === elem.uniqueId){
                               elem["selected"] = clause.selected;
                            }
                        });
                    });
                    if(this.selectedClauses.length > 0){
                        element["existingAssociatedClause"] = this.selectedClauses != null 
                                                            ? this.selectedClauses[this.selectedClauses.length-1].existingAssociatedClause
                                                            : null;
                    }
                });          
                this.manualClauses.push(element);
            });
            this.displayClauses = true;
        }).catch((err) => {
            util.log(err);
        });

    }

    selectClause(evt){
        const selectedId = evt.currentTarget.id.split('-');
        this.manualClauses.forEach(element => {
            element.clauses.forEach(elem =>{
                if(elem.uniqueId == selectedId[0]){
                    elem.selected = !elem.selected;

                }
            })     
        });
    }

    showToast(title, message, type, mode = 'dismissable'){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message, 
                variant: type,
                mode: mode
            }),
        ); 
    }

    @api getSelectedClauses(){
        //find selected clauses
        let mirrorClauses;
        let selectedClauseList;
        let inputTextField;
        let inputBahasaTextField;
        let inputBahasaOfferCondTextField;

        
        let iscaNoteMap = {};
        let iscaBahasaNoteMap = {};
        let iscaBahasaOfferCondMap = {};

        this.selectedClauses = [];
        this.acpNotes = {};
        this.acpBahasaNotes = {};
        this.manualClauses.forEach(element => {                      
            selectedClauseList = [];
            mirrorClauses = {}
            //select input text by class - by acp record id
            inputTextField = this.template.querySelector('.'+element.parentId+'eng');
            iscaNoteMap[element.parentId] = (inputTextField ? inputTextField.value : '');
     
            //select input text by class - by acp record id
            inputBahasaTextField = this.template.querySelector('.'+element.parentId+'baha');
            iscaBahasaNoteMap[element.parentId] = (inputBahasaTextField ? inputBahasaTextField.value : '');

            //select input text by class - by acp record id
            inputBahasaOfferCondTextField = this.template.querySelector('.bahasaoffercond');
            iscaBahasaOfferCondMap[element.parentId] = (inputBahasaOfferCondTextField ? inputBahasaOfferCondTextField.value : '');

            element.clauses.forEach(elem =>{
                if (elem.selected){
                    selectedClauseList.push(elem);
                }
            })
            mirrorClauses["existingAssociatedClause"] = element.existingAssociatedClause;
            mirrorClauses["clauses"] = selectedClauseList;
            mirrorClauses["parentId"] = element.parentId;
            mirrorClauses["parentName"] = element.parentName;
            mirrorClauses["parentObject"] = element.parentObject;
            this.selectedClauses.push(mirrorClauses);
        });

        this.acpNotes = iscaNoteMap;
        this.acpBahasaNotes = iscaBahasaNoteMap;
        return this.selectedClauses;
    }

    @api getACPnotes(){
        return this.acpNotes;
    }

    @api getACPBahasanotes(){
        return this.acpBahasaNotes;
    }

    @api getACPUpdateMap(){
        return this.mapData;
    }
    
    handleInputChange(event) {
        this.mapData.set(event.currentTarget.dataset.id, event.currentTarget.value)
        if(event.currentTarget.value){
            this.mapData.forEach((value, key) => {
                let record = {
                    fields: {
                        Id:key,
                        Bahasa_Offer_Condition__c: value
                    }
                };
                updateRecord(record) .catch(function(error) {
                    console.error(error);
                });
            });
        }
   }

    
    get isIndoOffer() {
        if (this.offerTemplate == 'Domestic Coursework - Indonesia' || this.offerTemplate == 'Domestic Coursework Indonesia'  ) {
            return true;
        }
        return false;
    }
    
    get stylecl(){
        if(isIndoOffer)
        {
            this.stylecss =  'max-width: 50%; border-right: 1px solid #DDDBDA';
        }else
        {
            this.stylecss =  'max-width: 100%; border-right: 1px solid #DDDBDA';
        }
        

    }
}