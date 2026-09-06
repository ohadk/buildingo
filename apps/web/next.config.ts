import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  // App Hosting adapter expects a standalone bundle.
  output: "standalone",
  // Keep standalone rooted here (not a parent monorepo path).
  outputFileTracingRoot: path.join(__dirname),
  serverExternalPackages: ["firebase-admin"],
};

export default nextConfig;
