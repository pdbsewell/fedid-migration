<aura:application access="GLOBAL" extends="ltng:outApp" implements="ltng:allowGuestAccess">
    <aura:dependency resource="ui:button"/>

    <div class="slds">
        <div class="slds-page-header">
            <div class="slds-grid">
                <div class="slds-col slds-has-flexi-truncate">
                    <p class="slds-text-heading--label">Course Offerings</p>
                    <div class="slds-grid">
                        <div class="slds-grid slds-type-focus slds-no-space">
                            <h1 class="slds-text-heading--large slds-truncate" title="Course Offerings">Course Offerings</h1>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="slds-col--padded slds-p-top--large">
            <c:EOIRegistration />
        </div>
    </div>
</aura:application>