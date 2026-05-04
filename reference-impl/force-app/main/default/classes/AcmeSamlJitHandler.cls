/**
 * AcmeSamlJitHandler
 *
 * Implements Pillar I.6 from the whitepaper (../../../../../index.html#i-custom-auth):
 *   group-driven entitlement -- map IdP groups to Permission Set Groups on every login.
 *
 * Pattern: the IdP returns a `groups` SAML attribute on every assertion. This handler:
 *   1) On createUser: provisions a new User record from the assertion and applies PSGs
 *   2) On updateUser: re-applies the PSG mapping on every login -- revoke + grant as needed
 *
 * Mapping table is custom metadata (IdP_Group_Permission_Mapping__mdt). Updating the mapping
 * is itself a deployment gate (Pillar IX), preventing in-flight privilege escalation.
 *
 * NOT official Salesforce documentation. Verify Auth.SamlJitHandler interface signatures
 * against the current Apex Reference Guide before deploying.
 */
public with sharing class AcmeSamlJitHandler implements Auth.SamlJitHandler {

    public class JitException extends Exception {}

    /**
     * Called when the SAML assertion arrives for an unknown user (federationIdentifier
     * has no matching User record). Provision a new User and apply IdP-group entitlements.
     */
    public User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
                           String federationIdentifier, Map<String, String> attributes,
                           String assertion) {
        validateRequiredAttributes(attributes);

        User u = new User();
        u.FederationIdentifier = federationIdentifier;
        u.Email = attributes.get('email');
        u.FirstName = attributes.get('firstname');
        u.LastName = attributes.get('lastname');
        // Username must be unique org-wide; FederationIdentifier@yourorg.com is a common convention.
        u.Username = federationIdentifier + '@acme.example.com';
        u.Alias = (federationIdentifier != null && federationIdentifier.length() > 0)
                  ? federationIdentifier.left(8) : 'jit_user';
        u.LocaleSidKey = 'en_US';
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.TimeZoneSidKey = 'America/Denver';
        u.ProfileId = getDefaultProfileId();

        insert u;
        applyGroupBasedPSGs(u.Id, attributes.get('groups'));
        return u;
    }

    /**
     * Called when the SAML assertion arrives for an existing User. Re-apply the
     * IdP-group entitlement on every login so that group changes in the IdP propagate
     * automatically. Departures from the IdP group revoke the matching PSG immediately.
     */
    public void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
                           String federationIdentifier, Map<String, String> attributes,
                           String assertion) {
        applyGroupBasedPSGs(userId, attributes.get('groups'));
    }

    // ---------------- Internals ----------------

    private static final Set<String> REQUIRED_ATTRS = new Set<String>{ 'email', 'firstname', 'lastname' };

    @TestVisible
    private void validateRequiredAttributes(Map<String, String> attributes) {
        if (attributes == null) {
            throw new JitException('SAML assertion attributes were null.');
        }
        for (String required : REQUIRED_ATTRS) {
            if (String.isBlank(attributes.get(required))) {
                throw new JitException('Missing required SAML attribute: ' + required);
            }
        }
    }

    @TestVisible
    private Id getDefaultProfileId() {
        // Standard User is a placeholder; in production use a profile that grants no
        // permissions of its own and rely on PSGs for all entitlement.
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        if (profiles.isEmpty()) {
            throw new JitException('Standard User profile not found in this org.');
        }
        return profiles[0].Id;
    }

    /**
     * Resolve the comma-delimited groups claim against the custom-metadata mapping table,
     * compute the target set of PSG developer names, and reconcile assignments.
     */
    @TestVisible
    private void applyGroupBasedPSGs(Id userId, String groupClaim) {
        if (String.isBlank(groupClaim)) {
            return;
        }
        Set<String> idpGroups = new Set<String>();
        for (String g : groupClaim.split(',')) {
            String trimmed = g.trim();
            if (String.isNotBlank(trimmed)) {
                idpGroups.add(trimmed);
            }
        }

        Map<String, String> idpToPSG = loadGroupMapping();

        Set<String> targetPSGNames = new Set<String>();
        for (String g : idpGroups) {
            if (idpToPSG.containsKey(g)) {
                targetPSGNames.add(idpToPSG.get(g));
            }
        }

        // Revoke existing PSG assignments not in the target set
        List<PermissionSetAssignment> existing = [
            SELECT Id, PermissionSetGroupId, PermissionSetGroup.DeveloperName
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId AND PermissionSetGroupId != null
        ];
        List<PermissionSetAssignment> toDelete = new List<PermissionSetAssignment>();
        Set<String> alreadyAssigned = new Set<String>();
        for (PermissionSetAssignment psa : existing) {
            String dev = psa.PermissionSetGroup.DeveloperName;
            if (!targetPSGNames.contains(dev)) {
                toDelete.add(psa);
            } else {
                alreadyAssigned.add(dev);
            }
        }
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }

        // Grant any newly authorized PSGs
        Set<String> toGrant = new Set<String>(targetPSGNames);
        toGrant.removeAll(alreadyAssigned);
        if (toGrant.isEmpty()) {
            return;
        }

        Map<String, Id> psgIds = new Map<String, Id>();
        for (PermissionSetGroup psg : [
            SELECT Id, DeveloperName FROM PermissionSetGroup
            WHERE DeveloperName IN :toGrant
        ]) {
            psgIds.put(psg.DeveloperName, psg.Id);
        }

        List<PermissionSetAssignment> toInsert = new List<PermissionSetAssignment>();
        for (String dev : toGrant) {
            Id psgId = psgIds.get(dev);
            if (psgId != null) {
                toInsert.add(new PermissionSetAssignment(
                    AssigneeId = userId,
                    PermissionSetGroupId = psgId
                ));
            }
        }
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    /**
     * Load the active rows from the custom-metadata mapping table.
     * Cached implicitly by Apex's mdt query optimizer; a static cache could
     * be added for per-transaction efficiency in high-throughput SSO scenarios.
     */
    @TestVisible
    private Map<String, String> loadGroupMapping() {
        Map<String, String> map = new Map<String, String>();
        for (IdP_Group_Permission_Mapping__mdt m : [
            SELECT DeveloperName, PermissionSetGroup__c
            FROM IdP_Group_Permission_Mapping__mdt
            WHERE Active__c = true
        ]) {
            if (String.isNotBlank(m.PermissionSetGroup__c)) {
                map.put(m.DeveloperName, m.PermissionSetGroup__c);
            }
        }
        return map;
    }
}
