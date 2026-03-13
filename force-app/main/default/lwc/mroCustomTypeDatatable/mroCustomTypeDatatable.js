import LightningDatatable from "lightning/datatable";
import customProgressBar from "./customProgressBar.html";

export default class MroCustomTypeDatatable extends LightningDatatable {
  static customTypes = {
    customTypeProgressBar: {
      template: customProgressBar
    }
  };
}