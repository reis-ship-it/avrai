/**
 * Chrome DevTools MCP Helper Functions for Flutter Web
 * 
 * These functions can be used directly in Chrome DevTools MCP evaluate_script calls
 * They wrap the Flutter Web Interaction Helper for easier use
 */

/**
 * Click a Flutter button by text - MCP wrapper
 * Usage in MCP: evaluate_script with this function
 */
function clickFlutterButton(buttonText) {
  // Inject helper if not already available
  if (!window.FlutterWebHelper) {
    // Helper should be injected first, but we'll define inline if needed
    const helperCode = `
      function findFlutterButtonByText(text) {
        const semantics = document.querySelectorAll('flt-semantics');
        for (const sem of semantics) {
          const textContent = sem.textContent?.trim() || '';
          const ariaLabel = sem.getAttribute('aria-label') || '';
          if (textContent.includes(text) || ariaLabel.includes(text)) {
            const role = sem.getAttribute('role');
            if (role === 'button' || sem.querySelector('[role="button"]')) {
              return sem;
            }
            let parent = sem.parentElement;
            while (parent && parent !== document.body) {
              if (parent.getAttribute('role') === 'button') return parent;
              parent = parent.parentElement;
            }
            return sem;
          }
        }
        return null;
      }
      
      function flutterClickButton(text) {
        const button = findFlutterButtonByText(text);
        if (!button) return { success: false, error: \`Button "\${text}" not found\` };
        
        const rect = button.getBoundingClientRect();
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;
        
        const events = [
          new PointerEvent('pointerdown', { bubbles: true, cancelable: true, pointerId: 1, pointerType: 'mouse', clientX: centerX, clientY: centerY }),
          new MouseEvent('mousedown', { bubbles: true, cancelable: true, button: 0, clientX: centerX, clientY: centerY }),
          new MouseEvent('mouseup', { bubbles: true, cancelable: true, button: 0, clientX: centerX, clientY: centerY }),
          new MouseEvent('click', { bubbles: true, cancelable: true, button: 0, clientX: centerX, clientY: centerY }),
          new PointerEvent('pointerup', { bubbles: true, cancelable: true, pointerId: 1, pointerType: 'mouse', clientX: centerX, clientY: centerY }),
        ];
        
        events.forEach(e => button.dispatchEvent(e));
        if (typeof button.click === 'function') button.click();
        
        return { success: true, text, coordinates: { x: centerX, y: centerY } };
      }
    `;
    eval(helperCode);
  }
  
  return window.FlutterWebHelper 
    ? window.FlutterWebHelper.flutterClickButton(buttonText)
    : flutterClickButton(buttonText);
}

/**
 * Get all interactive Flutter elements - MCP wrapper
 */
function getFlutterElements() {
  if (!window.FlutterWebHelper) {
    // Define inline if needed
    const semantics = document.querySelectorAll('flt-semantics');
    const elements = [];
    semantics.forEach((sem, index) => {
      const role = sem.getAttribute('role');
      const text = sem.textContent?.trim() || '';
      if (role && ['button', 'textbox', 'link'].includes(role)) {
        elements.push({ index, role, text: text.substring(0, 50) });
      }
    });
    return elements;
  }
  return window.FlutterWebHelper.getFlutterInteractiveElements();
}

/**
 * Click at coordinates - MCP wrapper
 */
function clickFlutterAt(x, y) {
  const element = document.elementFromPoint(x, y);
  if (!element) return { success: false, error: 'No element at coordinates' };
  
  let flutterElement = element;
  while (flutterElement && !flutterElement.tagName.includes('FLUTTER') && flutterElement !== document.body) {
    flutterElement = flutterElement.parentElement;
  }
  if (!flutterElement) flutterElement = element;
  
  const events = [
    new PointerEvent('pointerdown', { bubbles: true, cancelable: true, pointerId: 1, pointerType: 'mouse', clientX: x, clientY: y }),
    new MouseEvent('mousedown', { bubbles: true, cancelable: true, button: 0, clientX: x, clientY: y }),
    new MouseEvent('click', { bubbles: true, cancelable: true, button: 0, clientX: x, clientY: y }),
    new PointerEvent('pointerup', { bubbles: true, cancelable: true, pointerId: 1, pointerType: 'mouse', clientX: x, clientY: y }),
  ];
  
  events.forEach(e => flutterElement.dispatchEvent(e));
  return { success: true, coordinates: { x, y }, element: flutterElement.tagName };
}

// Return functions for MCP usage
return {
  clickFlutterButton,
  getFlutterElements,
  clickFlutterAt,
};
