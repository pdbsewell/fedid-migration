import LightningDatatable from "lightning/datatable";
import richTextTemplate from "./richText.html";

import stylesheet from '@salesforce/resourceUrl/listViewDatatableStyles';
import {loadStyle} from "lightning/platformResourceLoader";

export default class ListViewDatatable extends LightningDatatable {
    constructor() {
        super();
        //load style sheets to bypass shadow dom
        Promise.all([
            loadStyle(this, stylesheet)
        ]).then(() => {
            console.log("Loaded style sheet");
        }).catch(error => {
            console.error('Error loading stylesheet', error);
        });
    }

    static customTypes = {
        richText: {
            template: richTextTemplate,
            standardCellLayout: true
        }
    }
}