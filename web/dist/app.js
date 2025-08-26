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

function pmnt(principal, aprPct, n) {
  const r = (aprPct/100)/12;
  if (r === 0) return principal / n;
  return principal * (r * Math.pow(1+r, n)) / (Math.pow(1+r, n) - 1);
}

function fmt(n){
  return n.toLocaleString(undefined, {style:'currency', currency:'USD'})
}

let costChart;

function updateChart(principal, interest) {
  if (principal + interest === 0) return;

  const canvas = document.getElementById('cost-chart');
  const ctx = canvas.getContext('2d');
  if (!costChart) {
    costChart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: ['Total loan amount paid', 'Total interest paid'],
        datasets: [{
          data: [principal, interest],
          backgroundColor: ['#d4af37', '#10b981'],
          borderWidth: 0
        }]
      },
      options: {
        animation: false,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
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
        throw new Error('Loan amount must be greater than 0');
      }
      
      if (apr < 0 || apr > 100) {
        throw new Error('Interest rate must be between 0 and 100');
      }
      
      if (termMonths <= 0) {
        throw new Error('Loan term must be greater than 0');
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
          <p>Your application has been submitted successfully. We'll be in touch with you shortly with personalized loan offers.</p>
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
calc();
