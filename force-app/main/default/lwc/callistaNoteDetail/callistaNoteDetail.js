import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class CallistaNoteDetail extends LightningModal {
    @api record;

    handleDone() {
        this.close();
    }
}