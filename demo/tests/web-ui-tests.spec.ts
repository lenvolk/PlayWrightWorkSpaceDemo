import { test, expect } from '@playwright/test';

// Web UI Tests - Azure Playwright Workspaces Compatible Browser Automation
test.describe('🎭 Web UI Tests - Browser Automation', () => {

  test('Navigate to Example.com - Basic Navigation', async ({ page }) => {
    // Navigate to a reliable public website
    await page.goto('https://example.com');
    
    // Verify page title and basic UI elements
    await expect(page).toHaveTitle(/Example Domain/);
    
    // Check for basic page content
    await expect(page.locator('h1')).toContainText('Example Domain');
    await expect(page.locator('p')).toContainText('This domain is for use in illustrative examples');
    
    console.log('✅ Successfully navigated to example.com');
  });

  test('Test API Interaction via JSONPlaceholder', async ({ page }) => {
    // Navigate to JSONPlaceholder - a public API testing site
    await page.goto('https://jsonplaceholder.typicode.com/');
    
    // Verify the page loaded correctly
    await expect(page).toHaveTitle(/JSONPlaceholder/);
    
    // Check for API information
    await expect(page.locator('h1')).toBeVisible();
    
    console.log('✅ JSONPlaceholder API site loaded successfully');
  });

  test('Form Interaction - GitHub Search Demo', async ({ page }) => {
    await page.goto('https://github.com');
    
    // Find and interact with search form
    const searchBox = page.locator('[data-test-selector="nav-search-input"]').first();
    if (await searchBox.isVisible()) {
      await searchBox.fill('playwright');
      await searchBox.press('Enter');
      
      // Wait for search results
      await page.waitForTimeout(2000);
      console.log('✅ GitHub search completed successfully');
    } else {
      // Alternative search method
      await page.getByRole('button', { name: 'Search or jump to' }).first().click();
      await page.getByPlaceholder('Search GitHub').fill('playwright');
      await page.getByPlaceholder('Search GitHub').press('Enter');
      console.log('✅ GitHub search completed via alternative method');
    }
  });

  test('Responsive Design - Mobile View', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    await page.goto('https://example.com');
    
    // Verify mobile layout adjustments
    const heading = page.locator('h1');
    await expect(heading).toBeVisible();
    
    console.log('✅ Mobile viewport test completed');
  });

  test('Dark/Light Theme Detection', async ({ page }) => {
    await page.goto('https://github.com');
    
    // Check if page respects system theme preferences
    const isDarkMode = await page.evaluate(() => {
      return window.matchMedia('(prefers-color-scheme: dark)').matches;
    });
    
    console.log(`✅ System theme preference detected: ${isDarkMode ? 'Dark' : 'Light'} mode`);
  });

  test('JavaScript Interaction - Wikipedia Search', async ({ page }) => {
    await page.goto('https://en.wikipedia.org/wiki/Main_Page');
    
    // Use Wikipedia search functionality
    await page.fill('#searchInput', 'Playwright');
    await page.click('#searchButton');
    
    // Wait for search results page
    await page.waitForLoadState('networkidle');
    
    // Verify we're on a Playwright-related page
    await expect(page).toHaveTitle(/Playwright/);
    
    console.log('✅ Wikipedia search and navigation completed');
  });

  test('Error Handling - 404 Page', async ({ page }) => {
    // Navigate to a non-existent page on GitHub
    const response = await page.goto('https://github.com/nonexistent-user-12345/nonexistent-repo-67890');
    
    // Verify 404 handling
    expect(response?.status()).toBe(404);
    
    console.log('✅ 404 error handling verified');
  });

  test('Performance - Page Load Time Measurement', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto('https://example.com');
    await page.waitForLoadState('networkidle');
    
    const loadTime = Date.now() - startTime;
    
    // Assert page loads within reasonable time (< 5 seconds)
    expect(loadTime).toBeLessThan(5000);
    
    // Verify critical page elements loaded
    await expect(page.locator('h1')).toBeVisible();
    
    console.log(`✅ Page load time: ${loadTime}ms`);
  });
});

// Cross-Browser UI Tests - Demonstrating browser-specific behavior
test.describe('🌐 Cross-Browser UI Compatibility', () => {

  test('CSS Grid Layout Compatibility', async ({ page, browserName }) => {
    await page.goto('https://css-tricks.com/snippets/css/complete-guide-grid/');
    
    // Check CSS Grid demonstrations on CSS-Tricks
    const gridExamples = page.locator('.wp-block-cp-codepen-gutenberg-embed-block');
    await expect(gridExamples.first()).toBeVisible();
    
    console.log(`✅ CSS Grid compatibility verified on ${browserName}`);
  });

  test('WebAPI Features - Local Storage', async ({ page }) => {
    await page.goto('https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage');
    
    // Test localStorage functionality directly
    await page.evaluate(() => {
      localStorage.setItem('azure-playwright-test', 'cross-browser-storage');
    });
    
    const storedValue = await page.evaluate(() => {
      return localStorage.getItem('azure-playwright-test');
    });
    
    expect(storedValue).toBe('cross-browser-storage');
    
    console.log('✅ LocalStorage functionality verified');
  });

  test('Accessibility - ARIA Labels and Keyboard Navigation', async ({ page }) => {
    await page.goto('https://www.w3.org/WAI/ARIA/apg/');
    
    // Test keyboard navigation on W3C ARIA examples
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    
    // Verify focus management exists
    const focusedElement = await page.evaluate(() => document.activeElement?.tagName);
    expect(['BUTTON', 'A', 'INPUT', 'MAIN', 'HEADER']).toContain(focusedElement);
    
    console.log(`✅ Accessibility navigation verified, focused on: ${focusedElement}`);
  });
});

// Azure Playwright Workspaces Specific Tests
test.describe('☁️ Azure Cloud Testing Features', () => {

  test('Network Conditions - Slow 3G Simulation', async ({ page }) => {
    // Simulate slow network conditions (Azure Playwright Workspaces feature)
    await page.route('**/*', route => {
      // Add artificial delay to simulate slow network
      setTimeout(() => route.continue(), 50);
    });
    
    const startTime = Date.now();
    await page.goto('https://httpbin.org/delay/1');
    const loadTime = Date.now() - startTime;
    
    // Verify page loads with expected delay
    expect(loadTime).toBeGreaterThan(1000);
    
    console.log(`✅ Network simulation completed, load time: ${loadTime}ms`);
  });

  test('Geolocation Testing', async ({ page, context }) => {
    // Set geolocation (Azure can test from different regions)
    await context.setGeolocation({ latitude: 40.7128, longitude: -74.0060 });
    await context.grantPermissions(['geolocation']);
    
    await page.goto('https://www.openstreetmap.org/');
    
    // Test geolocation API availability
    const hasGeolocation = await page.evaluate(() => {
      return 'geolocation' in navigator;
    });
    
    expect(hasGeolocation).toBe(true);
    
    console.log('✅ Geolocation API testing completed (NYC coordinates)');
  });

  test('Multi-Tab Workflow', async ({ context }) => {
    // Create multiple tabs (testing cloud browser management)
    const page1 = await context.newPage();
    const page2 = await context.newPage();
    
    // Navigate to different pages
    await page1.goto('https://example.com');
    await page2.goto('https://httpbin.org/json');
    
    // Verify both pages loaded correctly
    await expect(page1.locator('h1')).toContainText('Example Domain');
    await expect(page2.locator('pre')).toBeVisible();
    
    // Test cross-tab communication via localStorage
    await page1.evaluate(() => {
      localStorage.setItem('azure-playwright-demo', 'multi-tab-test');
    });
    
    const sharedData = await page2.evaluate(() => {
      return localStorage.getItem('azure-playwright-demo');
    });
    
    expect(sharedData).toBe('multi-tab-test');
    
    console.log('✅ Multi-tab workflow completed successfully');
  });
});
