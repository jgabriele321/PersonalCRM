import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  basePath: '/people',
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
};

export default nextConfig;
