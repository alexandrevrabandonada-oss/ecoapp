/** @type {import('next').NextConfig} */
const nextConfig = {
  allowedDevOrigins: ["localhost","127.0.0.1","192.168.29.50"],
  serverExternalPackages: ["@prisma/client", "prisma"],
};
module.exports = nextConfig;

