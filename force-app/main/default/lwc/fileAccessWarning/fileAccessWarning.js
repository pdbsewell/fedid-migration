import { LightningElement } from 'lwc';
import FILE_ACCESS_WARNING from '@salesforce/resourceUrl/fileaccesswarning';

export default class FileAccessWarning extends LightningElement {

    connectedCallbackRun = false;
    fileAccessWarning;

    connectedCallback() {
        if (this.connectedCallbackRun) {
            return;
        }

        this.connectedCallbackRun = true;
        this.loadMessageContent();
    }

    async loadMessageContent() {
        try {
            const response = await fetch(FILE_ACCESS_WARNING);
            if (!response.ok) {
                throw new Error('Failed to retrieve message content');
            }
            this.fileAccessWarning = await response.text();
            console.log('File warning: ' + this.fileAccessWarning);
        } catch (error) {
            console.error('Error loading message content: ', error);
        }
    }

}