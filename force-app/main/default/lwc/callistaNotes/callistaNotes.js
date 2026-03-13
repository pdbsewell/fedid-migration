import { LightningElement, api } from 'lwc';
import CallistaNoteDetail from 'c/callistaNoteDetail';

export default class CallistaNotes extends LightningElement {
    @api recordId;

    async handleRecordClick(event){
        await CallistaNoteDetail.open({
            size: 'small',
            record: event.detail.record,
        });
    }
}