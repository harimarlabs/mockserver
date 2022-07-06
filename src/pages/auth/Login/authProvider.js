import { MsalAuthProvider, LoginType } from "react-aad-msal";
import { LogLevel, Logger } from "msal";

const logger = new Logger(
  (logLevel, message, containsPii) => {
    console.log("[MSAL]", message);
  },
  {
    level: LogLevel.Verbose,
    piiLoggingEnabled: false,
  },
);

const tenant = "cc6b2eea-c864-4839-85f5-94736facc3be";
// The auth provider should be a singleton. Best practice is to only have it ever instantiated once.
// Avoid creating an instance inside the component it will be recreated on each render.
// If two providers are created on the same page it will cause authentication errors.
export const authProvider = new MsalAuthProvider(
  {
    auth: {
      // authority: "https://login.microsoftonline.com/common",
      // clientId: "0f2c6253-3928-4fea-b131-bf6ef8f69e9c",
      authority: `https://login.microsoftonline.com/${tenant}`,
      clientId: "f4cef2ff-a4ae-4aa6-8527-c944f9ca295c",
      tenantId: tenant,
      postLogoutRedirectUri: window.location.origin,
      redirectUri: window.location.origin,
      validateAuthority: true,
      IdleSessionTimeoutMins: 5,
      // After being redirected to the "redirectUri" page, should user
      // be redirected back to the Url where their login originated from?
      navigateToLoginRequestUrl: true,
    },
    // Enable logging of MSAL events for easier troubleshooting.
    // This should be disabled in production builds.
    system: {
      logger,
    },
    cache: {
      cacheLocation: "sessionStorage",
      storeAuthStateInCookie: false,
    },
  },
  {
    scopes: ["openid"],
  },
  {
    loginType: LoginType.Redirect,
    // When a token is refreshed it will be done by loading a page in an iframe.
    // Rather than reloading the same page, we can point to an empty html file which will prevent
    // site resources from being loaded twice.
    // tokenRefreshUri: window.location.origin + "/auth.html"
    tokenRefreshUri: `${window.location.origin}/auth.html`,
  },
);
