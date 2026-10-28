// Scholaris — Multi-Tab Authentication Scoping & Cross-Tab Logout Synchronization
//
// 1. Isolation: gotrue 2.27.2 creates an origin-wide auth BroadcastChannel.
//    Scope ONLY its auth channels to this document via a unique per-tab UUID.
//    This isolates parallel sessions across tabs (e.g. Org Admin vs Org Staff).
//
// 2. Synchronization (IAS Section E2): When a user logs out in one tab,
//    broadcast an account-scoped logout event on 'scholaris_user_sync'.
//    Other tabs verify if their active storage session matches data.userId.
//    If matched, they clear local storage for that user/project and dispatch
//    SIGNED_OUT locally to transition in-memory GoTrue and Riverpod to /login.
//    Tabs with different userIds strictly ignore the event.
//
// Security Invariants:
// - Zero secret / token / session exposure (only { type, userId, authKey, sourceScope, timestamp }).
// - Event loop prevention (sending tab ignores its own sourceScope).
// - Multi-actor isolation strictly preserved across parallel sessions.
// - Multi-project scoping: logout in project A strictly protects project B from cleanup or notification.
// - Replay protection: events older than current session establishment or already processed are ignored.
// - Token refresh resilience: routine token refresh for same user preserves session establishment epoch baseline.
// - State-driven login epoch: transitions (previousUserId !== id) and explicit SIGNED_IN events establish fresh epochs without arbitrary write suppression.
// - Suspended tab / delayed delivery: elapsed delivery delay while suspended does not prevent same-session logout.
// - Page reload resilience: initial hydration snapshot does not treat page reload as a new login timestamp.
(() => {
  const NativeBroadcastChannel = window.BroadcastChannel;
  if (!NativeBroadcastChannel) return;

  const scope = (typeof crypto !== 'undefined' && crypto.getRandomValues)
    ? Array.from(crypto.getRandomValues(new Uint32Array(4)), n => n.toString(16)).join('-')
    : Math.random().toString(16).slice(2) + '-' + Date.now().toString(16);

  const SYNC_CHANNEL_NAME = 'scholaris_user_sync';
  const syncChannel = new NativeBroadcastChannel(SYNC_CHANNEL_NAME);
  const activeScopedChannelNames = new Set();
  const channelUsers = new Map(); // authKey -> userId
  const sessionEstablishedByAuthKey = new Map(); // authKey -> timestamp
  const lastProcessedLogoutByAuthKey = new Map(); // authKey -> timestamp

  let lastKnownUserId = null;

  function getSessionStorage() {
    try {
      if (typeof window !== 'undefined' && window.sessionStorage) return window.sessionStorage;
      if (typeof sessionStorage !== 'undefined') return sessionStorage;
    } catch (_) {}
    return null;
  }

  function interceptStorage(storage) {
    if (!storage || typeof storage.setItem !== 'function' || storage._intercepted) return;
    try {
      const origSetItem = storage.setItem;
      storage.setItem = function (key, value) {
        if (typeof key === 'string' && /^sb-[a-z0-9]+-auth-token$/.test(key)) {
          try {
            const parsed = JSON.parse(value);
            const id = parsed?.user?.id || parsed?.currentSession?.user?.id;
            if (id && typeof id === 'string') {
              const previousUserId = channelUsers.get(key);
              channelUsers.set(key, id);
              lastKnownUserId = id;
              // Reset session epoch ONLY if user changed or was previously signed out (fresh sign-in).
              // Routine token refresh for the same user preserves existing session epoch baseline.
              if (previousUserId !== id) {
                sessionEstablishedByAuthKey.set(key, Date.now());
                lastProcessedLogoutByAuthKey.delete(key);
              }
            }
          } catch (_) {}
        }
        return origSetItem.apply(this, arguments);
      };
      storage._intercepted = true;
    } catch (_) {}
  }

  const initialStorage = getSessionStorage();
  if (initialStorage) {
    interceptStorage(initialStorage);
  }

  function hydrateFromStorage() {
    try {
      const storage = getSessionStorage();
      if (!storage) return;
      interceptStorage(storage);
      for (let i = 0; i < storage.length; i++) {
        const key = storage.key(i);
        if (/^sb-[a-z0-9]+-auth-token$/.test(key)) {
          const raw = storage.getItem(key);
          if (raw) {
            try {
              const parsed = JSON.parse(raw);
              const id = parsed?.user?.id || parsed?.currentSession?.user?.id;
              if (id && typeof id === 'string') {
                channelUsers.set(key, id);
                if (!lastKnownUserId) {
                  lastKnownUserId = id;
                }
                // Establish initial baseline epoch so same-user token refreshes do not advance epoch to Date.now()
                if (!sessionEstablishedByAuthKey.has(key)) {
                  sessionEstablishedByAuthKey.set(key, 0);
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  hydrateFromStorage();

  function getActiveUserId(targetKey) {
    try {
      const storage = getSessionStorage();
      if (storage) {
        interceptStorage(storage);
        // 1. If targetKey is specified, check ONLY targetKey in storage
        if (targetKey) {
          const raw = storage.getItem(targetKey);
          if (raw) {
            try {
              const parsed = JSON.parse(raw);
              const id = parsed?.user?.id || parsed?.currentSession?.user?.id;
              if (id && typeof id === 'string') {
                channelUsers.set(targetKey, id);
                lastKnownUserId = id;
                return id;
              }
            } catch (_) {}
          }
          // If targetKey is specified and not in storage, check channelUsers fallback for targetKey
          if (channelUsers.has(targetKey)) {
            return channelUsers.get(targetKey);
          }
          return null; // Strict isolation: do not fall through to other project channels!
        }

        // 2. If no targetKey specified, check activeScopedChannelNames
        for (const channelName of activeScopedChannelNames) {
          const raw = storage.getItem(channelName);
          if (raw) {
            try {
              const parsed = JSON.parse(raw);
              const id = parsed?.user?.id || parsed?.currentSession?.user?.id;
              if (id && typeof id === 'string') {
                channelUsers.set(channelName, id);
                lastKnownUserId = id;
                return id;
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // Fallback when no targetKey was specified
    for (const channelName of activeScopedChannelNames) {
      if (channelUsers.has(channelName)) {
        return channelUsers.get(channelName);
      }
    }

    return lastKnownUserId;
  }

  // Listen for cross-tab user logout events
  syncChannel.onmessage = (event) => {
    const data = event.data;
    if (!data || typeof data !== 'object') return;
    if (data.type !== 'USER_LOGOUT') return;
    if (typeof data.userId !== 'string' || !data.userId) return;

    // Strict validation of sourceScope
    if (typeof data.sourceScope !== 'string' || !data.sourceScope) return;
    // Prevent event loops: ignore self broadcast
    if (data.sourceScope === scope) return;

    // Strict validation of timestamp and future clock skew (allow up to 30s future skew)
    if (typeof data.timestamp !== 'number' || !Number.isFinite(data.timestamp)) return;
    const now = Date.now();
    if (data.timestamp > now + 30000) return;

    // Replay protection scoped per authKey
    const targetKey = (typeof data.authKey === 'string' && data.authKey) ? data.authKey : null;
    if (targetKey) {
      const establishedAt = sessionEstablishedByAuthKey.get(targetKey) || 0;
      const lastProcessed = lastProcessedLogoutByAuthKey.get(targetKey) || 0;
      if (lastProcessed > 0 && data.timestamp <= lastProcessed) return;
      // Replay protection: if a fresh login established an epoch, reject logouts that occurred before that login.
      // Legitimate logouts queued while a tab is suspended/backgrounded (>30s delivery delay) are accepted
      // so long as they were dispatched during this active login session.
      if (establishedAt > 0 && data.timestamp < establishedAt) return;
    } else {
      // Unscoped envelope fallback (legacy/synthetic test payloads): enforce 30s freshness window
      if (data.timestamp < now - 30000) return;
      for (const [key, establishedAt] of sessionEstablishedByAuthKey.entries()) {
        const lastProcessed = lastProcessedLogoutByAuthKey.get(key) || 0;
        if (lastProcessed > 0 && data.timestamp <= lastProcessed) return;
        if (establishedAt > 0 && data.timestamp < establishedAt) return;
      }
    }

    // Multi-actor & multi-project isolation:
    // Only proceed if THIS tab has an active storage session matching data.userId
    const storage = getSessionStorage();
    if (!storage) return;

    const matchedChannels = new Set();
    const keysToRemove = [];

    if (targetKey) {
      // Scoped to specific auth key / project: only inspect and touch that specific key
      const raw = storage.getItem(targetKey);
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          const id = parsed?.user?.id || parsed?.currentSession?.user?.id;
          if (id === data.userId) {
            matchedChannels.add(targetKey);
            keysToRemove.push(targetKey);
            keysToRemove.push(`${targetKey}-code-verifier`);
          }
        } catch (_) {}
      }
    } else {
      // Unscoped envelope fallback: only match keys where stored session user matches data.userId
      for (let i = 0; i < storage.length; i++) {
        const k = storage.key(i);
        if (/^sb-[a-z0-9]+-auth-token$/.test(k)) {
          const raw = storage.getItem(k);
          if (raw) {
            try {
              const parsed = JSON.parse(raw);
              const id = parsed?.user?.id || parsed?.currentSession?.user?.id;
              if (id === data.userId) {
                matchedChannels.add(k);
                keysToRemove.push(k);
                keysToRemove.push(`${k}-code-verifier`);
              }
            } catch (_) {}
          }
        }
      }
    }

    if (matchedChannels.size === 0) {
      // Non-matching user ID, or tab not logged in as this user for this project: strictly ignore
      return;
    }

    // Same account & project: clear local tab session storage ONLY for the matched project
    keysToRemove.forEach((k) => {
      try {
        storage.removeItem(k);
      } catch (_) {}
    });

    matchedChannels.forEach((k) => {
      channelUsers.delete(k);
      sessionEstablishedByAuthKey.delete(k);
      lastProcessedLogoutByAuthKey.set(k, data.timestamp);
    });

    if (lastKnownUserId === data.userId) {
      lastKnownUserId = null;
    }

    // Notify GoTrue in this tab on all matching auth channel(s) ONLY
    matchedChannels.forEach((channelName) => {
      try {
        const notifyChannel = new NativeBroadcastChannel(`${channelName}:${scope}`);
        notifyChannel.postMessage({ event: 'SIGNED_OUT', session: null });
        notifyChannel.close();
      } catch (_) {}
    });
  };

  window.BroadcastChannel = class TabScopedAuthChannel extends NativeBroadcastChannel {
    constructor(name) {
      const isAuth = /^sb-[a-z0-9]+-auth-token$/.test(name);
      super(isAuth ? `${name}:${scope}` : name);
      this._isAuth = isAuth;
      this._rawName = name;
      if (isAuth) {
        activeScopedChannelNames.add(name);
        hydrateFromStorage();
      }
    }

    postMessage(data) {
      if (this._isAuth && data && typeof data === 'object') {
        if (data.session && data.session.user && typeof data.session.user.id === 'string') {
          const id = data.session.user.id;
          const previousUserId = channelUsers.get(this._rawName);
          channelUsers.set(this._rawName, id);
          lastKnownUserId = id;
          if (data.event === 'SIGNED_IN' || previousUserId !== id) {
            sessionEstablishedByAuthKey.set(this._rawName, Date.now());
            lastProcessedLogoutByAuthKey.delete(this._rawName);
          }
        }

        if (data.event === 'SIGNED_OUT') {
          const userToLogout = getActiveUserId(this._rawName);
          if (userToLogout) {
            try {
              syncChannel.postMessage({
                type: 'USER_LOGOUT',
                userId: userToLogout,
                authKey: this._rawName,
                sourceScope: scope,
                timestamp: Date.now()
              });
            } catch (_) {}
            channelUsers.delete(this._rawName);
            sessionEstablishedByAuthKey.delete(this._rawName);
            if (lastKnownUserId === userToLogout) {
              lastKnownUserId = null;
            }
          }
        }
      }
      super.postMessage(data);
    }
  };
})();
