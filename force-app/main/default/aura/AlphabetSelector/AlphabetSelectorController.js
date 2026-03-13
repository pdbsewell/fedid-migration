({
	handleClick : function(component, event, helper) {
        
        console.log("inside AlphabetSelectorController.js");

        var selectedAlphabet = event.getSource().get("v.label");
        var appEvent = $A.get("e.c:filterAgencyBy1stAlphabet");
        appEvent.setParams({"alphabetChosen" : selectedAlphabet});
        appEvent.fire();

    }
})