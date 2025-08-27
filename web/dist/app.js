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

let costChart;

function createGradient(ctx, stops) {
  const gradient = ctx.createLinearGradient(0, 0, 0, ctx.canvas.height);
  stops.forEach(([stop, color]) => gradient.addColorStop(stop, color));
  return gradient;
}

const shadowPlugin = {
  id: 'shadow',
  beforeDatasetsDraw(chart) {
    const ctx = chart.ctx;
    ctx.save();
    ctx.shadowColor = 'rgba(0,0,0,0.25)';
    ctx.shadowBlur = 10;
    ctx.shadowOffsetX = 5;
    ctx.shadowOffsetY = 5;
  },
  afterDatasetsDraw(chart) {
    chart.ctx.restore();
  }
};

const shinePlugin = {
  id: 'shine',
  afterDatasetsDraw(chart) {
    const ctx = chart.ctx;
    const { width, height, left, top } = chart.chartArea;
    const x = left + width / 2;
    const y = top + height / 2;
    const r = Math.min(width, height) / 2;
    const grad = ctx.createRadialGradient(x - r * 0.4, y - r * 0.4, 0, x - r * 0.4, y - r * 0.4, r);
    grad.addColorStop(0, 'rgba(255,255,255,0.6)');
    grad.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }
};

function updateChart(principal, interest) {
  if (principal + interest === 0) return;

  const canvas = document.getElementById('cost-chart');
  const ctx = canvas.getContext('2d');
  const principalGradient = createGradient(ctx, [
    [0, '#93c5fd'],
    [0.5, '#3b82f6'],
    [1, '#1e3a8a']
  ]);
  const interestGradient = createGradient(ctx, [
    [0, '#fdba74'],
    [0.5, '#f97316'],
    [1, '#c2410c']
  ]);
  if (!costChart) {
    costChart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: ['Total vehicle loan amount paid', 'Total interest paid'],
        datasets: [{
          data: [principal, interest],
          backgroundColor: [principalGradient, interestGradient],
          borderWidth: 0
        }]
      },
      options: {
        animation: false,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        }
      },
      plugins: [shadowPlugin, shinePlugin]
    });
  } else {
    costChart.data.datasets[0].data = [principal, interest];
    costChart.data.datasets[0].backgroundColor = [principalGradient, interestGradient];
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

      document.getElementById('fin').textContent = fmt(principal);
      document.getElementById('pay').textContent = fmt(monthly);
      document.getElementById('int').textContent = fmt(interest);
      document.getElementById('tot').textContent = fmt(total);
      
      updateChart(principal, interest);
      
      // Show success status
      calcStatus.className = 'calculation-status show success';
      calcStatus.textContent = 'Calculation completed successfully!';
      
    } catch (error) {
      // Show error status
      calcStatus.className = 'calculation-status show error';
      calcStatus.textContent = error.message;
      
      // Reset results
      document.getElementById('fin').textContent = '$0';
      document.getElementById('pay').textContent = '$0';
      document.getElementById('int').textContent = '$0';
      document.getElementById('tot').textContent = '$0';
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
