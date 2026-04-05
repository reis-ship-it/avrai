/**
 * Flutter Web Interaction Helper for Chrome DevTools MCP
 * 
 * This script provides utilities to interact with Flutter web apps
 * which use custom rendering (flutter-view, flt-semantics).
 * 
 * Usage in Chrome DevTools MCP:
 * - Use evaluate_script to inject and call these functions
 * - Example: evaluate_script with function that calls flutterClickButton('Next')
 */

/**
 * Finds a Flutter button by text content using accessibility tree
 * @param {string} text - The button text to find
 * @returns {Element|null} - The button element or null
 */
function findFlutterButtonByText(text) {
  // Flutter web uses flt-semantics for accessibility
  const semantics = document.querySelectorAll('flt-semantics');
  
  for (const sem of semantics) {
    const textContent = sem.textContent?.trim() || '';
    const ariaLabel = sem.getAttribute('aria-label') || '';
    
    // Check if this element contains the button text
    if (textContent.includes(text) || ariaLabel.includes(text)) {
      // Check if it's a button (has role="button" or is clickable)
      const role = sem.getAttribute('role');
      if (role === 'button' || sem.querySelector('[role="button"]')) {
        return sem;
      }
      
      // Also check parent elements
      let parent = sem.parentElement;
      while (parent && parent !== document.body) {
        if (parent.getAttribute('role') === 'button') {
          return parent;
        }
        parent = parent.parentElement;
      }
      
      // If no explicit button role, but has click handler, return it
      return sem;
    }
  }
  
  return null;
}

/**
 * Clicks a Flutter button by text
 * @param {string} text - The button text to click
 * @returns {Object} - Result object with success status
 */
function flutterClickButton(text) {
  const button = findFlutterButtonByText(text);
  
  if (!button) {
    return { success: false, error: `Button with text "${text}" not found` };
  }
  
  try {
    // Flutter web handles clicks through pointer events
    // Dispatch multiple event types to ensure Flutter catches it
    const events = [
      new PointerEvent('pointerdown', {
        bubbles: true,
        cancelable: true,
        pointerId: 1,
        pointerType: 'mouse',
        clientX: 0,
        clientY: 0,
      }),
      new MouseEvent('mousedown', {
        bubbles: true,
        cancelable: true,
        button: 0,
      }),
      new MouseEvent('mouseup', {
        bubbles: true,
        cancelable: true,
        button: 0,
      }),
      new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        button: 0,
      }),
      new PointerEvent('pointerup', {
        bubbles: true,
        cancelable: true,
        pointerId: 1,
        pointerType: 'mouse',
        clientX: 0,
        clientY: 0,
      }),
    ];
    
    // Get button's bounding rect for accurate coordinates
    const rect = button.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    
    // Update events with correct coordinates
    events.forEach(event => {
      if (event instanceof PointerEvent || event instanceof MouseEvent) {
        Object.defineProperty(event, 'clientX', { value: centerX, writable: false });
        Object.defineProperty(event, 'clientY', { value: centerY, writable: false });
      }
    });
    
    // Dispatch events in sequence
    events.forEach(event => {
      button.dispatchEvent(event);
    });
    
    // Also try direct click as fallback
    if (typeof button.click === 'function') {
      button.click();
    }
    
    return { 
      success: true, 
      text: text,
      element: button.tagName,
      coordinates: { x: centerX, y: centerY }
    };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

/**
 * Finds and fills a Flutter text field
 * @param {string} labelOrHint - The label or hint text of the field
 * @param {string} value - The value to fill
 * @returns {Object} - Result object with success status
 */
function flutterFillTextField(labelOrHint, value) {
  const semantics = document.querySelectorAll('flt-semantics');
  
  for (const sem of semantics) {
    const textContent = sem.textContent?.trim() || '';
    const ariaLabel = sem.getAttribute('aria-label') || '';
    const role = sem.getAttribute('role');
    
    // Check if this is a text field
    if (role === 'textbox' || sem.querySelector('input, textarea, [role="textbox"]')) {
      // Check if label/hint matches
      if (textContent.includes(labelOrHint) || ariaLabel.includes(labelOrHint)) {
        const input = sem.querySelector('input, textarea') || sem;
        
        // Set value and trigger input events
        input.value = value;
        input.dispatchEvent(new Event('input', { bubbles: true }));
        input.dispatchEvent(new Event('change', { bubbles: true }));
        
        return { success: true, labelOrHint, value };
      }
    }
  }
  
  return { success: false, error: `TextField with label/hint "${labelOrHint}" not found` };
}

/**
 * Gets all interactive Flutter elements
 * @returns {Array} - Array of element info objects
 */
function getFlutterInteractiveElements() {
  const elements = [];
  const semantics = document.querySelectorAll('flt-semantics');
  
  semantics.forEach((sem, index) => {
    const role = sem.getAttribute('role');
    const text = sem.textContent?.trim() || '';
    const ariaLabel = sem.getAttribute('aria-label') || '';
    
    if (role && ['button', 'textbox', 'link', 'checkbox', 'radio', 'switch'].includes(role)) {
      elements.push({
        index,
        role,
        text: text.substring(0, 50),
        ariaLabel: ariaLabel.substring(0, 50),
        tag: sem.tagName,
        uid: `flutter_element_${index}`,
      });
    }
  });
  
  return elements;
}

/**
 * Clicks an element by coordinates (useful for Flutter web)
 * @param {number} x - X coordinate
 * @param {number} y - Y coordinate
 * @returns {Object} - Result object
 */
function flutterClickAtCoordinates(x, y) {
  const element = document.elementFromPoint(x, y);
  
  if (!element) {
    return { success: false, error: 'No element at coordinates' };
  }
  
  // Find the nearest Flutter semantics element
  let flutterElement = element;
  while (flutterElement && !flutterElement.tagName.includes('FLUTTER') && flutterElement !== document.body) {
    flutterElement = flutterElement.parentElement;
  }
  
  if (!flutterElement) {
    flutterElement = element;
  }
  
  // Dispatch click events
  const events = [
    new PointerEvent('pointerdown', {
      bubbles: true,
      cancelable: true,
      pointerId: 1,
      pointerType: 'mouse',
      clientX: x,
      clientY: y,
    }),
    new MouseEvent('mousedown', {
      bubbles: true,
      cancelable: true,
      button: 0,
      clientX: x,
      clientY: y,
    }),
    new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      button: 0,
      clientX: x,
      clientY: y,
    }),
    new PointerEvent('pointerup', {
      bubbles: true,
      cancelable: true,
      pointerId: 1,
      pointerType: 'mouse',
      clientX: x,
      clientY: y,
    }),
  ];
  
  events.forEach(event => {
    flutterElement.dispatchEvent(event);
  });
  
  return { 
    success: true, 
    coordinates: { x, y },
    element: flutterElement.tagName 
  };
}

// Export functions for use in Chrome DevTools MCP
if (typeof window !== 'undefined') {
  window.FlutterWebHelper = {
    findFlutterButtonByText,
    flutterClickButton,
    flutterFillTextField,
    getFlutterInteractiveElements,
    flutterClickAtCoordinates,
  };
}

// For Node.js/Chrome DevTools MCP usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    findFlutterButtonByText,
    flutterClickButton,
    flutterFillTextField,
    getFlutterInteractiveElements,
    flutterClickAtCoordinates,
  };
}
