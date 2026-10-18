// gotrue 2.27.2 creates an origin-wide auth BroadcastChannel even with custom
// sessionStorage. It exposes no option to disable that channel. Scope ONLY its
// auth channels to this document before Flutter initializes; otherwise signing
// in in another tab silently replaces the current client's authenticated user.
(() => {
  const NativeBroadcastChannel = window.BroadcastChannel;
  if (!NativeBroadcastChannel) return;
  const scope = Array.from(crypto.getRandomValues(new Uint32Array(4)), n => n.toString(16)).join('-');
  window.BroadcastChannel = class TabScopedAuthChannel extends NativeBroadcastChannel {
    constructor(name) {
      super(/^sb-[a-z0-9]+-auth-token$/.test(name) ? `${name}:${scope}` : name);
    }
  };
})();
