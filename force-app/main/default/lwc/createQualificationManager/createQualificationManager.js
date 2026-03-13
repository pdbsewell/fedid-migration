/**
 * Created by jmap0002 on 23/10/2019.
 */

import {LightningElement, api, track, wire} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import fetchData from '@salesforce/apex/CreateQualificationServices.fetchInitialData';
import createQualification from '@salesforce/apex/CreateQualificationServices.createQualification';

export default class CreateQualificationManager extends LightningElement {
    @api recordId;

    @track showSpinner = false;
    @track disableSave = true;
    @track timeout;

    @track errMsgList;

    @track fetchedData;
    // Wired variables
    wiredFetchedData;

    @track selectedRecordTypeValue;
    @track disableSaveBtn = true;
    @track disableCancelBtn = false;

        // Tertiary Details
    @track selected_Country_TerEd;
    //@track str_Title_TerEd;
    @track str_Other_Qualification_TerEd;
    @track selected_Institution_Name_TerEd;
    @track str_Other_Institution_TerEd;
    @track selected_Status_TerEd;
    @track str_First_Year_Enrolled_TerEd;
    @track str_Last_Year_Enrolled_TerEd;
    @track str_Year_of_Completion_TerEd;
    @track textArea_Other_Qualification_Comments_TerEd;
    @track selected_QualificationLevel_TertiaryEducation;
    @track str_Score_TerEd;
    @track str_Qualification_GPA_Scale_TerEd;
    @track selected_Qualification_GPA_Calc_Method_TerEd;
    @track selected_Monash_Equivalent_GPA_TerEd;
    @track str_Number_of_Fails_TerEd;
    @track checked_USA_Accredited_TerEd;
    @track checked_Instruction_in_English_TerEd;
    @track textArea_Assessment_Comments_TerEd;
    @track selected_Verification_Status_TerEd;

        // Secondary Education
    @track selected_Qualification_Country_SecEd;
    @track selected_State_SecEd;
    @track str_State_Province_SecEd;
    @track selected_Qualification_SecEd;
    @track str_Other_Qualification_SecEd;
    @track selected_Institution_Name_SecEd;
    @track str_Other_Institution_SecEd;
    @track checked_isTestCompleted_SecEd;
    @track str_Year_of_Completion_SecEd;
    @track date_Expected_date_of_completion_SecEd;
    @track textArea_Other_Qualification_Comments_SecEd;
    @track str_Score_SecEd;
    @track str_Qualification_GPA_Scale_SecEd;
    @track selected_Qualification_GPA_Calc_Method_SecEd;
    @track selected_Monash_Equivalent_GPA_SecEd;
    @track str_Number_of_Fails_SecEd;
    @track checked_USA_Accredited_SecEd;
    @track checked_Instruction_in_English_SecEd;
    @track selected_Verification_Status_SecEd;
    @track textArea_Assessment_Comments_SecEd;

        // English Test
    @track selected_EnglishType_EngTest;
    @track checked_isTestCompleted_EngTest;
    @track date_Date_Achieved_EngTest;
    @track date_Expected_date_of_completion_EngTest;
    @track textArea_Other_Qualification_Comments_EngTest;
    @track str_Score_EngTest;
    @track str_Listening_EngTest;
    @track str_Reading_EngTest;
    @track str_Speaking_EngTest;
    @track str_Writing_EngTest;
    @track str_Test_of_Written_English_EngTest;
    @track selected_Monash_Equivalent_GPA_EngTest;
    @track selected_Verification_Status_EngTest;
    @track textArea_Assessment_Comments_EngTest;

        // Other Qualification
    @track str_Other_Qualification_OtherQual;
    @track checked_isTestCompleted_OtherQual;
    @track date_Date_Achieved_OtherQual;
    @track date_Expected_date_of_completion_OtherQual;
    @track textArea_Other_Qualification_Comments_OtherQual;
    @track str_Score_OtherQual;
    @track selected_Verification_Status_OtherQual;
    @track textArea_Assessment_Comments_OtherQual;



        // HELP TEXT
    @track helpText_AwardingBodyInstitution = 'If you cannot find the institution, enter it manually on Other Awarding Body or Institution.';

    @wire(fetchData)
    loadFetchedData(result) {
        this.showSpinner = true;
        this.wiredFetchedData = result;
        if (result.data) {
            this.fetchedData = result.data;
            this.showSpinner = false;
            this.disableSave = false;
        } else if (result.error) {
            //console.log('### result.error:' + JSON.stringify(result.error));
            this.showSpinner = false;
            this.showToast('Error', 'Something went wrong while processing your request. Please contact your system administrator.', 'error');
        }
    }

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        // code here
    }
    get recordTypeOptions() {
        var recordTypeOptions = [];
        if (this.fetchedData !== undefined && this.fetchedData.qualificationRecordTypeOptions !== undefined) {
            for (var key in this.fetchedData.qualificationRecordTypeOptions) {
                recordTypeOptions.push({label: this.fetchedData.qualificationRecordTypeOptions[key], value: key});
            }
        }
        return recordTypeOptions;
    }
    handleSelectedRecordTypeValueOnChange(event) {
        this.selectedRecordTypeValue = event.detail.value;

        if (this.selectedRecordTypeValue !== undefined && this.selectedRecordTypeValue !== null && this.selectedRecordTypeValue !== '') {
            this.disableSaveBtn = false;
        } else {
            this.disableSaveBtn = true;
        }
    }
    get showTertiarySection() {
        return this.selectedRecordTypeValue !== undefined && this.selectedRecordTypeValue !== null && this.selectedRecordTypeValue !== ''
            && this.fetchedData !== undefined && this.fetchedData.qualificationRecordTypeOptions !== undefined
            && this.fetchedData.qualificationRecordTypeOptions[this.selectedRecordTypeValue] === 'Tertiary Education';
    }
    get showSecondarySection() {
        return this.selectedRecordTypeValue !== undefined && this.selectedRecordTypeValue !== null && this.selectedRecordTypeValue !== ''
            && this.fetchedData !== undefined && this.fetchedData.qualificationRecordTypeOptions !== undefined
            && this.fetchedData.qualificationRecordTypeOptions[this.selectedRecordTypeValue] === 'Secondary Education';
    }
    get showEnglishSection() {
        return this.selectedRecordTypeValue !== undefined && this.selectedRecordTypeValue !== null && this.selectedRecordTypeValue !== ''
            && this.fetchedData !== undefined && this.fetchedData.qualificationRecordTypeOptions !== undefined
            && this.fetchedData.qualificationRecordTypeOptions[this.selectedRecordTypeValue] === 'English Test';
    }
    get showOtherSection() {
        return this.selectedRecordTypeValue !== undefined && this.selectedRecordTypeValue !== null && this.selectedRecordTypeValue !== ''
            && this.fetchedData !== undefined && this.fetchedData.qualificationRecordTypeOptions !== undefined
            && this.fetchedData.qualificationRecordTypeOptions[this.selectedRecordTypeValue] === 'Other Qualification';
    }
    get options_Qualification_Country_TerEd() {
        var v_countryListOptions = [];
        v_countryListOptions.push({label : '-- Select One --', value : ''});
        if (this.selectedRecordTypeValue !== undefined && this.selectedRecordTypeValue !== '' && this.fetchedData !== undefined && this.fetchedData.countryStudiedOptions !== undefined) {
            for (var key in this.fetchedData.countryStudiedOptions) {
                v_countryListOptions.push({label : this.fetchedData.countryStudiedOptions[key], value : key});
            }
        }
        return v_countryListOptions;
    }
    get options_Institution_Name_TerEd() {
        var v_options_Institution_Name_TerEd = [];
        v_options_Institution_Name_TerEd.push({label : '-- Select One --', value : ''});
        if (this.selected_Country_TerEd !== undefined && this.selected_Country_TerEd !== '' && this.fetchedData !== undefined && this.fetchedData.institutionOptions !== undefined) {
            var v_selected_Country_TerEd = this.fetchedData.countryStudiedOptions[this.selected_Country_TerEd] !== undefined ? this.fetchedData.countryStudiedOptions[this.selected_Country_TerEd] : '';
            for (var key in this.fetchedData.institutionOptions) {
                if (this.fetchedData.institutionOptions[key].Country__c !== undefined && this.fetchedData.institutionOptions[key].Country__c !== null && this.fetchedData.institutionOptions[key].Country__c !== '') {
                    if (this.fetchedData.institutionOptions[key].Type__c === 'Tertiary' && this.fetchedData.institutionOptions[key].Country__c.toLowerCase() === v_selected_Country_TerEd.toLowerCase()) {
                        v_options_Institution_Name_TerEd.push({ label : this.fetchedData.institutionOptions[key].Institution_Name__c, value : this.fetchedData.institutionOptions[key].Id });
                    }
                }
            }
        }
        return v_options_Institution_Name_TerEd;
    }
    get options_Status_TerEd() {
        var v_options_Status_TerEd = [];
        v_options_Status_TerEd.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.completionStatusOptions !== undefined) {
            for (var key in this.fetchedData.completionStatusOptions) {
                v_options_Status_TerEd.push({ label : this.fetchedData.completionStatusOptions[key], value : key});
            }
        }
        return v_options_Status_TerEd;
    }
    get options_Tertiary_Qualification_Level_TerEd() {
        var v_options_Tertiary_Qualification_Level_TerEd = [];
        v_options_Tertiary_Qualification_Level_TerEd.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.tertiaryQualificationLevelOptions !== undefined) {
            for (var key in this.fetchedData.tertiaryQualificationLevelOptions) {
                v_options_Tertiary_Qualification_Level_TerEd.push({ label : this.fetchedData.tertiaryQualificationLevelOptions[key], value : key})
            }
        }
        return v_options_Tertiary_Qualification_Level_TerEd;
    }
    get options_Qualification_GPA_Calc_Method_TerEd() {
        var v_options_Qualification_GPA_Calc_Method_TerEd = [];
        v_options_Qualification_GPA_Calc_Method_TerEd.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.qualificationGPACalcMethodOptions !== undefined) {
            for (var key in this.fetchedData.qualificationGPACalcMethodOptions) {
                v_options_Qualification_GPA_Calc_Method_TerEd.push({ label : this.fetchedData.qualificationGPACalcMethodOptions[key], value : key})
            }
        }
        return v_options_Qualification_GPA_Calc_Method_TerEd;
    }
    get options_Monash_Equivalent_GPA_TerEd() {
        var v_options_Monash_Equivalent_GPA_TerEd = [];
        v_options_Monash_Equivalent_GPA_TerEd.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.monashEquivalentGPAOptions !== undefined) {
            for (var key in this.fetchedData.monashEquivalentGPAOptions) {
                v_options_Monash_Equivalent_GPA_TerEd.push({ label : this.fetchedData.monashEquivalentGPAOptions[key], value : key})
            }
        }
        return v_options_Monash_Equivalent_GPA_TerEd;
    }
    get options_Verification_Status_TerEd() {
        var v_options_Verification_Status_TerEd = [];
        v_options_Verification_Status_TerEd.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.verificationStatusOptions !== undefined) {
            for (var key in this.fetchedData.verificationStatusOptions) {
                v_options_Verification_Status_TerEd.push({ label : this.fetchedData.verificationStatusOptions[key], value : key});
            }
        }
        return v_options_Verification_Status_TerEd;
    }
    onchange_selected_Country_TerEd(event) {
        this.selected_Country_TerEd = event.detail.value;

        // If selected country is Australia, set the English Language of Instruction to true by default
        if (this.fetchedData.countryStudiedOptions !== undefined && this.fetchedData.countryStudiedOptions[this.selected_Country_TerEd] === 'Australia')
            this.checked_Instruction_in_English_TerEd = true;
        else
            this.checked_Instruction_in_English_TerEd = false;
    }
   /* onchange_str_Title_TerEd(event) {
        this.str_Title_TerEd = event.detail.value;
    }*/
    onchange_str_Other_Qualification_TerEd(event) {
        this.str_Other_Qualification_TerEd = event.detail.value;
    }
    onchange_selected_Institution_Name_TerEd(event) {
        this.selected_Institution_Name_TerEd = event.detail.value;
    }
    onchange_str_Other_Institution_TerEd(event) {
        this.str_Other_Institution_TerEd = event.detail.value;
    }
    onchange_selected_Status_TerEd(event) {
        this.selected_Status_TerEd = event.detail.value;
    }
    onchange_str_First_Year_Enrolled_TerEd(event) {
        this.str_First_Year_Enrolled_TerEd = event.detail.value;
    }
    onchange_str_Last_Year_Enrolled_TerEd(event) {
        this.str_Last_Year_Enrolled_TerEd = event.detail.value;
    }
    onchange_str_Year_of_Completion_TerEd(event) {
        this.str_Year_of_Completion_TerEd = event.detail.value;
    }
    onchange_textArea_Other_Qualification_Comments_TerEd(event) {
        this.textArea_Other_Qualification_Comments_TerEd = event.detail.value;
    }
    onchange_selected_QualificationLevel_TertiaryEducation(event) {
        this.selected_QualificationLevel_TertiaryEducation = event.detail.value;
    }
    onchange_str_Score_TerEd(event) {
        this.str_Score_TerEd = event.detail.value;
    }
    onchange_str_Qualification_GPA_Scale_TerEd(event) {
        this.str_Qualification_GPA_Scale_TerEd = event.detail.value;
    }
    onchange_selected_Qualification_GPA_Calc_Method_TerEd(event) {
        this.selected_Qualification_GPA_Calc_Method_TerEd = event.detail.value;
    }
    onchange_selected_Monash_Equivalent_GPA_TerEd(event) {
        this.selected_Monash_Equivalent_GPA_TerEd = event.detail.value;
    }
    onchange_str_Number_of_Fails_TerEd(event) {
        this.str_Number_of_Fails_TerEd = event.detail.value;
    }
    onchange_checked_USA_Accredited_TerEd(event) {
        this.checked_USA_Accredited_TerEd = event.detail.checked;
    }
    onchange_checked_Instruction_in_English_TerEd(event) {
        this.checked_Instruction_in_English_TerEd = event.detail.checked;
    }
    onchange_textArea_Assessment_Comments_TerEd(event) {
        this.textArea_Assessment_Comments_TerEd = event.detail.value;
    }
    onchange_selected_Verification_Status_TerEd(event) {
        this.selected_Verification_Status_TerEd = event.detail.value;
    }

    // Secondary Education functions section
    get options_Qualification_Country_SecEd() {
        var v_countryListOptions = [];
        v_countryListOptions.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.countryStudiedOptions !== undefined) {
            for (var key in this.fetchedData.countryStudiedOptions) {
                v_countryListOptions.push({label : this.fetchedData.countryStudiedOptions[key], value : key});
            }
        }
        return v_countryListOptions;
    }
    get options_State_SecEd() {
        var v_options_State_SecEd = [];
        v_options_State_SecEd.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.ausStateOptions !== undefined) {
            for (var key in this.fetchedData.ausStateOptions) {
                v_options_State_SecEd.push({label : this.fetchedData.ausStateOptions[key], value : key});
            }
        }
        return v_options_State_SecEd;
    }
    get options_Qualification_SecEd() {
        var v_options_Qualification_SecEd = [];
        v_options_Qualification_SecEd.push({label : '-- Select One --', value : ''});
        if (this.selected_Qualification_Country_SecEd !== undefined && this.selected_Qualification_Country_SecEd !== '' && this.selected_Qualification_Country_SecEd === 'Australia'
            && this.fetchedData !== undefined && this.fetchedData.qualificationOptions !== undefined) {
            for (var key in this.fetchedData.qualificationOptions) {
                if (this.fetchedData.qualificationOptions[key].Overseas__c === false && this.fetchedData.qualificationOptions[key].State__c === this.selectedAuState
                    && this.fetchedData.qualificationOptions[key].RecordType.Name === 'Secondary Qualification') {
                    v_options_Qualification_SecEd.push({ label: this.fetchedData.qualificationOptions[key].Qualification_Name__c, value: this.fetchedData.qualificationOptions[key].Id});
                }
            }
        } else if (this.selected_Qualification_Country_SecEd !== undefined && this.selected_Qualification_Country_SecEd !== '' && this.fetchedData !== undefined && this.fetchedData.qualificationOptions !== undefined) {
            for (var key in this.fetchedData.qualificationOptions) {
                if (this.fetchedData.qualificationOptions[key].Overseas__c === true && this.fetchedData.qualificationOptions[key].RecordType.Name === 'Secondary Qualification') {
                    v_options_Qualification_SecEd.push({ label: this.fetchedData.qualificationOptions[key].Qualification_Name__c, value: this.fetchedData.qualificationOptions[key].Id});
                }
            }
        }
        return v_options_Qualification_SecEd;
    }
    get options_Institution_Name_SecEd() {
        var v_options_Institution_Name_SecEd = [];
        v_options_Institution_Name_SecEd.push({label : '-- Select One --', value : ''});
        if (this.selected_Qualification_Country_SecEd !== undefined && this.selected_Qualification_Country_SecEd !== '' && this.fetchedData !== undefined && this.fetchedData.institutionOptions !== undefined) {
            var v_selected_Qualification_Country_SecEd = this.fetchedData.countryStudiedOptions[this.selected_Qualification_Country_SecEd] !== undefined ? this.fetchedData.countryStudiedOptions[this.selected_Qualification_Country_SecEd] : '';
            for (var key in this.fetchedData.institutionOptions) {
                if (this.fetchedData.institutionOptions[key].Country__c !== undefined && this.fetchedData.institutionOptions[key].Country__c !== null && this.fetchedData.institutionOptions[key].Country__c !== '') {
                    if (v_selected_Qualification_Country_SecEd === 'Australia' && this.selected_State_SecEd === this.fetchedData.institutionOptions[key].State__c
                            && this.fetchedData.institutionOptions[key].Type__c === 'Secondary' && this.fetchedData.institutionOptions[key].Country__c.toLowerCase() === v_selected_Qualification_Country_SecEd.toLowerCase()) {
                        v_options_Institution_Name_SecEd.push({ label : this.fetchedData.institutionOptions[key].Institution_Name__c, value : this.fetchedData.institutionOptions[key].Id });
                    }
                }
            }
        }
        return v_options_Institution_Name_SecEd;
    }
    get options_Qualification_GPA_Calc_Method_SecEd() {
        var v_options_Qualification_GPA_Calc_Method_SecEd = [];
        v_options_Qualification_GPA_Calc_Method_SecEd.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.qualificationGPACalcMethodOptions !== undefined) {
            for (var key in this.fetchedData.qualificationGPACalcMethodOptions) {
                v_options_Qualification_GPA_Calc_Method_SecEd.push({ label : this.fetchedData.qualificationGPACalcMethodOptions[key], value : key});
            }
        }
        return v_options_Qualification_GPA_Calc_Method_SecEd;
    }
    get options_Monash_Equivalent_GPA_SecEd() {
        var v_options_Monash_Equivalent_GPA_SecEd = [];
        v_options_Monash_Equivalent_GPA_SecEd.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.monashEquivalentGPAOptions !== undefined) {
            for (var key in this.fetchedData.monashEquivalentGPAOptions) {
                v_options_Monash_Equivalent_GPA_SecEd.push({ label : this.fetchedData.monashEquivalentGPAOptions[key], value : key})
            }
        }
        return v_options_Monash_Equivalent_GPA_SecEd;
    }
    get options_Verification_Status_SecEd() {
        var v_options_Verification_Status_SecEd = [];
        v_options_Verification_Status_SecEd.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.verificationStatusOptions !== undefined) {
            for (var key in this.fetchedData.verificationStatusOptions) {
                v_options_Verification_Status_SecEd.push({ label : this.fetchedData.verificationStatusOptions[key], value : key});
            }
        }
        return v_options_Verification_Status_SecEd;
    }
    onchange_selected_Qualification_Country_SecEd(event) {
        this.selected_Qualification_Country_SecEd = event.detail.value;

        // If selected country is Australia, set the English Language of Instruction to true by default
        if (this.fetchedData.countryStudiedOptions !== undefined && this.fetchedData.countryStudiedOptions[this.selected_Qualification_Country_SecEd] === 'Australia')
            this.checked_Instruction_in_English_SecEd = true;
        else
            this.checked_Instruction_in_English_SecEd = false;
    }
    onchange_selected_State_SecEd(event) {
        this.selected_State_SecEd = event.detail.value;
    }
    onchange_str_State_Province_SecEd(event) {
        this.str_State_Province_SecEd = event.detail.value;
    }
    onchange_selected_Qualification_SecEd(event) {
        this.selected_Qualification_SecEd = event.detail.value;
    }
    onchange_str_Other_Qualification_SecEd(event) {
        this.str_Other_Qualification_SecEd = event.detail.value;
    }
    onchange_selected_Institution_Name_SecEd(event) {
        this.selected_Institution_Name_SecEd = event.detail.value;
    }
    onchange_str_Other_Institution_SecEd(event) {
        this.str_Other_Institution_SecEd = event.detail.value;
    }
    onchange_checked_isTestCompleted_SecEd(event) {
        this.checked_isTestCompleted_SecEd = event.detail.checked;
    }
    onchange_str_Year_of_Completion_SecEd(event) {
        this.str_Year_of_Completion_SecEd = event.detail.value;
    }
    onchange_date_Expected_date_of_completion_SecEd(event) {
        this.date_Expected_date_of_completion_SecEd = event.detail.value;
    }
    onchange_textArea_Other_Qualification_Comments_SecEd(event) {
        this.textArea_Other_Qualification_Comments_SecEd = event.detail.value;
    }
    onchange_str_Score_SecEd(event) {
        this.str_Score_SecEd = event.detail.value;
    }
    onchange_str_Qualification_GPA_Scale_SecEd(event) {
        this.str_Qualification_GPA_Scale_SecEd = event.detail.value;
    }
    onchange_selected_Qualification_GPA_Calc_Method_SecEd(event) {
        this.selected_Qualification_GPA_Calc_Method_SecEd = event.detail.value;
    }
    onchange_selected_Monash_Equivalent_GPA_SecEd(event) {
        this.selected_Monash_Equivalent_GPA_SecEd = event.detail.value;
    }
    onchange_str_Number_of_Fails_SecEd(event) {
        this.str_Number_of_Fails_SecEd = event.detail.value;
    }
    onchange_checked_USA_Accredited_SecEd(event) {
        this.checked_USA_Accredited_SecEd = event.detail.checked;
    }
    onchange_checked_Instruction_in_English_SecEd(event) {
        this.checked_Instruction_in_English_SecEd = event.detail.checked;
    }
    onchange_selected_Verification_Status_SecEd(event) {
        this.selected_Verification_Status_SecEd = event.detail.value;
    }
    onchange_textArea_Assessment_Comments_SecEd(event) {
        this.textArea_Assessment_Comments_SecEd = event.detail.value;
    }

    // English Test
    get options_EnglishType_EngTest() {
        var v_options_EnglishType_EngTest = [];
        v_options_EnglishType_EngTest.push({label : '-- Select One --', value : ''});
        if (this.selectedRecordTypeValue !== undefined && this.selectedRecordTypeValue !== null && this.selectedRecordTypeValue !== ''
            && this.fetchedData !== undefined && this.fetchedData.admissionTestOptions !== undefined) {
            for (var key in this.fetchedData.admissionTestOptions) {
                v_options_EnglishType_EngTest.push({ label : this.fetchedData.admissionTestOptions[key], value : key});
            }
        }
        return v_options_EnglishType_EngTest;
    }
    get options_Monash_Equivalent_GPA_EngTest() {
        var v_options_Monash_Equivalent_GPA_EngTest = [];
        v_options_Monash_Equivalent_GPA_EngTest.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.monashEquivalentGPAOptions !== undefined) {
            for (var key in this.fetchedData.monashEquivalentGPAOptions) {
                v_options_Monash_Equivalent_GPA_EngTest.push({ label : this.fetchedData.monashEquivalentGPAOptions[key], value : key})
            }
        }
        return v_options_Monash_Equivalent_GPA_EngTest;
    }
    get options_Verification_Status_EngTest() {
        var v_options_Verification_Status_EngTest = [];
        v_options_Verification_Status_EngTest.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.verificationStatusOptions !== undefined) {
            for (var key in this.fetchedData.verificationStatusOptions) {
                v_options_Verification_Status_EngTest.push({ label : this.fetchedData.verificationStatusOptions[key], value : key});
            }
        }
        return v_options_Verification_Status_EngTest;
    }
    onchange_English_Test(event) {
        switch(event.target.name) {
            case 'name_selected_EnglishType_EngTest':
                this.selected_EnglishType_EngTest = event.detail.value;
                break;
            case 'name_checked_isTestCompleted_EngTest':
                this.checked_isTestCompleted_EngTest = event.detail.checked;
                break;
            case 'name_date_Date_Achieved_EngTest':
                this.date_Date_Achieved_EngTest = event.detail.value;
                break;
            case 'name_date_Expected_date_of_completion_EngTest':
                this.date_Expected_date_of_completion_EngTest = event.detail.value;
                break;
            case 'name_textArea_Other_Qualification_Comments_EngTest':
                this.textArea_Other_Qualification_Comments_EngTest = event.detail.value;
                break;
            case 'name_str_Score_EngTest':
                this.str_Score_EngTest = event.detail.value;
                break;
            case 'name_str_Listening_EngTest':
                this.str_Listening_EngTest = event.detail.value;
                break;
            case 'name_str_Reading_EngTest':
                this.str_Reading_EngTest = event.detail.value;
                break;
            case 'name_str_Speaking_EngTest':
                this.str_Speaking_EngTest = event.detail.value;
                break;
            case 'name_str_Writing_EngTest':
                this.str_Writing_EngTest = event.detail.value;
                break;
            case 'name_str_Test_of_Written_English_EngTest':
                this.str_Test_of_Written_English_EngTest = event.detail.value;
                break;
            case 'name_selected_Monash_Equivalent_GPA_EngTest':
                this.selected_Monash_Equivalent_GPA_EngTest = event.detail.value;
                break;
            case 'name_selected_Verification_Status_EngTest':
                this.selected_Verification_Status_EngTest = event.detail.value;
                break;
            case 'name_textArea_Assessment_Comments_EngTest':
                this.textArea_Assessment_Comments_EngTest = event.detail.value;
                break;
            default:
            //Default catch-all
        }
    }

    // Other Qualification functions
    get options_Verification_Status_OtherQual() {
        var v_options_Verification_Status_OtherQual = [];
        v_options_Verification_Status_OtherQual.push({label : '-- Select One --', value : ''});
        if (this.fetchedData !== undefined && this.fetchedData.verificationStatusOptions !== undefined) {
            for (var key in this.fetchedData.verificationStatusOptions) {
                v_options_Verification_Status_OtherQual.push({ label : this.fetchedData.verificationStatusOptions[key], value : key});
            }
        }
        return v_options_Verification_Status_OtherQual;
    }
    onchange_Other_Qualfication(event) {
        switch(event.target.name) {
            case 'name_str_Other_Qualification_OtherQual':
                this.str_Other_Qualification_OtherQual = event.detail.value;
                break;
            case 'name_checked_isTestCompleted_OtherQual':
                this.checked_isTestCompleted_OtherQual = event.detail.checked;
                break;
            case 'name_date_Date_Achieved_OtherQual':
                this.date_Date_Achieved_OtherQual = event.detail.value;
                break;
            case 'name_date_Expected_date_of_completion_OtherQual':
                this.date_Expected_date_of_completion_OtherQual = event.detail.value;
                break;
            case 'name_textArea_Other_Qualification_Comments_OtherQual':
                this.textArea_Other_Qualification_Comments_OtherQual = event.detail.value;
                break;
            case 'name_str_Score_OtherQual':
                this.str_Score_OtherQual = event.detail.value;
                break;
            case 'name_selected_Verification_Status_OtherQual':
                this.selected_Verification_Status_OtherQual = event.detail.value;
                break;
            case 'name_textArea_Assessment_Comments_OtherQual':
                this.textArea_Assessment_Comments_OtherQual = event.detail.value;
                break;
            default:
            //Default catch-all
        }
    }
    saveContactQualification() {
        this.errMsgList = [];
        if (this.selectedRecordTypeValue === undefined || this.selectedRecordTypeValue === null || this.selectedRecordTypeValue === '') {
            this.errMsgList.push('Please select type of Qualification and fill the information');
        } else {
            var qualificationRecordTypeName = this.fetchedData.qualificationRecordTypeOptions[this.selectedRecordTypeValue];
            if (qualificationRecordTypeName === 'Tertiary Education') {
                this.validateTertiaryQualificationDetails();
                if (Array.isArray(this.errMsgList) && this.errMsgList.length === 0) {
                    this.errMsgList = null;
                    this.createTertiaryQualification();
                }
            }
            if (qualificationRecordTypeName === 'Secondary Education') {
                //this.showSecondary = true;
                this.validateSecondaryQualificationDetails();
                if (Array.isArray(this.errMsgList) && this.errMsgList.length === 0) {
                    this.errMsgList = null;
                    this.createSecondaryQualification();
                }
            }
            if (qualificationRecordTypeName === 'Other Qualification') {
                this.validateOtherQualification();
                if (Array.isArray(this.errMsgList) && this.errMsgList.length === 0) {
                    this.errMsgList = null;
                    this.createOtherQualification();
                }
            }
            if (qualificationRecordTypeName === 'English Test') {
                this.validateEnglishTestDetails();
                if (Array.isArray(this.errMsgList) && this.errMsgList.length === 0) {
                    this.errMsgList = null;
                    this.createEnglishTest();
                }
            }
        }
    }

    validateTertiaryQualificationDetails() {
        this.errMsgList = [];
        var dateRegexFormat = /(19|20)\d{2}/;

        if (this.selected_Country_TerEd === undefined || this.selected_Country_TerEd === null || this.selected_Country_TerEd === '') {
            this.errMsgList.push('Qualification Country is required');
        }
        if (this.str_Other_Qualification_TerEd === undefined || this.str_Other_Qualification_TerEd === null || this.str_Other_Qualification_TerEd === '') {
            this.errMsgList.push('Other Qualification is required');
        }
        if ((this.selected_Institution_Name_TerEd === undefined || this.selected_Institution_Name_TerEd === null || this.selected_Institution_Name_TerEd === '')
            && (this.str_Other_Institution_TerEd === undefined || this.str_Other_Institution_TerEd === null || this.str_Other_Institution_TerEd === '')) {
            this.errMsgList.push('Awarding Body/Institution Name or Other Awarding Body/Institution is required');
        }
        if (this.str_First_Year_Enrolled_TerEd !== undefined && this.str_First_Year_Enrolled_TerEd !== null
            && this.str_First_Year_Enrolled_TerEd !== '' && !dateRegexFormat.test(this.str_First_Year_Enrolled_TerEd)) {
            this.errMsgList.push('Please enter a valid year for First Year Enrolled');
        }
        if (this.str_Last_Year_Enrolled_TerEd !== undefined && this.str_Last_Year_Enrolled_TerEd !== null
            && this.str_Last_Year_Enrolled_TerEd !== '' && !dateRegexFormat.test(this.str_Last_Year_Enrolled_TerEd)) {
            this.errMsgList.push('Please enter a valid year for Last Year Enrolled');
        }
        /*if (this.str_First_Year_Enrolled_TerEd > this.str_Last_Year_Enrolled_TerEd) {
            this.errMsgList.push('Last Year Enrolled must be later than First Year Enrolled');
        }*/
        if (this.selected_Status_TerEd === undefined || this.selected_Status_TerEd === null || this.selected_Status_TerEd === '') {
            this.errMsgList.push('Level of Completion is required');
        }
    }

    createTertiaryQualification() {
        let contactQualification = { 'sobjectType': 'Contact_Qualification__c' };
        contactQualification.RecordTypeId = this.selectedRecordTypeValue;
        contactQualification.Qualification_Country__c = this.selected_Country_TerEd;
        contactQualification.Other_Qualification__c = this.str_Other_Qualification_TerEd;

        if (this.selected_Institution_Name_TerEd !== undefined && this.selected_Institution_Name_TerEd !== null && this.selected_Institution_Name_TerEd !== '') {
            var institutionName = this.fetchedData.institutionOptions[this.selected_Institution_Name_TerEd];
            contactQualification.Institution_Name__c = institutionName.Institution_Name__c;
            contactQualification.Institution_Code__c = institutionName.Institution_Code__c;
        }
        
        contactQualification.Other_Institution__c = this.str_Other_Institution_TerEd;
        contactQualification.First_Year_Enrolled__c = this.str_First_Year_Enrolled_TerEd;
        contactQualification.Last_Year_Enrolled__c = this.str_Last_Year_Enrolled_TerEd;
        contactQualification.Status__c = this.selected_Status_TerEd;
        contactQualification.Instruction_in_English__c = this.checked_Instruction_in_English_TerEd;

        // Not required fields
        //contactQualification.Title__c = this.str_Title_TerEd;
        contactQualification.Year_of_Completion__c = this.str_Year_of_Completion_TerEd;
        contactQualification.Other_Qualification_Comments__c = this.textArea_Other_Qualification_Comments_TerEd;
        contactQualification.Tertiary_Qualification_Level__c = this.selected_QualificationLevel_TertiaryEducation;
        contactQualification.Score__c = this.str_Score_TerEd;
        contactQualification.Qualification_GPA_Scale__c = this.str_Qualification_GPA_Scale_TerEd;
        contactQualification.Qualification_GPA_Calc_Method__c = this.selected_Qualification_GPA_Calc_Method_TerEd;
        contactQualification.Monash_Equivalent_GPA__c = this.selected_Monash_Equivalent_GPA_TerEd;
        contactQualification.Number_of_Fails__c = this.str_Number_of_Fails_TerEd;
        contactQualification.USA_Accredited__c = this.checked_USA_Accredited_TerEd;
        contactQualification.Assessment_Comments__c = this.textArea_Assessment_Comments_TerEd;
        contactQualification.Verification_Status__c = this.selected_Verification_Status_TerEd;

        this.doServerCall(contactQualification);
    }

    // Validation rules for Secondary Qualification
    validateSecondaryQualificationDetails() {
        this.errMsgList = [];
        var dateRegexFormat = /(19|20)\d{2}/;

        if (this.selected_Qualification_Country_SecEd === undefined || this.selected_Qualification_Country_SecEd === null || this.selected_Qualification_Country_SecEd === '') {
            this.errMsgList.push('Qualification Country is required');
        }
        var selectedCountrySecQual = this.fetchedData.countryStudiedOptions[this.selected_Qualification_Country_SecEd];
        if (selectedCountrySecQual === 'Australia') {
            if (this.selected_State_SecEd === undefined || this.selected_State_SecEd === null || this.selected_State_SecEd === '') {
                this.errMsgList.push('Australian State is required');
            }
        }
        if (selectedCountrySecQual === 'China (excludes SARs and Taiwan)' || selectedCountrySecQual === 'India') {
            if (this.str_State_Province_SecEd === undefined || this.str_State_Province_SecEd === null || this.str_State_Province_SecEd === '') {
                this.errMsgList.push('State/Province is required');
            }
        }
        if ((this.selected_Qualification_SecEd === undefined || this.selected_Qualification_SecEd === null || this.selected_Qualification_SecEd === '')
            && (this.str_Other_Qualification_SecEd === undefined || this.str_Other_Qualification_SecEd === null || this.str_Other_Qualification_SecEd === '')) {
            this.errMsgList.push('Qualification Name or Other Qualification is required');
        }
        if ((this.selected_Institution_Name_SecEd === undefined || this.selected_Institution_Name_SecEd === null || this.selected_Institution_Name_SecEd === '')
            && (this.str_Other_Institution_SecEd === undefined || this.str_Other_Institution_SecEd === null || this.str_Other_Institution_SecEd === '')) {
            this.errMsgList.push('Awarding Body/Institution Name or Other Awarding Body/Institution is required');
        }
        if (this.checked_isTestCompleted_SecEd) {
            if (this.str_Year_of_Completion_SecEd === undefined || this.str_Year_of_Completion_SecEd === null || this.str_Year_of_Completion_SecEd === '') {
                this.errMsgList.push('Year of Completion is required');
            } else {
                var currentDate = new Date();
                var yearCompletionCurrentDate = new Date();
                yearCompletionCurrentDate.setFullYear(parseInt(this.str_Year_of_Completion_SecEd));
                if (yearCompletionCurrentDate > currentDate) {
                    this.errMsgList.push('Completion Year must be less than or equal to the Current Year');
                }
            }

        }
        if (!this.checked_isTestCompleted_SecEd) {
            if (this.date_Expected_date_of_completion_SecEd === undefined || this.date_Expected_date_of_completion_SecEd === null || this.date_Expected_date_of_completion_SecEd === '') {
                this.errMsgList.push('Expected Completion Date is required');
            } else {
                var dateToday = new Date();
                var dateValue = new Date(this.date_Expected_date_of_completion_SecEd);
                if (dateValue < dateToday) {
                    this.errMsgList.push('Expected Completion Date must be in future date');
                }
            }
        }
    }

    createSecondaryQualification() {
        let contactQualification = { 'sobjectType': 'Contact_Qualification__c' };
        contactQualification.RecordTypeId = this.selectedRecordTypeValue;
        contactQualification.Qualification_Country__c = this.selected_Qualification_Country_SecEd;

        var selectedCountrySecQual = this.fetchedData.countryStudiedOptions[this.selected_Qualification_Country_SecEd];
        if (selectedCountrySecQual === 'Australia') {
            contactQualification.State__c = this.selected_State_SecEd;
        }
        if (selectedCountrySecQual === 'China (excludes SARs and Taiwan)' || selectedCountrySecQual === 'India') {
            contactQualification.State_Province__c = this.str_State_Province_SecEd;
        }
        
        contactQualification.Qualification__c = this.selected_Qualification_SecEd;
        contactQualification.Other_Qualification__c = this.str_Other_Qualification_SecEd;
        
        if (this.selected_Institution_Name_SecEd !== undefined && this.selected_Institution_Name_SecEd !== null && this.selected_Institution_Name_SecEd !== '') {
            var school = this.fetchedData.institutionOptions[this.selected_Institution_Name_SecEd];
            contactQualification.Institution_Name__c = school.Institution_Name__c;
            contactQualification.Institution_Code__c = school.Institution_Code__c;
        }
        contactQualification.Other_Institution__c = this.str_Other_Institution_SecEd;
        
        contactQualification.Year_of_Completion__c = this.str_Year_of_Completion_SecEd;
        contactQualification.Expected_date_of_completion__c = this.date_Expected_date_of_completion_SecEd;
        contactQualification.isTestCompleted__c = this.checked_isTestCompleted_SecEd;
        contactQualification.Instruction_in_English__c = this.checked_Instruction_in_English_SecEd;
        contactQualification.Other_Qualification_Comments__c = this.textArea_Other_Qualification_Comments_SecEd;

        // Additional Fields
        contactQualification.Score__c = this.str_Score_SecEd;
        contactQualification.Qualification_GPA_Scale__c = this.str_Qualification_GPA_Scale_SecEd;
        contactQualification.Qualification_GPA_Calc_Method__c = this.selected_Qualification_GPA_Calc_Method_SecEd;
        contactQualification.Monash_Equivalent_GPA__c = this.selected_Monash_Equivalent_GPA_SecEd;
        contactQualification.Number_of_Fails__c = this.str_Number_of_Fails_SecEd;
        contactQualification.USA_Accredited__c = this.checked_USA_Accredited_SecEd;
        contactQualification.Verification_Status__c = this.selected_Verification_Status_SecEd;
        contactQualification.Assessment_Comments__c = this.textArea_Assessment_Comments_SecEd;

        this.doServerCall(contactQualification);
    }

    // Validation rules for English Test
    validateEnglishTestDetails() {
        this.errMsgList = [];

        if (this.selected_EnglishType_EngTest === undefined || this.selected_EnglishType_EngTest === null || this.selected_EnglishType_EngTest === '') {
            this.errMsgList.push('English Qualification Type is required');
        }
        if (this.checked_isTestCompleted_EngTest) {
            if (this.date_Date_Achieved_EngTest === undefined || this.date_Date_Achieved_EngTest === null) {
                this.errMsgList.push('Date Achieved is required');
            } else {
                var dateToday = new Date();
                var dateValue = new Date(this.date_Date_Achieved_EngTest);
                if (dateValue > dateToday) {
                    this.errMsgList.push('Date Achieved must be in the past');
                }
            }
        }
        if (!this.checked_isTestCompleted_EngTest) {
            if (this.date_Expected_date_of_completion_EngTest === undefined || this.date_Expected_date_of_completion_EngTest === null) {
                this.errMsgList.push('Expected Completion Date is required');
            } else {
                var dateToday = new Date();
                var dateValue = new Date(this.date_Expected_date_of_completion_EngTest);
                if (dateValue < dateToday) {
                    this.errMsgList.push('Expected Completion Date must be in future date');
                }
            }
        }
    }

    createEnglishTest() {
        let contactQualification = { 'sobjectType': 'Contact_Qualification__c' };
        contactQualification.RecordTypeId = this.selectedRecordTypeValue;
        contactQualification.Qualification__c = this.selected_EnglishType_EngTest;
        contactQualification.isTestCompleted__c = this.checked_isTestCompleted_EngTest;
        contactQualification.Date_Achieved__c = this.date_Date_Achieved_EngTest;
        contactQualification.Expected_date_of_completion__c = this.date_Expected_date_of_completion_EngTest;

        // Additional Fields
        contactQualification.Other_Qualification_Comments__c = this.textArea_Other_Qualification_Comments_EngTest;
        contactQualification.Score__c = this.str_Score_EngTest;
        contactQualification.Listening__c = this.str_Listening_EngTest;
        contactQualification.Reading__c = this.str_Reading_EngTest;
        contactQualification.Speaking__c = this.str_Speaking_EngTest;
        contactQualification.Writing__c = this.str_Writing_EngTest;
        contactQualification.Test_of_Written_English__c = this.str_Test_of_Written_English_EngTest;
        contactQualification.Monash_Equivalent_GPA__c = this.selected_Monash_Equivalent_GPA_EngTest;
        contactQualification.Verification_Status__c = this.selected_Verification_Status_EngTest;
        contactQualification.Assessment_Comments__c = this.textArea_Assessment_Comments_EngTest;
        contactQualification.Source_Channel__c = 'Manual';

        this.doServerCall(contactQualification);
    }

    // Validation rules for Other Qualification
    validateOtherQualification() {
        this.errMsgList = [];

        if (this.str_Other_Qualification_OtherQual === undefined || this.str_Other_Qualification_OtherQual === null || this.str_Other_Qualification_OtherQual === '') {
            this.errMsgList.push('Other Qualification is required');
        }
    }

    createOtherQualification() {
        let contactQualification = { 'sobjectType': 'Contact_Qualification__c' };
        contactQualification.RecordTypeId = this.selectedRecordTypeValue;
        contactQualification.Other_Qualification__c = this.str_Other_Qualification_OtherQual;

        // Additional Details
        contactQualification.isTestCompleted__c = this.checked_isTestCompleted_OtherQual;
        contactQualification.Date_Achieved__c = this.date_Date_Achieved_OtherQual;
        contactQualification.Expected_date_of_completion__c = this.date_Expected_date_of_completion_OtherQual;
        contactQualification.Other_Qualification_Comments__c = this.textArea_Other_Qualification_Comments_OtherQual;
        contactQualification.Score__c = this.str_Score_OtherQual;
        contactQualification.Verification_Status__c = this.selected_Verification_Status_OtherQual;
        contactQualification.Assessment_Comments__c = this.textArea_Assessment_Comments_OtherQual;

        this.doServerCall(contactQualification);
    }

    doServerCall(contactQualification) {
        this.disableSaveBtn = true;
        this.disableCancelBtn = true;
        this.showSpinner = true;
        createQualification({sObjectId : this.recordId, jsonContactQualification : JSON.stringify(contactQualification)})
        .then(result => {
            if (result.status === 'success') {
                this.showToast('Success', 'Record successfully created.', 'success');
            } else if (result.status === 'error') {
                this.showToast('Error', 'Something went wrong while processing your request. Please contact your system administrator.', 'error');
            }
            this.clearAllFields();
            this.closeModal();
        })
        .catch(err => {
            this.showToast('Error', 'Something went wrong while processing your request. Please contact your system administrator.', 'error');
            this.clearAllFields();
            this.closeModal();
        });
    }

    cancel() {
        refreshApex(this.wiredFetchedData);
        this.clearAllFields();
        this.closeModal();
    }
    
    closeModal() {
        const closeModalEvent = new CustomEvent('closemodal', {
            data: { 'message' : 'close modal' }
        });
        // Fire the custom event
        this.dispatchEvent(closeModalEvent);
    }

    onClickCloseAlert() {
        this.errMsgList = null;
    }

    showToast(pTitle, pMessage, pType) {
        this.showSpinner = false;
        const event = new ShowToastEvent({
            title: pTitle,
            message: pMessage,
            variant: pType
        });
        this.dispatchEvent(event);
    }

    clearAllFields() {
        this.disableSaveBtn = true;
        this.disableCancelBtn = false;
        // Clear Record Type
        this.selectedRecordTypeValue = null;

        // Tertiary Details
        this.selected_Country_TerEd = '';
        //this.str_Title_TerEd = '';
        this.str_Other_Qualification_TerEd = '';
        this.selected_Institution_Name_TerEd = '';
        this.str_Other_Institution_TerEd = '';
        this.selected_Status_TerEd = '';
        this.str_First_Year_Enrolled_TerEd = '';
        this.str_Last_Year_Enrolled_TerEd = '';
        this.str_Year_of_Completion_TerEd = '';
        this.textArea_Other_Qualification_Comments_TerEd = '';
        this.selected_QualificationLevel_TertiaryEducation = '';
        this.str_Score_TerEd = '';
        this.str_Qualification_GPA_Scale_TerEd = '';
        this.selected_Qualification_GPA_Calc_Method_TerEd = '';
        this.selected_Monash_Equivalent_GPA_TerEd = '';
        this.str_Number_of_Fails_TerEd = '';
        this.checked_USA_Accredited_TerEd = false;
        this.checked_Instruction_in_English_TerEd = false;
        this.textArea_Assessment_Comments_TerEd = '';
        this.selected_Verification_Status_TerEd = '';

        // Secondary Education
        this.selected_Qualification_Country_SecEd = '';
        this.selected_State_SecEd = '';
        this.str_State_Province_SecEd = '';
        this.selected_Qualification_SecEd = '';
        this.str_Other_Qualification_SecEd = '';
        this.selected_Institution_Name_SecEd = '';
        this.str_Other_Institution_SecEd = '';
        this.checked_isTestCompleted_SecEd = false;
        this.str_Year_of_Completion_SecEd = '';
        this.date_Expected_date_of_completion_SecEd = null;
        this.textArea_Other_Qualification_Comments_SecEd = '';
        this.str_Score_SecEd = '';
        this.str_Qualification_GPA_Scale_SecEd = '';
        this.selected_Qualification_GPA_Calc_Method_SecEd = '';
        this.selected_Monash_Equivalent_GPA_SecEd = '';
        this.str_Number_of_Fails_SecEd = '';
        this.checked_USA_Accredited_SecEd = false;
        this.checked_Instruction_in_English_SecEd = false;
        this.selected_Verification_Status_SecEd = '';
        this.textArea_Assessment_Comments_SecEd = '';

        // English Test
        this.selected_EnglishType_EngTest = '';
        this.checked_isTestCompleted_EngTest = false;
        this.date_Date_Achieved_EngTest = null;
        this.date_Expected_date_of_completion_EngTest = null;
        this.textArea_Other_Qualification_Comments_EngTest = '';
        this.str_Score_EngTest = '';
        this.str_Listening_EngTest = '';
        this.str_Reading_EngTest = '';
        this.str_Speaking_EngTest = '';
        this.str_Writing_EngTest = '';
        this.str_Test_of_Written_English_EngTest = '';
        this.selected_Monash_Equivalent_GPA_EngTest = '';
        this.selected_Verification_Status_EngTest = '';
        this.textArea_Assessment_Comments_EngTest = '';

        // Other Qualification
        this.str_Other_Qualification_OtherQual = '';
        this.checked_isTestCompleted_OtherQual = false;
        this.date_Date_Achieved_OtherQual = null;
        this.date_Expected_date_of_completion_OtherQual = null;
        this.textArea_Other_Qualification_Comments_OtherQual = '';
        this.str_Score_OtherQual = '';
        this.selected_Verification_Status_OtherQual = false;
        this.textArea_Assessment_Comments_OtherQual = '';
    }
}