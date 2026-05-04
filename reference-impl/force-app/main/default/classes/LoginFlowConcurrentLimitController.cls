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
        for (Integer i = 0; i < toRemove; i++) {
            try {
                // The exact signature of Auth.SessionManagement to terminate a session
                // varies by API version. Some versions expose endSession(Id) directly;
                // others require revoking via SOAP API. Adapt to your target API.
                Auth.SessionManagement.endSession(nonCurrent[i].Id);
            } catch (Exception e) {
                // Log and continue; a single revoke failure should not abort the login flow.
                System.debug(LoggingLevel.WARN,
                    'LoginFlowConcurrentLimitController failed to end session: ' + e.getMessage());
            }
        }
    }
}
