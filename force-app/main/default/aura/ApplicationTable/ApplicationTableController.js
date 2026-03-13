/**
 * Created by trentdelaney on 14/8/18.
 */
({
    doInit : function(component, event, helper) {
        helper.getDataHelper(component, event);
    },

    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {
            case 'view_application':
                helper.viewEditApplication(component, row, '/applicationreview');
                break;
            case 'edit_application':
                helper.viewEditApplication(component, row, '');
                break;
            case 'delete':
                helper.removeApplication(component, row);
                break;
        }
    }

})