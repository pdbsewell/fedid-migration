/* base components */
import { LightningElement, api, wire } from 'lwc';
/* custom methods */
import retrieveApplicantCommunityUser from '@salesforce/apex/DocumentChecklistAssessmentServices.retrieveApplicantCommunityUser';

/**
 *  @author APRivera
 *  @date 04-05-2025
 *  @group My App Application for English Test
 *  @description used to group the documents based on the checklist type or Contact Qualification Record type
 **/
export default class DocumentEnglishTestChecklistAssessmentCommunityGroup extends LightningElement {
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
                if(element.name === tileName) {
                    element.isVisible = !element.isVisible
                }
            })
            this.nestedChecklistItems = items
        } else {
            this.isOtherDocumentSelected = !this.isOtherDocumentSelected;
        }
    }

    connectedCallback() {
        let mapOfItems = [];
        if (this.checklistItems && !this.nestedChecklistItems) {
            this.checklistItems.forEach(element => {
                let groupName;

                if (element.Contact_Qualification__r) {
                    // Group by Qualification Type
                    const qualificationType = element.Contact_Qualification__r.Qualification_Type__c;
                    switch (qualificationType) {
                        case 'Tertiary Education':
                        case 'Secondary Education':
                        case 'Other Qualification':
                            groupName = 'ACADEMIC QUALIFICATIONS';
                            break;
                        case 'English Test':
                            groupName = 'ENGLISH PROFICIENCY';
                            break;
                        default:
                            groupName = qualificationType;
                    }
                } else {
                    // Group by Checklist Type
                    const checklistRequirement = element.Checklist_Requirement__c;
                    if ([
                        'On-Site Supervisor Form',
                        'Attendance and Appointment Commitments',
                        'Sponsorship/Scholarship Letter',
                        'Research Program Research Proposal',
                        'Research Program Invitation Details'
                    ].includes(checklistRequirement)) {
                        groupName = 'Research Program';
                    } else if (checklistRequirement === 'Nomination of Agent Form') {
                        groupName = 'Agent';
                    } else if (element.Application__c !== undefined && element.Application__r?.Type_of_Study__c === 'Graduate Research') {
                        groupName = 'Application Documents';
                    } else {
                        groupName = (element.Type__c === 'Residency' || element.Type__c === 'Name Change')
                            ? 'PERSONAL DETAILS' : element.Type__c;
                    }
                }

                // Add to mapOfItems using uppercase groupName
                this.getMapOfItems(mapOfItems, element, groupName.toUpperCase());
            });

            this.nestedChecklistItems = mapOfItems;
        }
    }

    /**
     * forming the map based on the group name
     * @param mapOfItems
     * @param element
     * @param groupName
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
    }
}