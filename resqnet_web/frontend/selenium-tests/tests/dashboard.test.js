const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const assert = require('assert');

describe('ResQNet Web - Tactical Dashboard E2E Tests', function () {
  this.timeout(30000); // 30s timeout

  let driver;
  const baseUrl = 'http://localhost:5173/ReqNet_Web/';

  before(async function () {
    const options = new chrome.Options();
    // Use headless mode in CI/Actions, but non-headless locally by default
    if (process.env.HEADLESS === 'true') {
      options.addArguments('--headless=new');
    }
    options.addArguments('--start-maximized');
    options.addArguments('--disable-gpu');
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');

    driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(options)
      .build();
  });

  after(async function () {
    if (driver) {
      await driver.quit();
    }
  });

  it('UI-01: Should load correct browser tab title', async function () {
    await driver.get(baseUrl);
    // Wait for the app-container to render
    await driver.wait(until.elementLocated(By.className('app-container')), 10000);
    const title = await driver.getTitle();
    assert.ok(title.includes('ResQNet - Tactical Mesh Dashboard'), `Title was: ${title}`);
  });

  it('UI-04: Should display the ResQNet Web logo text in header', async function () {
    const logoElement = await driver.wait(until.elementLocated(By.id('logo-text')), 5000);
    const logoText = await logoElement.getText();
    assert.strictEqual(logoText.toUpperCase(), 'RESQNET WEB');
  });

  it('UI-05: Should verify presence of network logo icon in header', async function () {
    const iconElement = await driver.findElement(By.id('logo-icon'));
    assert.ok(iconElement, 'Logo icon element was not found in the header');
  });

  it('FN-01 & FN-14: Should support sending a secure message via chat input', async function () {
    const chatInput = await driver.findElement(By.id('chat-input'));
    const testMessage = `E2E Automated test message - ${Date.now()}`;
    
    // Clear and type
    await chatInput.clear();
    await chatInput.sendKeys(testMessage);
    
    // Check it has been typed
    const typedVal = await chatInput.getAttribute('value');
    assert.strictEqual(typedVal, testMessage);

    // Find send button and click it
    const sendButton = await driver.findElement(By.id('chat-send-button'));
    await driver.executeScript("arguments[0].scrollIntoView({block: 'center'});", sendButton);
    await driver.executeScript("arguments[0].click();", sendButton);

    // Wait a brief moment and verify it's cleared
    const clearedVal = await chatInput.getAttribute('value');
    assert.strictEqual(clearedVal, '');

    // Verify it appeared in the chat bubbles
    await driver.wait(async () => {
      const pageSource = await driver.getPageSource();
      return pageSource.includes(testMessage);
    }, 5000, 'Sent message was not found in the chat panel history');
  });

  it('FN-05: Should toggle WebRTC Mesh protocol switch without crashing', async function () {
    const webrtcSlider = await driver.findElement(By.id('protocol-slider-webrtc-mesh'));
    assert.ok(webrtcSlider, 'WebRTC slider switch not found');
    
    // Scroll into view & click
    await driver.executeScript("arguments[0].scrollIntoView({block: 'center'});", webrtcSlider);
    await driver.sleep(200);
    await driver.executeScript("arguments[0].click();", webrtcSlider);
    
    // Verify it toggles successfully (no error thrown)
    await driver.sleep(500);
  });
});
