const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: false });
    const context = await browser.newContext();
    const page = await context.newPage();
    
    // Enable console logging
    page.on('console', msg => console.log('Browser console:', msg.text()));
    page.on('pageerror', error => console.log('Page error:', error.message));
    
    // Intercept network requests
    page.on('request', request => {
        if (request.url().includes('messages')) {
            console.log('\n=== REQUEST ===');
            console.log('URL:', request.url());
            console.log('Method:', request.method());
            console.log('Headers:', request.headers());
            console.log('Post Data:', request.postData());
        }
    });
    
    page.on('response', response => {
        if (response.url().includes('messages')) {
            console.log('\n=== RESPONSE ===');
            console.log('URL:', response.url());
            console.log('Status:', response.status());
            console.log('Headers:', response.headers());
        }
    });
    
    try {
        console.log('Navigating to simple test page...');
        await page.goto('http://localhost:8500/mcpcfc/simple-test.cfm');
        
        // Take initial screenshot
        await page.screenshot({ path: 'test-initial.png' });
        
        // Click debug endpoint button
        console.log('\nClicking Test Debug Endpoint button...');
        await page.click('button:has-text("Test Debug Endpoint")');
        
        // Wait for response
        await page.waitForTimeout(2000);
        
        // Get the result
        const result = await page.locator('#result').textContent();
        console.log('\n=== RESULT ===');
        console.log(result);
        
        // Take final screenshot
        await page.screenshot({ path: 'test-result.png' });
        
        // Now test the original endpoint
        console.log('\n\nClicking Test Original Endpoint button...');
        await page.click('button:has-text("Test Original Endpoint")');
        
        await page.waitForTimeout(2000);
        
        const result2 = await page.locator('#result').textContent();
        console.log('\n=== ORIGINAL ENDPOINT RESULT ===');
        console.log(result2);
        
        await page.screenshot({ path: 'test-original.png' });
        
    } catch (error) {
        console.error('Error:', error);
        await page.screenshot({ path: 'test-error.png' });
    }
    
    await browser.close();
})();