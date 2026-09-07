/** App Store / Play Store URLs used by /app and /open/* fallbacks. */
export function storeLinks() {
  const appStore =
    process.env.APP_STORE_URL?.trim() ||
    "https://apps.apple.com/search?term=Buildingo&entity=software";
  const playStore =
    process.env.PLAY_STORE_URL?.trim() ||
    "https://play.google.com/store/search?q=Buildingo&c=apps";
  const site =
    process.env.PUBLIC_WEB_URL?.replace(/\/$/, "") ||
    "https://buildingo-api--buildingo-6ff54.us-central1.hosted.app";
  return { appStore, playStore, site };
}
