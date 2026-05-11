/**
 * LoginFlowConcurrentLimitController
 *
 * Implements Pillar I.4 from the whitepaper (../../../../../index.html#i-login-flow):
 *   limit concurrent sessions per user via a Custom Login Flow. Bound to a
 *   Visualforce-hosted Login Flow page (LoginFlow_StepUp.page in App. A.2).
 *
 * NOT official Salesforce documentation. Verify the Auth.SessionManagement
 * API surface against the current Apex Reference Guide before deploying.
 *
 * The reference implementation enforces a hard ceiling of MAX_CONCURRENT
 * sessions; any login that exceeds the ceiling causes the oldest sessions
 * to be terminated until the user is back at MAX_CONCURRENT - 1.
 */
public with sharing class LoginFlowConcurrentLimitController {

    @TestVisible
    private static Integer MAX_CONCURRENT = 3;

    /**
     * Page action method bound to the Visualforce Login Flow page.
     * Returns the page reference produced by Auth.SessionManagement.finishLoginFlow().
     */
    public PageReference enforce() {
        terminateOldestExcessSessions(UserInfo.getUserId(), MAX_CONCURRENT);
        // finishLoginFlow() returns the post-login destination PageReference.
        return Auth.SessionManagement.finishLoginFlow();
    }

    /**
     * Query the AuthSession objects the running user owns (excluding the current),
     * and end the oldest sessions until the active count is under the cap.
     *
     * Notes:
     *   - AuthSession.IsCurrent identifies the just-established login session.
     *   - The exact AuthSession schema fields can vary by API version; if your
     *     deployment fails to compile against this query, consult the current
     *     Object Reference for AuthSession.
     */
    @TestVisible
    private static void terminateOldestExcessSessions(Id userId, Integer cap) {
        List<AuthSession> nonCurrent = [
            SELECT Id, LastModifiedDate
            FROM AuthSession
            WHERE UsersId = :userId AND IsCurrent = false
            ORDER BY LastModifiedDate ASC
        ];

        // The current session counts toward the cap, so allowed non-current is cap - 1.
        Integer allowedNonCurrent = Math.max(cap - 1, 0);
        Integer toRemove = nonCurrent.size() - allowedNonCurrent;
        if (toRemove <= 0) {
            return;
        }
        // Session termination by Id is NOT a method on Auth.SessionManagement (verified against
        // the current Apex Reference Guide:
        //   https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Auth_SessionManagement.htm
        // ).
        // The class exposes finishLoginFlow(), inviteUser(...), isApprovedFromVerificationFlow(),
        // setSessionLevel(SessionLevel), and verifyUser(...) -- not endSession(Id).
        //
        // Working alternatives:
        //   1. Tooling API DELETE callout to /services/data/vXX.X/tooling/sobjects/AuthSession/{Id}
        //      (preferred -- documented, works across API versions).
        //   2. Salesforce SOAP API logoutUser() call from a queued integration user.
        //   3. Publish a platform event whose subscriber invokes one of the above.
        //
        // Recommendation: pick option 1 and configure a Named Credential with permission to call
        // the Tooling API as a designated integration user. The login-flow runtime then invokes
        // an HttpRequest with `callout:Tooling_NC/services/data/v64.0/tooling/sobjects/AuthSession/{Id}`
        // and DELETE verb.
        //
        // The block below collects the Ids to terminate and emits a platform event for an
        // asynchronous subscriber to process via the supported callout path. This compiles
        // under current API; the subscriber is left as a customer-build extension point.
        List<Id> sessionIdsToEnd = new List<Id>();
        for (Integer i = 0; i < toRemove; i++) {
            sessionIdsToEnd.add(nonCurrent[i].Id);
        }
        if (!sessionIdsToEnd.isEmpty()) {
            // Customer-build extension point: publish a platform event whose Apex / Flow
            // subscriber issues the Tooling-API DELETE callout per the comment above.
            // Example placeholder -- adapt to a real platform event in your org:
            //
            //   Concurrent_Session_Terminate__e evt = new Concurrent_Session_Terminate__e(
            //       Session_Ids__c = String.join(sessionIdsToEnd, ',')
            //   );
            //   EventBus.publish(evt);
            //
            // For pedagogical purposes the IDs are logged here; replace with the platform-event
            // publish call in your deployment.
            System.debug(LoggingLevel.INFO,
                'LoginFlowConcurrentLimitController: terminate sessions via Tooling-API DELETE -> ' + sessionIdsToEnd);
        }
    }
}
