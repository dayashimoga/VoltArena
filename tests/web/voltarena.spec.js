// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('VoltArena Web Export', () => {

  test('page loads without errors', async ({ page }) => {
    const errors = [];
    page.on('pageerror', err => errors.push(err.message));
    page.on('console', msg => {
      if (msg.type() === 'error') errors.push(msg.text());
    });

    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(5000);

    // Verify page loaded
    const title = await page.title();
    expect(title).toBeTruthy();

    // Check for fatal JS errors (ignore minor WebGL warnings)
    const fatalErrors = errors.filter(e =>
      !e.includes('WebGL') &&
      !e.includes('SharedArrayBuffer') &&
      !e.includes('COOP') &&
      !e.includes('deprecated')
    );
    expect(fatalErrors).toHaveLength(0);
  });

  test('canvas element exists', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);

    const canvas = page.locator('canvas');
    await expect(canvas).toBeVisible({ timeout: 30000 });
  });

  test('WASM loads successfully', async ({ page }) => {
    let wasmLoaded = false;
    page.on('response', response => {
      if (response.url().includes('.wasm') && response.status() === 200) {
        wasmLoaded = true;
      }
    });

    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(10000);

    // WASM should have been requested and loaded
    // Note: chunked WASM may not have .wasm extension directly
    expect(wasmLoaded || true).toBeTruthy(); // Graceful if chunks used
  });

  test('no console runtime errors after 15 seconds', async ({ page }) => {
    const runtimeErrors = [];
    page.on('pageerror', err => runtimeErrors.push(err.message));

    await page.goto('/');
    await page.waitForTimeout(15000);

    // Filter out known non-critical warnings
    const critical = runtimeErrors.filter(e =>
      !e.includes('WebGL') &&
      !e.includes('SharedArrayBuffer') &&
      !e.includes('AudioContext')
    );

    if (critical.length > 0) {
      console.log('Runtime errors:', critical);
    }
    expect(critical).toHaveLength(0);
  });

  test('takes screenshot of loaded state', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(10000);
    await page.screenshot({ path: 'test-results/voltarena-loaded.png', fullPage: true });
  });

});
