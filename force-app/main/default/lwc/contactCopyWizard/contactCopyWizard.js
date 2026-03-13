import { LightningElement} from "lwc";
/* APEX SERVICES */
import retrieveDuplicatecontactData from "@salesforce/apex/ContactCopyController.retrieveDuplicateContactData";
import deleteDRSAndUpdateContacts from "@salesforce/apex/ContactCopyController.deleteDRSAndUpdateContacts";
import fetchContactPointRecord from "@salesforce/apex/ContactCopyController.fetchContactPointRecord";
import updateContactPoints from "@salesforce/apex/ContactCopyController.updateContactPoints";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

// constants
const ADVANCEMENT = 'Advancement';
const ALUMNI_CONTACT_PROFILE = 'Alumni';
const ALUMNI_NO_DEGREE_CONTACT_PROFILE = 'Alumni No Degree';
const RECORD_TYPE_PROSPECTIVE_STUDENT = 'Prospective_Student';
const PROSPECTIVE_STUDENTS = 'Prospective Students';
const OTHER = 'Other';
const FIELD_API_NAME_MAP  = {'First_Name__c' : 'firstname', 
'Preferred_Name__c' : 'preferredname',
'Last_Name__c': 'lastname',
'Email' : 'email',
'Personal_Email__c' : 'personalemail',
'MobilePhone' : 'mobilephone',
'Birthdate' : 'dob',
'Person_ID__c' : 'personid',
'Gender__c' : 'gender',
'Pronouns_V2__c' : 'pronoun',
'Contact_Profile__c' : 'profile',
'Record_Type_Developer_Name__c' : 'recordtype'};
const FIELDS_CONSIDERED_FOR_MATCHING = ['First_Name__c','Preferred_Name__c','Last_Name__c','Email','Personal_Email__c','MobilePhone','Birthdate'];
const BG_COLOR_WHITE = '#FFFFFF';
const BG_COLOR_GREY = '#f3f3f3';
const BG_COLOR_GREEN = '#45c65a';

export default class ContactMergeWizard extends NavigationMixin(LightningElement) {
    myList = [];
    myListBefore = [];
    fullList = [];
    result = [];
    beforeData = []; 
    afterData = [];
    updatedContacts = [];
    newPhoneContactPoints = [];
    newEmailContactPoints = [];
    contactIdsMap = {};
    drsIdBycontactIdsMap = {};
    showSpinner = false;
    ruleValue = '';
    businessUnitValue = 'All';
    pageSizeValue = '10';
    drsrecordwithmatchingfieldsupdated = [];
    drsIdsToDelete = [];
    saveAndOpenClicked = false;

    get totalDRSRecords(){
        return this.myList?.length;
    }

    get isDataPresent(){
        return this.totalDRSRecords > 0 ? true : false;
    }

    get totalContactsForUpdate(){
        return this.updatedContacts ? this.updatedContacts.length : 0;
    }

    get isContactsMarkedForUpdate(){
        return this.totalContactsForUpdate > 0;
    }

    get duplicateRuleOptions() {
        return [
            { label: 'Contact Perfect Match', value: 'Contact Perfect' },
            { label: 'Contact Potential Match', value: 'Contact Potential' },
            { label: 'Contact Loose Match', value: 'Contact Loose' },
        ];
    }

    get businessUnitOptions() {
        return [
            { label: 'All', value: 'All' },
            { label: ADVANCEMENT, value: ADVANCEMENT },
            { label: PROSPECTIVE_STUDENTS, value: PROSPECTIVE_STUDENTS },
        ];
    }

    get pageSizeOptions(){
        return [
            { label: '10', value: '10' },
            { label: '20', value: '20' },
            { label: '30', value: '30' },
            { label: '40', value: '40' },
            { label: '50', value: '50' }
        ];
    }

    get advancementDRSList(){
        let drs = [];
        for(let i = 0; i < this.fullList.length; i++){
            if(this.fullList[i].businessUnit.includes(ADVANCEMENT)){
                drs.push(this.fullList[i]);
            }
        }
        return drs;
    }

    get prospectiveStudentsDRSList(){
        let drs = [];
        for(let i = 0; i < this.fullList.length; i++){
            if(this.fullList[i].businessUnit.includes(PROSPECTIVE_STUDENTS)){
                drs.push(this.fullList[i]);
            }
        }
        return drs;
    }

    /*
     * Method Name: searchOnClick
     * Description: method to query entity data from controller with some pre-invocation validations
     */
    searchOnClick() {

        this.showSpinner = true;
        this.myList = [];
        this.myListBefore = [];
        this.updatedContacts = [];
        this.newPhoneContactPoints = [];
        this.newEmailContactPoints = [];
        if(!this.ruleValue){
            this.showSpinner = false;
            this.showToast(
                "Error",
                "Select a Duplicate Rule",
                "Error"
            );  
        }
        else{
            this.getData();
        }
    }

    /*
     * Method Name: getData
     * Description: method to call apex function passing parameters from the UI
     */
    getData() {
        retrieveDuplicatecontactData({
            duplicateRule: this.ruleValue + '%',
            businessUnit: this.businessUnitValue,
            limitSize: this.pageSizeValue
        })
            .then((result) => {
                this.result = result;
                this.myList = [];
                this.myListBefore = [];
                this.prepareDataTable();
                this.updateListBasedOnBusinessUnit();
            })
            .catch((error) => {
                this.showToast(
                    "Error",
                    "An error has occurred: " + error?.body?.message,
                    "Error"
                );
            });
    }

    /*
     * Method Name: prepareDataTable
     * Description: method to prepare the array of table data
     */
    prepareDataTable() {
        if(this.result){
            for(var i = 0; i < this.result.length; i++){
                let businessUnit = [];
                let contactList = [];
                let con1 = this.result[i].contactData[0].Id;
                let con2 = this.result[i].contactData[1].Id;
                this.contactIdsMap[con1] = con2;

                this.drsIdBycontactIdsMap[con1] = this.result[i].drsId.replace("/", "");
                this.drsIdBycontactIdsMap[con2] = this.result[i].drsId.replace("/", "");

                let dkey1 = Math.random().toString(36).substring(2, 15);
                for(var j = 0; j < this.result[i].contactData.length; j++) {
                    
                    let cc = this.result[i].contactData[j];
                    let contactIdNavigation = '/'+cc.Id;
                    
                    // Prepare the contact record table data
                    contactList.push({firstname_fieldname : 'First_Name__c', firstname : cc.First_Name__c, firstname_rname : dkey1+'firstname', firstname_rid : Math.random().toString(36).substring(2, 15), firstname_bgcolor : BG_COLOR_WHITE,
                                        preferredname_fieldname : 'Preferred_Name__c', preferredname : cc.Preferred_Name__c, preferredname_rname : dkey1+'preferredname', preferredname_rid : Math.random().toString(36).substring(2, 15), preferredname_bgcolor : BG_COLOR_WHITE,
                                        lastname_fieldname : 'Last_Name__c', lastname : cc.Last_Name__c, lastname_rname : dkey1+'lastname', lastname_rid : Math.random().toString(36).substring(2, 15), lastname_bgcolor : BG_COLOR_WHITE,
                                        email_fieldname : 'Email', email : cc.Email, email_rname : dkey1+'email', email_rid : Math.random().toString(36).substring(2, 15), email_bgcolor : BG_COLOR_WHITE,
                                        personalemail_fieldname : 'Personal_Email__c', personalemail : cc.Email, personalemail_rname : dkey1+'personalemail', personalemail_rid : Math.random().toString(36).substring(2, 15), personalemail_bgcolor : BG_COLOR_WHITE,
                                        mobilephone_fieldname : 'MobilePhone', mobilephone : cc.MobilePhone, mobilephone_rname : dkey1+'mobilephone', mobilephone_rid : Math.random().toString(36).substring(2, 15), mobilephone_bgcolor : BG_COLOR_WHITE,
                                        dob_fieldname : 'Birthdate', dob : cc.Birthdate, dob_rname : dkey1+'dob', dob_rid : Math.random().toString(36).substring(2, 15), dob_bgcolor : BG_COLOR_WHITE,
                                        personid_fieldname : 'Person_ID__c', personid : cc.Person_ID__c, personid_rname : dkey1+'personid', personid_rid : Math.random().toString(36).substring(2, 15), personid_bgcolor : BG_COLOR_GREY,
                                        gender_fieldname : 'Gender__c', gender : cc.Gender__c, gender_rname : dkey1+'gender', gender_rid : Math.random().toString(36).substring(2, 15), gender_bgcolor : BG_COLOR_WHITE,
                                        pronoun_fieldname : 'Pronouns_V2__c', pronoun : cc.Pronouns_V2__c, pronoun_rname : dkey1+'pronoun', pronoun_rid : Math.random().toString(36).substring(2, 15), pronoun_bgcolor : BG_COLOR_WHITE,
                                        profile_fieldname : 'Contact_Profile__c', profile : cc.Contact_Profile__c, profile_rname : dkey1+'profile', profile_rid : Math.random().toString(36).substring(2, 15), profile_bgcolor : BG_COLOR_GREY,
                                        recordtype_fieldname : 'Record_Type_Developer_Name__c', recordtype : cc.Record_Type_Developer_Name__c, recordtype_rname : dkey1+'recordtype', recordtype_rid : Math.random().toString(36).substring(2, 15), recordtype_bgcolor : BG_COLOR_GREY,
                                        key : cc.Id,
                                        contactId : contactIdNavigation});

                    if(cc?.Contact_Profile__c?.includes(ALUMNI_CONTACT_PROFILE) && !cc?.Contact_Profile__c?.includes(ALUMNI_NO_DEGREE_CONTACT_PROFILE) ){
                        businessUnit.push(ADVANCEMENT);
                    }
                    if(cc?.Record_Type_Developer_Name__c?.includes(RECORD_TYPE_PROSPECTIVE_STUDENT)){
                        businessUnit.push(PROSPECTIVE_STUDENTS);
                    }
                    if(!cc?.Contact_Profile__c?.includes(ALUMNI_CONTACT_PROFILE) &&
                        !cc?.Record_Type_Developer_Name__c?.includes(RECORD_TYPE_PROSPECTIVE_STUDENT)){
                        businessUnit.push(OTHER);
                    }
                }

                // Prepare the DRS table data
                this.myList.push({drsname : this.result[i].drsName, 
                                drsId : this.result[i].drsId, 
                                contact : contactList , key : dkey1, 
                                businessUnit : businessUnit,
                                updated : false,
                                excludeFromMerge : (this.result[i].excludeFromMerge === 'true') ? true : false});

                this.myListBefore = JSON.parse(JSON.stringify(this.myList));
            }
            this.showSpinner = false;
            this.fullList = JSON.parse(JSON.stringify(this.myList));
        }
    }

    handleClick(event) {
        let fName = event.currentTarget.dataset.fieldName;
        let fValue = event.currentTarget.dataset.fieldValue;
        let conKey = event.currentTarget.dataset.contactKey;
        let selectedContactPersonId = event.currentTarget.dataset.contactPersonid;
        let drsId = '';
        let associatedConId = this.getAssociatedContact(conKey);
        let associatedCon = {};

        for(let i = 0; i < this.afterData.length; i++){
            if(this.afterData[i].Id == associatedConId){
                let rec = {};
                rec = JSON.parse(JSON.stringify(this.afterData[i]));

                associatedCon = rec;
                let alumString = ALUMNI_CONTACT_PROFILE + ';';
                if((associatedCon.Contact_Profile__c && (associatedCon.Contact_Profile__c === ALUMNI_CONTACT_PROFILE || associatedCon.Contact_Profile__c.includes(alumString) || associatedCon.Contact_Profile__c.endsWith(ALUMNI_CONTACT_PROFILE))) || 
                (!selectedContactPersonId && associatedCon.Person_ID__c)){
                    this.showToast(
                        "Error",
                        "Cannot edit contact record with Person Id and/or Alumni profile",
                        "Error"
                    );
                    return;
                }

                // Do not capture if the value has not changed
                if(fValue == associatedCon[fName]){
                    return;
                }

                rec[fName] = fValue;
                this.afterData.splice(i, 1);
                this.afterData.push(rec);

                drsId = this.drsIdBycontactIdsMap[rec.Id];
                if(FIELDS_CONSIDERED_FOR_MATCHING.indexOf(fName) >= 0 && this.drsIdsToDelete.indexOf(drsId) < 0){
                    this.drsIdsToDelete.push(drsId);
                }

                break
            }
        }

        this.updateBackgroundColorAndValue(event.currentTarget.id.split('-'), FIELD_API_NAME_MAP[fName], fValue);        
        
        this.getUpdatedContact();

        let objectApiName = '';
        if (fName === 'MobilePhone'){
            objectApiName = 'Phone__c';
        }
        else if (fName === 'Email' || fName === 'Personal_Email__c'){
            objectApiName = 'Email__c';
        }
        
        if(objectApiName !== ''){
            this.fetchAndUpdateContactPoint(objectApiName, fValue, fName, conKey, associatedConId);  
        } 
    }

    /*
     * Method Name: updateBackgroundColorAndValue
     * Description: method to mark the updating field green and copy the field value to destination
     */
    updateBackgroundColorAndValue(fieldId, fieldname, newvalue){
        let fldid = fieldId[0];
        let rid = fieldname + '_rid';
        let bgcolor = fieldname + '_bgcolor';
        let found = false;
        let oldvalue = '';
        for(let i = 0; i < this.myList.length; i++){
            for(let j = 0; j < this.myList[i].contact.length; j++){
                if(this.myList[i].contact[j][rid] === fldid){
                    let idx = 0
                    idx = (j === 0) ? 1 : 0;
                    oldvalue = this.myList[i].contact[idx][fieldname];
                    if(oldvalue != newvalue){
                        this.myList[i].contact[idx][bgcolor] = BG_COLOR_GREEN;
                        this.myList[i].contact[idx][fieldname] = newvalue;
                    }
                    found = true;
                    this.myList[i].updated = true;
                    break;
                }
                if(found) break;
            }
            if(found) break;
        }
    }

    /*
     * Method Name: getUpdatedContact
     * Description: method to identify the updated contact
     */
    getUpdatedContact(){
        this.updatedContacts = [];
        let contactForUpdate = {};
        for (var i = 0; i<this.beforeData.length; i++) {
            for (var j = 0; j<this.afterData.length; j++) {
                if(this.beforeData[i].Id === this.afterData[j].Id && 
                    !this.shallowEqual(this.beforeData[i], this.afterData[j])){
                        contactForUpdate = this.afterData[j];
                        this.updatedContacts.push(contactForUpdate);
                }
            }
        }
    }

    /*
     * Method Name: fetchAndUpdateContactPoint
     * Description: method to fetch, clone and link it to the updating contact record
     */
    fetchAndUpdateContactPoint(objectApiName, fValue, fName, conKey, associatedConId){
        if(objectApiName != '' && fValue != undefined && fValue != ''){
            fetchContactPointRecord({
                contactPointValue: fValue,
                contactId: conKey,
                objectApiName: objectApiName
            })
            .then((result) => {
                let newContactPoint = JSON.parse(JSON.stringify(result));
                newContactPoint.Contact__c = associatedConId;
                if (fName === 'MobilePhone'){
                    this.newPhoneContactPoints.push(newContactPoint);
                }
                else if (fName === 'Email' || fName === 'Personal_Email__c'){
                    this.newEmailContactPoints.push(newContactPoint);
                }
            })
            .catch((error) => {
                this.showToast(
                    "Error",
                    "An error has occurred: " + error?.body?.message,
                    "Error"
                );
            });
        }
    }

    /*
     * Method Name: shallowEqual
     * Description: method to compare 2 objects
     */
    shallowEqual(object1, object2) {
        const keys1 = Object.keys(object1);
        const keys2 = Object.keys(object2);
      
        if (keys1.length !== keys2.length) {
            return false;
        }
      
        for (let key of keys1) {
            if (object1[key] !== object2[key]) {
                return false;
            }
        }
      
        return true;
    }

    /*
     * Method Name: getAssociatedContact
     * Description: method to get the associated contact Id for the passed contact Id
     */
    getAssociatedContact(selectedContact){
        let associatedContact = '';
        
        if(this.contactIdsMap[selectedContact]){
            associatedContact = this.contactIdsMap[selectedContact];
        }
        else{
            associatedContact = this.getKeyByValue(this.contactIdsMap, selectedContact);
        }
        return associatedContact;
    }

    getKeyByValue(object, value) {
        return Object.keys(object).find(key => object[key] === value);
    }

    /*
     * Method Name: saveChanges
     * Description: method to save the contact changes
     */
    saveChanges() {

        this.showSpinner = true;
        this.myList = [];
        this.myListBefore = [];
        this.beforeData = [];
        this.afterData = [];

        // Delete the DRS records and update the contacts
        deleteDRSAndUpdateContacts({
             drsIds: this.drsIdsToDelete,
             contactsToUpdate: this.updatedContacts
        })
        .then((result) => {
            this.showSpinner = false;

            // Update the contact points created by roll down
            updateContactPoints({
                newPhoneRecords: this.newPhoneContactPoints,
                newEmailRecords: this.newEmailContactPoints
            })
            .then((result1) => {
                this.updatedContacts = [];
                this.newPhoneContactPoints = [];
                this.newEmailContactPoints = [];
            })
            .catch((error) => {
                this.showSpinner = false;
                this.updatedContacts = [];
                this.newPhoneContactPoints = [];
                this.newEmailContactPoints = [];
                this.showToast(
                    "Error",
                    "An error has occurred while updating the contact point: " + error.body.message,
                    "Error"
                );
            });
        })
        .catch((error) => {
            this.showSpinner = false;
            this.updatedContacts = [];
            this.newPhoneContactPoints = [];
            this.newEmailContactPoints = [];
            this.showToast(
                "Error",
                "An error has occurred while updating the contact: " + error.body.message,
                "Error"
            );
        });
    }

    handleRuleChange(event) {
        this.ruleValue = event.detail.value;
        this.searchOnClick();
    }

    handlePageSizeChange(event){
        this.pageSizeValue = event.detail.value;
        this.searchOnClick();
    }

    handleBusinessUnitChange(event) {
        this.businessUnitValue = event.detail.value;
        //this.updateListBasedOnBusinessUnit();
        this.searchOnClick();
    }

    /*
     * Method Name: navigateToContactMergeApp
     * Description: method to prepare parameters to be passed while opening merge tool
     */
    navigateToContactMergeApp(event) {
        let recordIdx = event.target.dataset.id;
        let firstname = this.myList[recordIdx].contact[0].preferredname ? this.myList[recordIdx].contact[0].preferredname :
                        this.myList[recordIdx].contact[0].firstname ? this.myList[recordIdx].contact[0].firstname : '';
        let lastname = this.myList[recordIdx].contact[0].lastname ? this.myList[recordIdx].contact[0].lastname : '';
        let email = this.myList[recordIdx].contact[0].email ? this.myList[recordIdx].contact[0].email : '';
        let personid = this.myList[recordIdx].contact[0].personid ? this.myList[recordIdx].contact[0].personid : '';
        //let url = '/lightning/n/Merge_Tool?c__fname='+firstname+'&c__lname='+lastname+'&c__email='+email+'&c__personid='+personid;
        let url = '/lightning/n/Merge_Tool?c__email='+email;

        this.navigateToUrl(url);
    }

    /*
     * Method Name: navigateToUrl
     * Description: method to open the url eg : Merge tool
     * Parameters: url - url to navigate to
     */
    navigateToUrl(url) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }

    /*
     * Method Name: navigateToContactMergeApp
     * Description: method to prepare parameters to be passed while opening merge tool
     */
    reset(event) {
        let tempList = JSON.parse(JSON.stringify(this.myList));
        let tempListBefore = JSON.parse(JSON.stringify(this.myListBefore));
        this.myList = [];
        let recordIdx = event.target.dataset.id;
        let contactsList = [];
        contactsList.push(tempListBefore[recordIdx].contact[0].contactId.replace("/", ""));
        contactsList.push(tempListBefore[recordIdx].contact[1].contactId.replace("/", ""));

        for(let i = 0; i < tempList.length; i++){
            if(tempListBefore[recordIdx].drsname === tempList[i].drsname){
                this.myList.push(tempListBefore[recordIdx]);
            }
            else{
                this.myList.push(tempList[i]);
            }
        }
        
        for(let i = 0; i < this.beforeData.length; i++){
            for(let j = 0; j < this.afterData.length; j++){
                if(this.beforeData[i].Id === this.afterData[j].Id && contactsList.includes(this.afterData[j].Id)){
                    this.afterData[j] = this.beforeData[i];
                }
            }
        }

        // Remove contacts marked for update from the list
        let contactPositions = [];
        for(let i = 0; i < this.updatedContacts.length; i++){
            if(contactsList.includes(this.updatedContacts[i].Id)){
                contactPositions.push(i);
            }
        }
        for(let i = 0; i < contactPositions.length; i++){
            this.updatedContacts.splice(contactPositions[i], 1);
        }

        // Remove contact points marked for update from the list
        let phonePositions = [];
        for(let i = 0; i < this.newPhoneContactPoints.length; i++){
            if(contactsList.includes(this.newPhoneContactPoints[i].Contact__c)){
                phonePositions.push(i);
            }
        }
        for(let i = 0; i < phonePositions.length; i++){
            this.newPhoneContactPoints.splice(phonePositions[i], 1);
        }

        let emailPositions = [];
        for(let i = 0; i < this.newEmailContactPoints.length; i++){
            if(contactsList.includes(this.newEmailContactPoints[i].Contact__c)){
                emailPositions.push(i);
            }
        }
        for(let i = 0; i < emailPositions.length; i++){
            this.newEmailContactPoints.splice(emailPositions[i], 1);
        }

        // Remove DRS Ids marked for deletion from the list
        this.drsIdsToDelete.splice(this.drsIdsToDelete.indexOf(tempListBefore[recordIdx].drsId.replace("/", "")), 1);
    }

    /*
     * Method Name: updateListBasedOnBusinessUnit
     * Description: method to display data based on the selected business unit
     */
    updateListBasedOnBusinessUnit(){
        switch (this.businessUnitValue) {
            case ADVANCEMENT:
                this.myList = JSON.parse(JSON.stringify(this.advancementDRSList));
                break;

            case PROSPECTIVE_STUDENTS:
                this.myList = JSON.parse(JSON.stringify(this.prospectiveStudentsDRSList));
                break;

            case 'All':
                this.myList = JSON.parse(JSON.stringify(this.fullList));
                break;
        
            default:
                this.myList = JSON.parse(JSON.stringify(this.fullList));
                break;
        }

        this.myListBefore = JSON.parse(JSON.stringify(this.myList));
        this.prepareBeforeAndAfterData();
    }

    /*
     * Method Name: prepareBeforeAndAfterData
     * Description: method to mark the updating field green and copy the field value to destination
     */
    prepareBeforeAndAfterData(){
        this.beforeData = [];
        this.afterData = [];
        for(let i = 0; i < this.myList.length; i++){
            for(let j = 0; j < this.result.length; j++){
                if(this.myList[i].drsname === this.result[j].drsName){
                    this.beforeData.push(this.result[j].contactData[0]);
                    this.beforeData.push(this.result[j].contactData[1]);
                    break;
                }
            }
        }
        this.afterData = JSON.parse(JSON.stringify(this.beforeData));
    }

    /*
     * Method Name: showToast
     * Description: method to show toast
     */
    showToast(toastTitle, toastMessage, toastVariant) {
        const toast = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
        });
        this.dispatchEvent(toast);
    }
}