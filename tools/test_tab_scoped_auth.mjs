// tools/test_tab_scoped_auth.mjs
//
// Independent QA verification harness for actual production JavaScript:
// web/tab_scoped_auth.js (IAS Section E2: Same-Account Cross-Tab Logout & Multi-Actor Isolation)
//
// Evaluators: Mr. Ian Celmar A. Avila, MIT & Mr. Roel Daniot, MSIT
// Student: Gilbert Bulado (#71)
// Contract: SPECIALIST_CONTRACT.md (v2.6)

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PROD_SCRIPT_PATH = path.resolve(__dirname, '../web/tab_scoped_auth.js');

console.log('============================================================');
console.log('=== TEST HARNESS: ACTUAL PRODUCTION web/tab_scoped_auth.js ===');
console.log('============================================================');

if (!fs.existsSync(PROD_SCRIPT_PATH)) {
  console.error(`FATAL: Production script not found at ${PROD_SCRIPT_PATH}`);
  process.exit(1);
}

const prodScriptCode = fs.readFileSync(PROD_SCRIPT_PATH, 'utf8');

// Shared Broadcast Channel Hub simulating true browser inter-tab BroadcastChannel behavior
// Specification: BroadcastChannel.postMessage() dispatches asynchronously via the event loop task queue.
class BroadcastHub {
  constructor() {
    this.channels = new Map(); // channelName -> Set of listener objects
    this.pendingTasks = new Set();
  }

  register(name, listener) {
    if (!this.channels.has(name)) {
      this.channels.set(name, new Set());
    }
    this.channels.get(name).add(listener);
  }

  unregister(name, listener) {
    if (this.channels.has(name)) {
      this.channels.get(name).delete(listener);
      if (this.channels.get(name).size === 0) {
        this.channels.delete(name);
      }
    }
  }

  dispatch(sender, name, data) {
    if (!this.channels.has(name)) return;
    const listeners = Array.from(this.channels.get(name));
    for (const listener of listeners) {
      if (listener.owner !== sender) {
        // Structured clone simulation
        const clonedData = JSON.parse(JSON.stringify(data));
        // True asynchronous dispatch to simulate browser task queue
        const timerId = setTimeout(() => {
          this.pendingTasks.delete(timerId);
          if (!listener.owner.closed) {
            listener.callback({ data: clonedData });
          }
        }, 0);
        this.pendingTasks.add(timerId);
      }
    }
  }

  async flush(delayMs = 40) {
    while (this.pendingTasks.size > 0) {
      await new Promise((resolve) => setTimeout(resolve, 10));
    }
    await new Promise((resolve) => setTimeout(resolve, delayMs));
  }

  clear() {
    for (const timerId of this.pendingTasks) {
      clearTimeout(timerId);
    }
    this.pendingTasks.clear();
    this.channels.clear();
  }
}

const globalHub = new BroadcastHub();

// Native BroadcastChannel implementation connected to globalHub
class MockNativeBroadcastChannel {
  constructor(name) {
    this.name = name;
    this.closed = false;
    this._listenerObj = {
      owner: this,
      callback: (event) => {
        if (!this.closed && typeof this.onmessage === 'function') {
          this.onmessage(event);
        }
      }
    };
    globalHub.register(name, this._listenerObj);
  }

  postMessage(data) {
    if (this.closed) throw new Error('Cannot postMessage on closed channel');
    globalHub.dispatch(this, this.name, data);
  }

  close() {
    this.closed = true;
    globalHub.unregister(this.name, this._listenerObj);
  }
}

// Mock sessionStorage implementation
class MockSessionStorage {
  constructor() {
    this._store = new Map();
  }

  getItem(key) {
    return this._store.has(key) ? this._store.get(key) : null;
  }

  setItem(key, value) {
    this._store.set(String(key), String(value));
  }

  removeItem(key) {
    this._store.delete(String(key));
  }

  clear() {
    this._store.clear();
  }

  key(index) {
    const keys = Array.from(this._store.keys());
    return index >= 0 && index < keys.length ? keys[index] : null;
  }

  get length() {
    return this._store.size;
  }
}

// Creates an isolated simulated browser tab running web/tab_scoped_auth.js
function createSimulatedTab(tabName, initialUserId = null, initialToken = null, extraStorage = {}, customAuthKey = null) {
  const sessionStorage = new MockSessionStorage();
  const authKey = customAuthKey || 'sb-yqwbarzxpduzmtrxnrbm-auth-token';

  // Populate extra storage first if requested (e.g. other project keys)
  for (const [k, v] of Object.entries(extraStorage)) {
    sessionStorage.setItem(k, typeof v === 'string' ? v : JSON.stringify(v));
  }

  if (initialUserId) {
    const sessionObj = {
      user: { id: initialUserId },
      access_token: initialToken || `token-for-${initialUserId}`,
      refresh_token: `refresh-for-${initialUserId}`,
    };
    sessionStorage.setItem(authKey, JSON.stringify(sessionObj));
  }

  const sandbox = {
    console: {
      log: () => {},
      error: console.error,
      warn: console.warn,
    },
    crypto: {
      getRandomValues: (arr) => {
        const bytes = crypto.randomBytes(arr.byteLength);
        const buf = new Uint8Array(arr.buffer, arr.byteOffset, arr.byteLength);
        buf.set(bytes);
        return arr;
      }
    },
    sessionStorage,
    BroadcastChannel: MockNativeBroadcastChannel,
    setTimeout,
    clearTimeout,
    Date,
    Array,
    JSON,
    Set,
    Uint32Array,
    Math,
  };
  sandbox.window = sandbox;

  // Execute actual production script in tab context
  const context = vm.createContext(sandbox);
  vm.runInContext(prodScriptCode, context);

  // TabScoped BroadcastChannel is now installed on sandbox.window.BroadcastChannel
  const TabScopedBroadcastChannel = sandbox.window.BroadcastChannel;

  // Simulate GoTrue client initializing its auth channel
  const gotrueChannel = new TabScopedBroadcastChannel(authKey);
  const receivedGotrueEvents = [];

  gotrueChannel.onmessage = (event) => {
    receivedGotrueEvents.push(event.data);
  };

  return {
    tabName,
    sandbox,
    sessionStorage,
    authKey,
    gotrueChannel,
    receivedGotrueEvents,
    TabScopedBroadcastChannel,
    // Real SDK ordering: signOut removes persisted session storage
    simulateSignOut() {
      sessionStorage.removeItem(authKey);
      gotrueChannel.postMessage({
        event: 'SIGNED_OUT',
        session: null
      });
    },
    // Realistic GoTrue 2.27.2 password change flow:
    // GoTrue updateUser emits USER_UPDATED with updated session; scope:others revokes remotely via API
    // and emits NO local SIGNED_OUT event. Tab stays signed in.
    simulatePasswordUpdate(updatedUserId) {
      const session = {
        user: { id: updatedUserId },
        access_token: `new-access-token-${updatedUserId}`,
        refresh_token: `new-refresh-token-${updatedUserId}`
      };
      sessionStorage.setItem(authKey, JSON.stringify(session));
      gotrueChannel.postMessage({
        event: 'USER_UPDATED',
        session
      });
    },
    // Method to simulate user sign in to this tab
    simulateSignIn(userId) {
      const session = {
        user: { id: userId },
        access_token: `access-token-${userId}`,
        refresh_token: `refresh-token-${userId}`
      };
      sessionStorage.setItem(authKey, JSON.stringify(session));
      gotrueChannel.postMessage({
        event: 'SIGNED_IN',
        session
      });
    },
    close() {
      gotrueChannel.close();
    }
  };
}

let totalTests = 0;
let passedTests = 0;
const failures = [];

function assert(condition, message) {
  totalTests++;
  if (condition) {
    console.log(`  ✓ PASS: ${message}`);
    passedTests++;
  } else {
    console.error(`  ✗ FAIL: ${message}`);
    failures.push(message);
  }
}

async function runAllTests() {
  // ============================================================
  // SCENARIO 1: Same-User Logout Propagation (Async + Storage Removal)
  // ============================================================
  console.log('\n--- SCENARIO 1: Same-User Logout Propagation (Async + Sender Storage Cleared) ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';

    const tab1 = createSimulatedTab('Chrome Tab 1 (User A)', userA);
    const tab2 = createSimulatedTab('Chrome Tab 2 (User A)', userA);

    assert(tab1.sessionStorage.getItem(tab1.authKey) !== null, 'Tab 1 has session in sessionStorage');
    assert(tab2.sessionStorage.getItem(tab2.authKey) !== null, 'Tab 2 has session in sessionStorage');

    // Tab 1 signs out using real SDK ordering (storage removed, SIGNED_OUT posted)
    tab1.simulateSignOut();
    await globalHub.flush();

    // Assert Tab 1 sender storage was removed
    assert(tab1.sessionStorage.getItem(tab1.authKey) === null, 'Tab 1 sender storage is cleared on signOut');

    // Assert Tab 2 received SIGNED_OUT notification on its own scoped auth channel
    assert(tab2.receivedGotrueEvents.length === 1, 'Tab 2 received exactly 1 GoTrue event');
    assert(tab2.receivedGotrueEvents[0]?.event === 'SIGNED_OUT', 'Tab 2 received SIGNED_OUT event');
    assert(tab2.receivedGotrueEvents[0]?.session === null, 'Tab 2 session payload is null');

    // Assert Tab 2 cleared its session storage
    assert(tab2.sessionStorage.getItem(tab2.authKey) === null, 'Tab 2 sessionStorage token was removed');
    assert(tab2.sessionStorage.length === 0, 'Tab 2 sessionStorage is completely cleared of auth keys');

    tab1.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 2: Different-User Multi-Actor Isolation Invariant
  // ============================================================
  console.log('\n--- SCENARIO 2: Different-User Multi-Actor Isolation Invariant ---');
  {
    globalHub.clear();
    const orgAdminId = 'org-admin-uuid-dost-01';
    const orgStaffId = 'org-staff-uuid-dost-02';

    const tab1 = createSimulatedTab('Chrome Tab 1 (Org Admin)', orgAdminId, 'jwt-admin-token');
    const tab3 = createSimulatedTab('Chrome Tab 3 (Org Staff / Reviewer)', orgStaffId, 'jwt-staff-token');

    assert(tab1.sessionStorage.getItem(tab1.authKey).includes('jwt-admin-token'), 'Tab 1 stores Admin token');
    assert(tab3.sessionStorage.getItem(tab3.authKey).includes('jwt-staff-token'), 'Tab 3 stores Staff token');

    // Org Admin signs out in Tab 1
    tab1.simulateSignOut();
    await globalHub.flush();

    // Tab 3 must NOT receive SIGNED_OUT and must NOT have its storage wiped
    assert(tab3.receivedGotrueEvents.length === 0, 'Tab 3 (Org Staff) received 0 logout events');
    assert(tab3.sessionStorage.getItem(tab3.authKey) !== null, 'Tab 3 sessionStorage token is retained');
    assert(tab3.sessionStorage.getItem(tab3.authKey).includes('jwt-staff-token'), 'Tab 3 session token is unharmed and uncorrupted');

    tab1.close();
    tab3.close();
  }

  // ============================================================
  // SCENARIO 3: Event Loop Prevention
  // ============================================================
  console.log('\n--- SCENARIO 3: Event Loop Prevention ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';

    const tab1 = createSimulatedTab('Chrome Tab 1', userA);

    // Tab 1 signs out
    tab1.simulateSignOut();
    await globalHub.flush();

    // Tab 1 must NOT receive a duplicate SIGNED_OUT from the sync channel
    assert(tab1.receivedGotrueEvents.length === 0, 'Tab 1 ignored its own sourceScope broadcast; 0 loopback events');

    tab1.close();
  }

  // ============================================================
  // SCENARIO 4: Robustness to Malformed Wire Payloads & Wire Protocol Validation
  // ============================================================
  console.log('\n--- SCENARIO 4: Robustness to Malformed Wire Payloads & Wire Protocol Validation ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';
    const tab = createSimulatedTab('Chrome Tab Test', userA);

    const directSyncChannel = new MockNativeBroadcastChannel('scholaris_user_sync');

    // 1. Null payload
    directSyncChannel.postMessage(null);
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Null payload handled safely; storage intact');

    // 2. Empty object
    directSyncChannel.postMessage({});
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Empty object handled safely; storage intact');

    // 3. Missing userId
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', sourceScope: 'other', timestamp: Date.now() });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Missing userId handled safely; storage intact');

    // 4. Non-string userId
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: 12345, sourceScope: 'other', timestamp: Date.now() });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Numeric userId handled safely; storage intact');

    // 5. Unknown event type
    directSyncChannel.postMessage({ type: 'UNKNOWN_EVENT', userId: userA, sourceScope: 'other', timestamp: Date.now() });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Unknown event type handled safely; storage intact');

    // 6. Missing sourceScope (MUST reject)
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, timestamp: Date.now() });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Missing sourceScope is rejected; storage intact');

    // 7. Empty or non-string sourceScope (MUST reject)
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: '', timestamp: Date.now() });
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: 12345, timestamp: Date.now() });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Empty/invalid sourceScope is rejected; storage intact');

    // 8. Missing timestamp (MUST reject)
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: 'other' });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Missing timestamp is rejected; storage intact');

    // 9. Non-numeric or NaN timestamp (MUST reject)
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: 'other', timestamp: NaN });
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: 'other', timestamp: 'not-a-number' });
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: 'other', timestamp: null });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Non-numeric timestamp is rejected; storage intact');

    // 10. Stale timestamp (> 30s in past) (MUST reject)
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: 'other', timestamp: Date.now() - 60000 });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Stale timestamp (>30s old) is rejected; storage intact');

    // 11. Future timestamp (> 30s in future) (MUST reject)
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: 'other', timestamp: Date.now() + 60000 });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) !== null, 'Future timestamp (>30s ahead) is rejected; storage intact');

    // 12. Valid logout payload
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: 'other', timestamp: Date.now() });
    await globalHub.flush();
    assert(tab.sessionStorage.getItem(tab.authKey) === null, 'Valid logout successfully cleared storage');
    assert(tab.receivedGotrueEvents.length === 1, 'Valid logout triggered exactly 1 local sign out');

    // 13. Replayed duplicate logout (when already signed out)
    directSyncChannel.postMessage({ type: 'USER_LOGOUT', userId: userA, sourceScope: 'other', timestamp: Date.now() });
    await globalHub.flush();
    assert(tab.receivedGotrueEvents.length === 1, 'Replayed duplicate event is safely no-op; no extra signouts');

    directSyncChannel.close();
    tab.close();
  }

  // ============================================================
  // SCENARIO 5: Actual GoTrue 2.27.2 Password Change Wire Semantics
  // (Evidence Correction: _signOut(scope:others) emits NO local SIGNED_OUT;
  // notifyAllSubscribers envelope has only event/session, NOT scope)
  // ============================================================
  console.log('\n--- SCENARIO 5: Actual GoTrue 2.27.2 Password Change Wire Semantics ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';

    // Tab 1 updates password and invokes updateUser() + signOut(scope: others)
    // GoTrue 2.27.2 emits USER_UPDATED locally; it emits NO local SIGNED_OUT event.
    // The initiating Tab 1 remains signed in.
    const tab1 = createSimulatedTab('Chrome Tab 1 (Password Updater)', userA, 'token-tab1');
    const tab2 = createSimulatedTab('Chrome Tab 2 (Remote Session of User A)', userA, 'token-tab2');

    // An independent local listener in Tab 1 (e.g. Riverpod auth listener)
    const tab1LocalListener = new tab1.sandbox.window.BroadcastChannel(tab1.authKey);
    const tab1LocalEvents = [];
    tab1LocalListener.onmessage = (event) => tab1LocalEvents.push(event.data);

    // Simulate actual SDK password change: updateUser emits USER_UPDATED
    tab1.simulatePasswordUpdate(userA);
    await globalHub.flush();

    // Tab 1 remains active
    assert(tab1.sessionStorage.getItem(tab1.authKey) !== null, 'Tab 1 retains active session in storage after password change');
    assert(tab1LocalEvents.some(e => e.event === 'USER_UPDATED'), 'Tab 1 local listener received USER_UPDATED event');
    assert(tab1LocalEvents.every(e => e.event !== 'SIGNED_OUT'), 'Tab 1 received ZERO SIGNED_OUT events during password change');

    // Tab 1 did NOT emit synthetic cross-tab SIGNED_OUT event on scholaris_user_sync
    // Cross-tab peer notification on scope:others requires explicit future Dart/backend integration.
    assert(tab2.sessionStorage.getItem(tab2.authKey) !== null, 'Remote Tab 2 local session remains until backend revocation / refresh without synthetic wire events');

    tab1LocalListener.close();
    tab1.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 6: Freshly Rehydrated Session with Storage Removed BEFORE SIGNED_OUT
  // ============================================================
  console.log('\n--- SCENARIO 6: Freshly Rehydrated Session + Storage Removal BEFORE SIGNED_OUT ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';

    // Both tabs load existing session from storage (freshly rehydrated; no SIGNED_IN event posted)
    const tab1 = createSimulatedTab('Chrome Tab 1 (Rehydrated)', userA);
    const tab2 = createSimulatedTab('Chrome Tab 2 (Rehydrated)', userA);

    // Adversarial sequence:
    // Tab 1 storage is removed BEFORE the SIGNED_OUT postMessage occurs
    tab1.sessionStorage.removeItem(tab1.authKey);
    assert(tab1.sessionStorage.getItem(tab1.authKey) === null, 'Tab 1 storage removed prior to SIGNED_OUT dispatch');

    // Tab 1 dispatches SIGNED_OUT
    tab1.gotrueChannel.postMessage({
      event: 'SIGNED_OUT',
      session: null
    });
    await globalHub.flush();

    // Tab 2 MUST receive SIGNED_OUT and clear its storage
    assert(tab2.receivedGotrueEvents.length === 1, 'Tab 2 successfully received SIGNED_OUT despite Tab 1 pre-dispatch storage removal');
    assert(tab2.sessionStorage.getItem(tab2.authKey) === null, 'Tab 2 storage cleared despite Tab 1 pre-dispatch storage removal');

    tab1.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 6B: Unauthenticated at Load -> Session Stored Later -> Storage Removed BEFORE SIGNED_OUT
  // ============================================================
  console.log('\n--- SCENARIO 6B: Unauthenticated at Load -> Session Stored Later -> Storage Removed BEFORE SIGNED_OUT ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';

    // Tab 1 loads with NO session (unauthenticated student)
    const tab1 = createSimulatedTab('Chrome Tab 1 (Initially Blank)', null);
    const tab2 = createSimulatedTab('Chrome Tab 2 (Target Session)', userA);

    // Student logs in: Dart writes session to sessionStorage
    const sessionObj = {
      user: { id: userA },
      access_token: `token-${userA}`,
      refresh_token: `refresh-${userA}`,
    };
    tab1.sessionStorage.setItem(tab1.authKey, JSON.stringify(sessionObj));

    // Adversarial: Storage is cleared prior to gotrueChannel.postMessage
    tab1.sessionStorage.removeItem(tab1.authKey);

    tab1.gotrueChannel.postMessage({
      event: 'SIGNED_OUT',
      session: null
    });
    await globalHub.flush();

    assert(tab2.receivedGotrueEvents.length === 1, 'Tab 2 received SIGNED_OUT when Tab 1 session was stored after script load');
    assert(tab2.sessionStorage.getItem(tab2.authKey) === null, 'Tab 2 storage cleared when Tab 1 session was stored after script load');

    tab1.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 6C: Page Reload / Rehydration Does Not Block Queued Valid Logout
  // ============================================================
  console.log('\n--- SCENARIO 6C: Page Reload / Rehydration Does Not Block Queued Valid Logout ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';

    // Tab 2 has rehydrated from storage (e.g. user just refreshed page)
    const tab2 = createSimulatedTab('Chrome Tab 2 (Refreshed Page)', userA);

    const directSyncChannel = new MockNativeBroadcastChannel('scholaris_user_sync');

    // A logout was dispatched 2 seconds ago (within the valid 30s freshness window)
    const queuedLogoutTime = Date.now() - 2000;
    directSyncChannel.postMessage({
      type: 'USER_LOGOUT',
      userId: userA,
      authKey: tab2.authKey,
      sourceScope: 'tab1-scope',
      timestamp: queuedLogoutTime
    });
    await globalHub.flush();

    // Page refresh MUST NOT treat the reload as a brand new session that ignores legitimate queued logouts
    assert(tab2.receivedGotrueEvents.length === 1, 'Refreshed tab accepted queued logout within freshness window');
    assert(tab2.sessionStorage.getItem(tab2.authKey) === null, 'Refreshed tab storage was cleared on queued logout');

    directSyncChannel.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 7: Cached Active User A but Storage Changes to User B
  // ============================================================
  console.log('\n--- SCENARIO 7: Cached Active User A but Storage Changes to User B ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';
    const userB = 'user-b-uuid-2222';

    // Tab 1 signs in as User A (caches activeUserId = userA)
    const tab1 = createSimulatedTab('Chrome Tab 1 (Switch Account)', userA);
    tab1.simulateSignIn(userA);

    // Tab 2 signs in as User B
    const tab2 = createSimulatedTab('Chrome Tab 2 (User B Target)', userB);
    tab2.simulateSignIn(userB);

    // Tab 3 signs in as User A
    const tab3 = createSimulatedTab('Chrome Tab 3 (User A Target)', userA);
    tab3.simulateSignIn(userA);

    // Now Tab 1 storage changes to User B (e.g. account switch in storage)
    const newSessionB = {
      user: { id: userB },
      access_token: 'token-b',
      refresh_token: 'refresh-b'
    };
    tab1.sessionStorage.setItem(tab1.authKey, JSON.stringify(newSessionB));

    // Tab 1 now signs out
    tab1.simulateSignOut();
    await globalHub.flush();

    // Tab 1 must broadcast logout for current storage user (User B), NOT stale cached User A!
    assert(tab2.sessionStorage.getItem(tab2.authKey) === null, 'Tab 2 (User B) was signed out matching Tab 1 current storage');
    assert(tab3.sessionStorage.getItem(tab3.authKey) !== null, 'Tab 3 (User A) remains unaffected; stale User A was NOT broadcast');

    tab1.close();
    tab2.close();
    tab3.close();
  }

  // ============================================================
  // SCENARIO 8: Duplicate / Replayed Event After Relogin
  // ============================================================
  console.log('\n--- SCENARIO 8: Duplicate / Replayed Event After Relogin ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';
    const tab2 = createSimulatedTab('Chrome Tab 2 (Relogin Session)', userA);

    const directSyncChannel = new MockNativeBroadcastChannel('scholaris_user_sync');

    // T0: tab2 initialized and sessionEstablishedAt recorded
    // Wait 50ms so T1 is strictly greater than sessionEstablishedAt
    await new Promise((r) => setTimeout(r, 50));

    // T1: Logout event occurs at T1
    const t1 = Date.now();
    directSyncChannel.postMessage({
      type: 'USER_LOGOUT',
      userId: userA,
      authKey: tab2.authKey,
      sourceScope: 'tab1-scope',
      timestamp: t1
    });
    await globalHub.flush();

    assert(tab2.sessionStorage.getItem(tab2.authKey) === null, 'Tab 2 signed out at T1');
    assert(tab2.receivedGotrueEvents.length === 1, 'Tab 2 received initial logout');

    // T2: User A logs back in to Tab 2 at T2 (T2 > T1)
    await new Promise((r) => setTimeout(r, 50));
    tab2.simulateSignIn(userA);
    assert(tab2.sessionStorage.getItem(tab2.authKey) !== null, 'Tab 2 successfully relogged in at T2');

    // T3: Replayed / duplicate event from T1 (timestamp = t1) arrives at T3
    directSyncChannel.postMessage({
      type: 'USER_LOGOUT',
      userId: userA,
      authKey: tab2.authKey,
      sourceScope: 'tab1-scope',
      timestamp: t1 // stale / older than relogin at T2!
    });
    await globalHub.flush();

    // Tab 2 MUST IGNORE the replayed T1 logout and remain logged in!
    assert(tab2.sessionStorage.getItem(tab2.authKey) !== null, 'Tab 2 ignored replayed pre-login logout event; fresh session preserved');
    assert(tab2.receivedGotrueEvents.length === 1, 'Tab 2 received 0 additional logout events on replayed message');

    directSyncChannel.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 8B: Routine Token Refresh Does NOT Reset Login Epoch or Discard Queued Logout
  // ============================================================
  console.log('\n--- SCENARIO 8B: Routine Token Refresh Does NOT Reset Login Epoch ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';
    const tab2 = createSimulatedTab('Chrome Tab 2 (Refresh Resilience)', userA);

    const directSyncChannel = new MockNativeBroadcastChannel('scholaris_user_sync');

    // T0: tab2 initialized and session epoch recorded
    await new Promise((r) => setTimeout(r, 50));

    // T1: Logout event occurs at T1 (t1 > t0)
    const t1 = Date.now();
    directSyncChannel.postMessage({
      type: 'USER_LOGOUT',
      userId: userA,
      authKey: tab2.authKey,
      sourceScope: 'tab1-scope',
      timestamp: t1
    });

    // T2: Before queued logout is processed, Tab 2 performs a routine token refresh (same user)
    // Supabase writes updated access/refresh token to sessionStorage in same event-loop turn
    const refreshedSession = {
      user: { id: userA },
      access_token: 'new-refreshed-access-token-999',
      refresh_token: 'new-refreshed-refresh-token-999'
    };
    tab2.sessionStorage.setItem(tab2.authKey, JSON.stringify(refreshedSession));

    // T3: Event loop flushes and delivers queued logout from T1
    await globalHub.flush();

    // Routine refresh MUST NOT update sessionEstablishedAt and cause T1 to be discarded!
    assert(tab2.receivedGotrueEvents.length === 1, 'Queued logout accepted despite routine token refresh write');
    assert(tab2.sessionStorage.getItem(tab2.authKey) === null, 'Session storage cleared on queued logout after token refresh');

    directSyncChannel.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 8C: Multi-Client Token Refresh Epoch Scoping
  // ============================================================
  console.log('\n--- SCENARIO 8C: Multi-Client Token Refresh Epoch Scoping ---');
  {
    globalHub.clear();
    const projA = 'sb-projecta-auth-token';
    const projB = 'sb-projectb-auth-token';
    const userA = 'user-a-1111';
    const userB = 'user-b-2222';

    // Tab 2 has Project A and Project B
    const tab2 = createSimulatedTab('Chrome Tab 2', userA, 'token-a', {
      [projB]: { user: { id: userB }, access_token: 'token-b' }
    }, projA);
    const tab2ClientB = new tab2.TabScopedBroadcastChannel(projB);

    await new Promise((r) => setTimeout(r, 50));

    // Logout occurs for Project A at T1
    const t1 = Date.now();
    const directSyncChannel = new MockNativeBroadcastChannel('scholaris_user_sync');
    directSyncChannel.postMessage({
      type: 'USER_LOGOUT',
      userId: userA,
      authKey: projA,
      sourceScope: 'tab1-scope',
      timestamp: t1
    });

    // Project B undergoes token refresh
    await new Promise((r) => setTimeout(r, 10));
    tab2.sessionStorage.setItem(projB, JSON.stringify({ user: { id: userB }, access_token: 'refreshed-token-b' }));

    await globalHub.flush();

    // Project A must still be logged out; Project B must remain active
    assert(tab2.sessionStorage.getItem(projA) === null, 'Project A logged out regardless of Project B token refresh');
    assert(tab2.sessionStorage.getItem(projB) !== null, 'Project B remained active and uncorrupted');

    directSyncChannel.close();
    tab2ClientB.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 8D: Suspended / Backgrounded Tab Delayed Delivery (>30s Old)
  // ============================================================
  console.log('\n--- SCENARIO 8D: Suspended / Backgrounded Tab Delayed Delivery (>30s Old) ---');
  {
    globalHub.clear();
    const userA = 'user-a-uuid-1111';

    // Tab 2 has an active session established in memory/storage
    const tab2 = createSimulatedTab('Chrome Tab 2 (Suspended Tab)', userA);

    const directSyncChannel = new MockNativeBroadcastChannel('scholaris_user_sync');

    // Simulate tab backgrounding: logout event was queued while tab was active,
    // but delivery is delayed by >30 seconds (e.g. 45s ago, well outside naive 30s freshness cutoff).
    // Because logout occurred during the same active session (timestamp >= establishedAt),
    // it MUST NOT be discarded merely due to elapsed delivery delay.
    const delayedLogoutTimestamp = Date.now() - 45000;

    directSyncChannel.postMessage({
      type: 'USER_LOGOUT',
      userId: userA,
      authKey: tab2.authKey,
      sourceScope: 'tab1-scope',
      timestamp: delayedLogoutTimestamp
    });
    await globalHub.flush();

    // Tab 2 accepts delayed logout on wake; session storage is cleared
    assert(tab2.receivedGotrueEvents.length === 1, 'Suspended tab accepted delayed valid same-session logout (>30s old)');
    assert(tab2.sessionStorage.getItem(tab2.authKey) === null, 'Suspended tab storage cleared on delayed logout wake');

    // Replay protection invariant check:
    // User logs in fresh to a new session at T_fresh
    tab2.simulateSignIn(userA);
    assert(tab2.sessionStorage.getItem(tab2.authKey) !== null, 'Tab 2 fresh login established at T_fresh');

    // Stale delayed logout from before this new login (timestamp = delayedLogoutTimestamp) arrives
    directSyncChannel.postMessage({
      type: 'USER_LOGOUT',
      userId: userA,
      authKey: tab2.authKey,
      sourceScope: 'tab1-scope',
      timestamp: delayedLogoutTimestamp
    });
    await globalHub.flush();

    // Replayed old logout from prior session must NOT kill the fresh session
    assert(tab2.sessionStorage.getItem(tab2.authKey) !== null, 'Replayed old logout from prior session rejected; fresh session preserved');
    assert(tab2.receivedGotrueEvents.length === 1, 'No extra logout events dispatched for stale pre-login replay');

    directSyncChannel.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 9: Another Project Auth Key in Same Storage (Cross-Project Key Isolation)
  // ============================================================
  console.log('\n--- SCENARIO 9: Another Project Auth Key in Same Storage ---');
  {
    globalHub.clear();
    const scholarisUser = 'scholaris-user-uuid-8888';
    const otherProjectUser = 'other-app-user-uuid-9999';
    const otherProjectKey = 'sb-anotherproject-auth-token';

    const extra = {};
    // Put other project key FIRST so it is index 0 in storage
    extra[otherProjectKey] = {
      user: { id: otherProjectUser },
      access_token: 'other-token'
    };

    const tab1 = createSimulatedTab('Chrome Tab 1 (Multi-Project)', scholarisUser, 'scholaris-token', extra);
    const tab2 = createSimulatedTab('Chrome Tab 2 (Multi-Project)', scholarisUser, 'scholaris-token', extra);

    // Tab 1 signs out of Scholaris
    tab1.simulateSignOut();
    await globalHub.flush();

    // Tab 2 must clear Scholaris token
    assert(tab2.sessionStorage.getItem(tab2.authKey) === null, 'Tab 2 cleared Scholaris auth token');

    // Tab 2 must NOT delete the other project's auth key!
    assert(tab2.sessionStorage.getItem(otherProjectKey) !== null, 'Tab 2 preserved other project auth key in sessionStorage');
    assert(JSON.parse(tab2.sessionStorage.getItem(otherProjectKey))?.user?.id === otherProjectUser, 'Other project token intact and uncorrupted');

    tab1.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 9B: Two Active Clients for Different Projects in Same Tab
  // (Multi-Client / Multi-Project Scoping & Non-Interference)
  // ============================================================
  console.log('\n--- SCENARIO 9B: Two Active Clients for Different Projects in Same Tab ---');
  {
    globalHub.clear();
    const projA_Key = 'sb-projecta-auth-token';
    const projB_Key = 'sb-projectb-auth-token';
    const userA = 'user-proj-a-1111';
    const userB = 'user-proj-b-2222';

    // Tab 1 has sessions for BOTH Project A and Project B
    const tab1 = createSimulatedTab('Chrome Tab 1', userA, 'token-a', {
      [projB_Key]: { user: { id: userB }, access_token: 'token-b' }
    }, projA_Key);
    // Tab 1 opens client for Project B as well
    const tab1ClientB = new tab1.TabScopedBroadcastChannel(projB_Key);
    const tab1ClientBEvents = [];
    tab1ClientB.onmessage = (e) => tab1ClientBEvents.push(e.data);

    // Tab 2 also runs both projects
    const tab2 = createSimulatedTab('Chrome Tab 2', userA, 'token-a', {
      [projB_Key]: { user: { id: userB }, access_token: 'token-b' }
    }, projA_Key);
    const tab2ClientB = new tab2.TabScopedBroadcastChannel(projB_Key);
    const tab2ClientBEvents = [];
    tab2ClientB.onmessage = (e) => tab2ClientBEvents.push(e.data);

    // Tab 1 signs out of Project A ONLY
    tab1.simulateSignOut();
    await globalHub.flush();

    // In Tab 1: Project B session must remain intact and client B received 0 signouts
    assert(tab1.sessionStorage.getItem(projB_Key) !== null, 'Tab 1 Project B session preserved in storage');
    assert(tab1ClientBEvents.length === 0, 'Tab 1 Project B client received 0 SIGNED_OUT events');

    // In Tab 2: Project A received SIGNED_OUT and its storage cleared
    assert(tab2.receivedGotrueEvents.length === 1, 'Tab 2 Project A received SIGNED_OUT');
    assert(tab2.sessionStorage.getItem(projA_Key) === null, 'Tab 2 Project A storage cleared');

    // In Tab 2: Project B MUST NOT be cleared or notified
    assert(tab2.sessionStorage.getItem(projB_Key) !== null, 'Tab 2 Project B session preserved in storage');
    assert(tab2ClientBEvents.length === 0, 'Tab 2 Project B client received 0 SIGNED_OUT events');

    tab1ClientB.close();
    tab2ClientB.close();
    tab1.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 9C: Shared User ID across Different Projects (Exact Project Key Scoping)
  // ============================================================
  console.log('\n--- SCENARIO 9C: Shared User ID across Different Projects ---');
  {
    globalHub.clear();
    const projA_Key = 'sb-projecta-auth-token';
    const projB_Key = 'sb-projectb-auth-token';
    const sharedUserId = 'common-user-uuid-9999';

    // Both projects happen to share the same user UUID (e.g. common SSO ID)
    const tab1 = createSimulatedTab('Chrome Tab 1', sharedUserId, 'token-a', {
      [projB_Key]: { user: { id: sharedUserId }, access_token: 'token-b' }
    }, projA_Key);
    const tab1ClientB = new tab1.TabScopedBroadcastChannel(projB_Key);

    const tab2 = createSimulatedTab('Chrome Tab 2', sharedUserId, 'token-a', {
      [projB_Key]: { user: { id: sharedUserId }, access_token: 'token-b' }
    }, projA_Key);
    const tab2ClientB = new tab2.TabScopedBroadcastChannel(projB_Key);
    const tab2ClientBEvents = [];
    tab2ClientB.onmessage = (e) => tab2ClientBEvents.push(e.data);

    // Tab 1 signs out of Project A ONLY
    tab1.simulateSignOut();
    await globalHub.flush();

    // Tab 2: Project A storage cleared
    assert(tab2.sessionStorage.getItem(projA_Key) === null, 'Tab 2 Project A storage cleared');

    // Tab 2: Project B storage MUST NOT be cleared despite identical user ID!
    assert(tab2.sessionStorage.getItem(projB_Key) !== null, 'Tab 2 Project B storage preserved despite matching user ID');
    assert(tab2ClientBEvents.length === 0, 'Tab 2 Project B client received 0 SIGNED_OUT events');

    tab1ClientB.close();
    tab2ClientB.close();
    tab1.close();
    tab2.close();
  }

  // ============================================================
  // SCENARIO 10: Asynchronous BroadcastChannel Delivery Verification
  // ============================================================
  console.log('\n--- SCENARIO 10: Asynchronous BroadcastChannel Delivery Verification ---');
  {
    globalHub.clear();
    const chA = new MockNativeBroadcastChannel('async_test_channel');
    const chB = new MockNativeBroadcastChannel('async_test_channel');
    let delivered = false;

    chB.onmessage = () => {
      delivered = true;
    };

    chA.postMessage({ ping: true });

    // In true browser async BroadcastChannel, delivery has NOT occurred synchronously in the same call frame
    assert(delivered === false, 'BroadcastChannel delivery is truly asynchronous (not executed synchronously)');

    await globalHub.flush();
    assert(delivered === true, 'BroadcastChannel delivered message asynchronously after event loop turn');

    chA.close();
    chB.close();
  }

  console.log('\n============================================================');
  console.log(`TEST SUMMARY: ${passedTests}/${totalTests} PASSED`);
  if (failures.length > 0) {
    console.log(`❌ ${failures.length} REGRESSION FAILURES DETECTED IN PRODUCTION JS:`);
    failures.forEach((f, idx) => console.log(`   ${idx + 1}. ${f}`));
  } else {
    console.log('🎉 ALL CROSS-TAB TESTS PASSED!');
  }
  console.log('============================================================\n');

  if (failures.length > 0) {
    process.exit(1);
  }
}

runAllTests().catch((err) => {
  console.error('FATAL TEST ERROR:', err);
  process.exit(1);
});
