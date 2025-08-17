import { defineConfig } from '@playwright/test';
import { getServiceConfig, ServiceOS } from '@azure/playwright';
import { DefaultAzureCredential } from '@azure/identity';
import config from './playwright.config';

// Load environment variables from .env file
require('dotenv').config();

// Override the base config for Azure Playwright Workspaces
const azureConfig = {
  ...config,
  use: {
    ...config.use,
    // Remove localhost baseURL for Azure execution
    baseURL: undefined,
    // Configure for cloud testing
    headless: true,
    video: 'retain-on-failure' as const,
    screenshot: 'only-on-failure' as const,
  },
};

/* Learn more about service configuration at https://aka.ms/pww/docs/config */
export default defineConfig(
  azureConfig,
  getServiceConfig(azureConfig, {
    // Configure for browser testing in Azure
    exposeNetwork: undefined, // Remove loopback restriction for browser tests
    timeout: 5 * 60 * 1000, // 5 minutes for browser tests
    os: ServiceOS.LINUX,
    credential: new DefaultAzureCredential(),
  })
);
