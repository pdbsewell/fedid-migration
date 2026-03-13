import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class QuestionForm extends LightningElement {
    questions = [];
    @api questionmap;
    @api dragMap;
    @api formid;
    @api outputformid;
    @api inputValueList;


    showLibraryModal = false;
    connectedCallback() {

        if (this.inputValueList) {

            this.questionmap = new Map();
            let tempArray = JSON.parse(JSON.stringify(this.inputValueList));
            //push parent records with an empty child array and set index
            tempArray.forEach((arrayElement, index) => {
                arrayElement.index = index;
                arrayElement.uniqueId = this.generateUniqueId();
                this.questionmap.set(arrayElement.uniqueId, { ...arrayElement, children: [] });

            });

            tempArray.forEach(arrayElement => {
                const parentId = arrayElement.Parent_Element__c;
                if (parentId) {

                    // Find the parent record by the ID set in the Parent_Element__c field
                    const parentRecord = Array.from(this.questionmap.values()).find(element => element.Id === parentId);

                    if (parentRecord) {
                        parentRecord.children.push(arrayElement.uniqueId);

                    }
                }
            });
            this.questions = JSON.parse(JSON.stringify(tempArray));
        }
    }

    generateUniqueId() {
        // Generate a random unique ID
        return crypto.randomUUID();
    }

    onDragStart(evt) {

        this.dragMap = new Map();

        let eventRowDataId = evt.currentTarget.dataset.dragId;
        let eventRowKey = evt.currentTarget.dataset.key;

        let currentRowRef = this.questionmap.get(eventRowKey);
        this.dragMap.set(eventRowKey, currentRowRef);

        if (currentRowRef.children.length > 0) {
            for (let i = 0; i < currentRowRef.children.length; i++) {
                let childId = currentRowRef.children[i];

                let childrow = this.questionmap.get(childId);

                this.dragMap.set(childrow.uniqueId, childrow);

                let childElm = this.template.querySelector(`[data-key="${childrow.uniqueId}"]`);
                childElm.classList.add("grabbed");

            }
        }

        evt.dataTransfer.setData("dragId", eventRowDataId);
        evt.dataTransfer.setData("sy", evt.pageY);
        evt.dataTransfer.effectAllowed = "move";
        evt.currentTarget.classList.add("grabbed");

    }

    onDragOver(evt) {
        evt.preventDefault();
        evt.dataTransfer.dropEffect = "move";
    }

    onDrop(evt) {
        evt.preventDefault();
        let eventRowDataId = evt.currentTarget.dataset.dragId;
        let sourceId = evt.dataTransfer.getData("dragId");
        const sy = evt.dataTransfer.getData("sy");
        const cy = evt.pageY;

        if (cy > sy) {
            //this.dragMap.forEach((value, key, map) => {
            Array.from(this.dragMap).reverse().forEach(element => {
                let key = element[0];
                const elm = this.template.querySelector(`[data-key="${key}"]`);
                if (!!elm) {
                    elm.classList.remove("grabbed");
                }
                evt.currentTarget.parentElement.insertBefore(elm, evt.currentTarget.nextElementSibling);
            });

        } else {

            this.dragMap.forEach((value, key, map) => {

                const elm = this.template.querySelector(`[data-key="${key}"]`);
                if (!!elm) {
                    elm.classList.remove("grabbed");
                }
                evt.currentTarget.parentElement.insertBefore(elm, evt.currentTarget);
            });

        }

        this.processRowNumbers();
    }

    processRowNumbers() {
        const trs = this.template.querySelectorAll(".myIndex");
        const ids = this.template.querySelectorAll(".myId");
        for (let i = 0; i < trs.length; i++) {
            let currentRowId = ids[i].innerText;
            let currentRowRef = this.questionmap.get(currentRowId);
            currentRowRef.index = i;
            this.questionmap.set(currentRowId, currentRowRef);//modify ref to the question table
            trs[i].innerText = i;
        }
        this.questions = Array.from(this.questionmap.values());
    }

    handleSaveOrder() {

        for (let i = 0; i < this.questions.length; i++) {
            this.questions[i].Element_Sequence__c = this.questions[i].index;
        }
        this.inputValueList = this.questions;
        const appevent = new FlowAttributeChangeEvent('inputValueList', this.inputValueList);

        this.dispatchEvent(appevent);
    }

    handleNext() {

        this.handleSaveOrder();
        setTimeout(() => {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }, 1);

    }

}