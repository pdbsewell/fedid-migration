/* base components */
import { LightningElement, api, wire } from 'lwc';
/* custom methods */
import retrieveApplicantCommunityUser from '@salesforce/apex/DocumentChecklistAssessmentServices.retrieveApplicantCommunityUser';

/**
*  @author Vishal Gupta
*  @date 5-08-2024
*  @group My App Application for graduate research
*  @description used to group the documents based on the checklist type or Contact Qualification Record type 
**/
export default class DocumentChecklistAssessmentCommunityGroup extends LightningElement {
    @api applicationId;
    @api applicantId;
    @api applicationName;
    @api applicationStudyType;
    @api applicationStatus;
    @api checklistItems;
    nestedChecklistItems
    isOtherDocumentSelected = true
    
    @wire(retrieveApplicantCommunityUser, { applicationId: '$applicationId' })
    applicantCommunityUser;

    //Fire preview document request sending back the event to the parent aura component
    onFilePreview(event) {
        //file preview event
        const filePreviewEvent = new CustomEvent('filepreview', {
            detail: { documentId: event.detail.documentId }
        });
        this.dispatchEvent(filePreviewEvent);
    }

    handleDocumentsSectionClick(event) {
        var tileName = event.currentTarget.dataset.id
        if(tileName) {
            var items = [...this.nestedChecklistItems]
            this.nestedChecklistItems = []
            items.forEach(element => {
                if(element.name == tileName) {
                    element.isVisible = !element.isVisible
                }
            })
            this.nestedChecklistItems = items
        } else {
            this.isOtherDocumentSelected = !this.isOtherDocumentSelected;
        }        
    }
    
    connectedCallback() {
        let mapOfItems = []
        if(this.checklistItems && !this.nestedChecklistItems) {
            this.checklistItems.forEach(element => {
                if(element.Contact_Qualification__r) {//if checklist is associated with contact qualification, the group it with Qualification Type (record type)
                    var groupName = element.Contact_Qualification__r.Qualification_Type__c
                    if(element.Contact_Qualification__r.Qualification_Type__c == 'Tertiary Education') {
                        groupName = 'Qualifications'
                    } else if(element.Contact_Qualification__r.Qualification_Type__c == 'Other Qualification') {
                        groupName = 'Additional Supporting Information'
                    }else if(element.Contact_Qualification__r.Qualification_Type__c == 'Referees') {
                        groupName = 'Referee Reports (optional)'
                    } else if(element.Contact_Qualification__r.Qualification_Type__c == 'English Test') {
                        groupName = 'English Language Proficiency Verification'
                    }
                    this.getMapOfItems(mapOfItems, element, groupName)
                }
                else { //if checklist is not associated with contact qualification, the group it with checklist Type
                    var groupName
                    if(element.Checklist_Requirement__c == 'On-Site Supervisor Form' ||
                        element.Checklist_Requirement__c == 'Attendance and Employment Commitments' ||
                        element.Checklist_Requirement__c == 'Sponsorship/Scholarship Letter' ||
                        element.Checklist_Requirement__c == 'Research Program Research Proposal' ||
                        element.Checklist_Requirement__c == 'Research Program Invitation Details'
                    ) {//if checklist is related to research program then create a new group
                        groupName = 'Research Program'
                    }
                    else if(element.Checklist_Requirement__c == 'Nomination of Agent Form') {  //if checklist is related to agent then make a new group
                        groupName = 'Agent'
                    } else if(element.Application__c != undefined && JSON.parse(JSON.stringify(element.Application__r.Type_of_Study__c)) == 'Graduate Research') {
                        groupName = 'Application Documents'
                    } else {
                        groupName = element.Type__c
                    }
                    this.getMapOfItems(mapOfItems, element, groupName)
                }
                
            });
            this.nestedChecklistItems = mapOfItems                          
        }
    }

    /**
     * forming the map based on the group name
     * @param mapOfItems, element, groupName
     */
    getMapOfItems(mapOfItems, element, groupName) {
        if(mapOfItems?.find((item) => item.name == groupName)) {
            mapOfItems.find((item) => item.name == groupName).value.push(element)
        } else {
            mapOfItems.push({
                isVisible : true,
                name: groupName,
                value: [element]
            })                   
        }
        // List of specific group names that need to be sorted
        const groupNamesToSort = ['Qualifications', 'Additional Supporting Information', 'Referee Reports (optional)'];

        // Check if the provided group name is one that requires sorting
        if (groupNamesToSort.includes(groupName)) {
            let qualificationsGroup = mapOfItems?.find((item) => item.name == groupName);

            // If the group exists and has more than one item, we perform sorting
            if(qualificationsGroup?.value?.length > 1) {
                // Sort the value array of the group by the Name field on Contact Qualification
                    qualificationsGroup?.value.sort((a, b) => {
                    const nameA = a.Contact_Qualification__r?.Name || '';
                    const nameB = b.Contact_Qualification__r?.Name || '';
                    return nameA.toLowerCase().localeCompare(nameB.toLowerCase());
                });
            }
        }
    }
}