import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class FlowModal extends LightningModal {
    @api flowApiName;
    @api flowInputVariables;
    @api modalHeader;
    @api modalSubHeader;

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') 
        {
            this.close();
        }
    }
}