<aura:application extends="force:slds" controller="DocumentViewerService">
    <aura:attribute name="layoutVersion" type="String" />
    <aura:attribute name="initializeReady" type="Boolean" default="false" />

    <!-- constructor -->
    <aura:handler name="init" value="{!this}" action="{!c.doInit}"/>

    <aura:if isTrue="{!!v.initializeReady}">
        <lightning:spinner alternativeText="Loading" size="medium" variant="brand" />
    </aura:if>
    <aura:if isTrue="{!v.initializeReady}">
        <!-- 19.5.3.2 - 19.6.2.1 -->
        <aura:if isTrue="{!v.layoutVersion == 'Version 1'}">
            <div class="slds-m-around_large">
                <c:contentDocumentViewer />
            </div>
        </aura:if>
        <!-- 19.6.2.2 -->
        <aura:if isTrue="{!v.layoutVersion == 'Version 2'}">
            <c:DocumentViewer />
        </aura:if>
    </aura:if>
</aura:application>