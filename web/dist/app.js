const params = new URLSearchParams(window.location.search);
const aff = params.get('aff');
['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content'].forEach(k => {
  const v = params.get(k);
  if (v) localStorage.setItem(k, v);
});
if (aff) {
  localStorage.setItem('affiliate', aff);
  fetch('/api/track', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ affiliate: aff })
  });
}

const presets = {
  auto: { apr: 10, term: 5 },
  rv: { apr: 8, term: 15 },
  moto: { apr: 12, term: 5 },
  ski: { apr: 9, term: 3 }
};

function applyPreset(type) {
  const preset = presets[type];
  if (preset) {
    document.getElementById('apr').value = preset.apr;
    document.getElementById('term').value = preset.term;
    document.getElementById('years').checked = true;
  }
}

document.getElementById('vehicle').addEventListener('change', (e) => {
  applyPreset(e.target.value);
});

function pmnt(principal, aprPct, n) {
  const r = (aprPct/100)/12;
  if (r === 0) return principal / n;
  return principal * (r * Math.pow(1+r, n)) / (Math.pow(1+r, n) - 1);
}

function fmt(n){
  return n.toLocaleString(undefined, {style:'currency', currency:'USD'})
}

function animateNumber(el, value) {
  const newStr = fmt(value);
  const oldStr = el.dataset.current || el.textContent;
  el.dataset.current = newStr;
  const frag = document.createDocumentFragment();
  for (let i = 0; i < newStr.length; i++) {
    const newCh = newStr[i];
    const oldCh = oldStr[i] || '0';
    if (/\d/.test(newCh)) {
      const wrapper = document.createElement('span');
      wrapper.className = 'digit-wrapper';
      const digits = document.createElement('span');
      digits.className = 'digits';
      for (let d = 0; d < 10; d++) {
        const digit = document.createElement('span');
        digit.className = 'digit';
        digit.textContent = d;
        digits.appendChild(digit);
      }
      const startDigit = /^\d$/.test(oldCh) ? parseInt(oldCh, 10) : 0;
      digits.style.transform = `translateY(-${startDigit * 10}%)`;
      wrapper.appendChild(digits);
      frag.appendChild(wrapper);
    } else {
      const span = document.createElement('span');
      span.className = 'digit-symbol';
      span.textContent = newCh;
      frag.appendChild(span);
    }
  }
  el.innerHTML = '';
  el.appendChild(frag);
  requestAnimationFrame(() => {
    const digitElems = el.querySelectorAll('.digits');
    let idx = 0;
    for (let i = 0; i < newStr.length; i++) {
      const ch = newStr[i];
      if (/\d/.test(ch)) {
        const digits = digitElems[idx++];
        digits.style.transition = 'transform 0.5s cubic-bezier(0.2, 0.8, 0.4, 1)';
        digits.style.transform = `translateY(-${parseInt(ch, 10) * 10}%)`;
      }
    }
  });
}

let costChart;

// Grab Chart.js' Tooltip helper so we can extend it. When using the CDN build
// the helper lives on the global `Chart` object.
const { Tooltip } = Chart;

// Custom tooltip positioner that places the tooltip outside the pie slice.
// Without this, Chart.js centers the tooltip on the slice, leaving the caret
// inside the chart where it gets clipped. Attaching our function to
// `Tooltip.positioners` registers the new option value `position: 'outside'`.
Tooltip.positioners.outside = function (items) {
  if (!items.length) return false;
  const arc = items[0].element;
  const angle = (arc.startAngle + arc.endAngle) / 2;
  const offset = 16; // pixels away from the outer edge of the pie
  return {
    x: arc.x + Math.cos(angle) * (arc.outerRadius + offset),
    y: arc.y + Math.sin(angle) * (arc.outerRadius + offset)
  };
};

function updateChart(principal, interest) {
  if (principal + interest === 0) return;

  const canvas = document.getElementById('cost-chart');
  const ctx = canvas.getContext('2d');
  if (!costChart) {
    costChart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: ['Total vehicle loan amount paid', 'Total interest paid'],
        datasets: [{
          data: [principal, interest],
          backgroundColor: ['#d4af37', '#10b981'],
          borderWidth: 0
        }]
      },
      options: {
        animation: false,
        maintainAspectRatio: false,
        layout: {
          // Pad canvas so our external tooltips have room to render
          padding: 24
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            // Float tooltip outside the pie using the custom positioner above
            position: 'outside'
          }
        }
      }
    });
  } else {
    costChart.data.datasets[0].data = [principal, interest];
    costChart.update('none');
  }

  canvas.classList.remove('bounce');
  void canvas.offsetWidth;
  canvas.classList.add('bounce');
}

function calc(){
  const calcBtn = document.getElementById('calc');
  const calcStatus = document.getElementById('calc-status');
  
  // Get values
  const price = +document.getElementById('price').value || 0;
  const term = +document.getElementById('term').value || 1;
  const termUnit = document.querySelector('input[name="term-unit"]:checked').value;
  const apr = +document.getElementById('apr').value || 0;
  const down = +document.getElementById('down').value || 0;
  const fees = +document.getElementById('fees').value || 0;

  // Convert term to months if needed
  const termMonths = termUnit === 'years' ? term * 12 : term;

  // Show loading state
  calcBtn.disabled = true;
  calcBtn.textContent = 'Calculating...';
  calcStatus.className = 'calculation-status';
  calcStatus.textContent = '';

  // Simulate calculation delay for better UX
  setTimeout(() => {
    try {
      if (price <= 0) {
        throw new Error('Vehicle loan amount must be greater than 0');
      }
      
      if (apr < 0 || apr > 100) {
        throw new Error('Interest rate must be between 0 and 100');
      }
      
      if (termMonths <= 0) {
        throw new Error('Vehicle loan term must be greater than 0');
      }

      const principal = Math.max(price + fees - down, 0);
      const monthly = pmnt(principal, apr, termMonths);
      const total = monthly * termMonths;
      const interest = Math.max(total - principal, 0);

      animateNumber(document.getElementById('fin'), principal);
      animateNumber(document.getElementById('pay'), monthly);
      animateNumber(document.getElementById('int'), interest);
      animateNumber(document.getElementById('tot'), total);
      
      updateChart(principal, interest);
      
      // Show success status
      calcStatus.className = 'calculation-status show success';
      calcStatus.textContent = 'Calculation completed successfully!';
      
    } catch (error) {
      // Show error status
      calcStatus.className = 'calculation-status show error';
      calcStatus.textContent = error.message;
      
      // Reset results
      animateNumber(document.getElementById('fin'), 0);
      animateNumber(document.getElementById('pay'), 0);
      animateNumber(document.getElementById('int'), 0);
      animateNumber(document.getElementById('tot'), 0);
    } finally {
      // Reset button state
      calcBtn.disabled = false;
      calcBtn.textContent = 'Calculate';
    }
  }, 500);
}

function toggleExpandable(sectionId) {
  const content = document.getElementById(sectionId + '-content');
  const icon = content.previousElementSibling.querySelector('.expandable-icon');
  
  content.classList.toggle('show');
  icon.style.transform = content.classList.contains('show') ? 'rotate(180deg)' : 'rotate(0deg)';
}

// Lead generation functions
function openLeadModal() {
  document.getElementById('lead-modal').classList.add('show');
  // Pre-fill price from calculator
  document.getElementById('lead-price').value = document.getElementById('price').value;
  document.getElementById('lead-vehicle').value = document.getElementById('vehicle').value;
}

function closeLeadModal() {
  document.getElementById('lead-modal').classList.remove('show');
  // Reset form
  document.getElementById('lead-form').reset();
  // Reset modal content
  document.getElementById('modal-content').innerHTML = document.getElementById('modal-content').innerHTML;
  // Re-attach event listener
  document.getElementById('lead-form').addEventListener('submit', handleLeadSubmission);
}

async function handleLeadSubmission(e) {
  e.preventDefault();
  
  const submitBtn = document.getElementById('submit-lead');
  const submitText = document.getElementById('submit-text');
  const submitLoading = document.getElementById('submit-loading');
  
  // Show loading state
  submitBtn.disabled = true;
  submitText.style.display = 'none';
  submitLoading.style.display = 'inline-block';
  
  try {
    const formData = {
      name: document.getElementById('lead-name').value + ' ' + document.getElementById('lead-lastname').value,
      email: document.getElementById('lead-email').value,
      phone: document.getElementById('lead-phone').value || null,
      vehicle_type: document.getElementById('lead-vehicle').value,
      price: parseFloat(document.getElementById('lead-price').value) || null,
      affiliate: localStorage.getItem('affiliate') || null
    };
    
    const response = await fetch('/api/leads', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(formData)
    });
    
    if (response.ok) {
      // Show success message
      document.getElementById('modal-content').innerHTML = `
        <div class="success-message">
          <h4>Thank You!</h4>
          <p>Your application has been submitted successfully. We'll be in touch shortly with personalized vehicle loan offers.</p>
        </div>
      `;
      
      // Close modal after 3 seconds
      setTimeout(() => {
        closeLeadModal();
      }, 3000);
    } else {
      throw new Error('Failed to submit lead');
    }
  } catch (error) {
    console.error('Error submitting lead:', error);
    // Show error message
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.textContent = 'There was an error submitting your application. Please try again.';
    
    const modalContent = document.getElementById('modal-content');
    modalContent.insertBefore(errorDiv, modalContent.firstChild);
    
    // Reset button state
    submitBtn.disabled = false;
    submitText.style.display = 'inline';
    submitLoading.style.display = 'none';
  }
}

// Event listeners
document.getElementById('calc').addEventListener('click', calc);

// Lead button listener
document.getElementById('lead-btn').addEventListener('click', () => {
  openLeadModal();
});

// Lead form submission
document.getElementById('lead-form').addEventListener('submit', handleLeadSubmission);

// Initialize with default values
applyPreset(document.getElementById('vehicle').value);
calc();

async function setServerDate() {
  try {
    const res = await fetch('/api/health', { cache: 'no-store' });
    const dateHeader = res.headers.get('Date');
    if (dateHeader) {
      const formatted = new Date(dateHeader).toLocaleDateString('en-US', {
        month: 'short', day: 'numeric', year: 'numeric'
      });
      const headerDate = document.querySelector('.date');
      if (headerDate) headerDate.textContent = formatted;
      document.querySelectorAll('.disclaimer-date').forEach(el => {
        el.textContent = formatted;
      });
    }
  } catch (err) {
    console.error('Failed to fetch server date', err);
  }
}
setServerDate();
