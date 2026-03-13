import { LightningElement, api, wire } from 'lwc';
import FlowModal from 'c/flowModal';
import { CurrentPageReference } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';

/**
*  @description launch flow in a modal
**/
export default class LaunchFlowButton extends LightningElement {

    //global variables
    @api flowApiName; 
    @api buttonLabel;
    @api horizontalAlign;
    @api modalSize;
    @api modalHeader;
    @api modalSubHeader;

    //local variables
    recordId;


    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
       if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
       }
    }

    /**
    * @description  method to open a modal with input variables
    * @inputs       recordId = relatedToId on the task
    * @inputs       recordTypeId = recordTypeId of the task
    * @inputs       flowApiName = API name of the create task flow to launch
    * @returns      N/A
    **/
    async openModal() {
        const flowInputVariable =[
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
        const result = await FlowModal.open({
            description: 'Flow Modal',
            flowApiName: this.flowApiName,
            flowInputVariables: flowInputVariable,
            size: this.modalSize,
            label: this.buttonLabel,
            modalHeader: this.modalHeader,
            modalSubHeader: this.modalSubHeader
        }).then((result) => {
            this.dispatchEvent(new RefreshEvent());
        });
    }

}