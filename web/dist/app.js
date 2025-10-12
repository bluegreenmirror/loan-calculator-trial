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

function fmt(n){
  return n.toLocaleString(undefined, {style:'currency', currency:'USD'})
}

const scheduleTableBody = document.querySelector('#amortization-table tbody');
const scheduleStatusEl = document.getElementById('amortization-status');
const scheduleToggleBtn = document.getElementById('amortization-view-toggle');
const scheduleTableContainer = document.getElementById('amortization-table-container');
const amortizationCanvas = document.getElementById('amortization-chart');
const SCHEDULE_PAGE_SIZE = 12;
let scheduleRows = [];
let scheduleExpanded = false;
let amortizationChart;

function setScheduleStatus(message, variant = 'info') {
  if (!scheduleStatusEl) return;
  scheduleStatusEl.textContent = message || '';
  scheduleStatusEl.className = `amortization-status${variant ? ` ${variant}` : ''}`;
}

function renderSchedule() {
  if (!scheduleTableBody) return;
  scheduleTableBody.innerHTML = '';

  if (!scheduleRows.length) {
    scheduleTableContainer?.classList.add('is-empty');
    return;
  }

  scheduleTableContainer?.classList.remove('is-empty');
  const rowsToShow = scheduleExpanded ? scheduleRows : scheduleRows.slice(0, SCHEDULE_PAGE_SIZE);

  rowsToShow.forEach((row) => {
    const tr = document.createElement('tr');
    const cells = [
      { label: 'Month', value: row.month.toString() },
      { label: 'Payment', value: fmt(row.payment) },
      { label: 'Principal', value: fmt(row.principal) },
      { label: 'Interest', value: fmt(row.interest) },
      { label: 'Balance', value: fmt(row.balance) }
    ];

    cells.forEach((cell) => {
      const td = document.createElement('td');
      td.dataset.label = cell.label;
      td.textContent = cell.value;
      tr.appendChild(td);
    });

    scheduleTableBody.appendChild(tr);
  });
}

function updateSchedule(rows) {
  scheduleRows = (rows || []).map((row) => ({
    month: row.month,
    payment: row.payment,
    principal: row.principal,
    interest: row.interest,
    balance: row.balance
  }));
  scheduleExpanded = false;

  if (!scheduleRows.length) {
    renderSchedule();
    setScheduleStatus('No payments due for this scenario.', 'info');
    updateAmortizationChart([]);
    if (scheduleToggleBtn) {
      scheduleToggleBtn.hidden = true;
      scheduleToggleBtn.setAttribute('aria-expanded', 'false');
    }
    return;
  }

  renderSchedule();
  updateAmortizationChart(scheduleRows);

  if (!scheduleToggleBtn) {
    setScheduleStatus(`Showing all ${scheduleRows.length} months.`, 'info');
    return;
  }

  if (scheduleRows.length > SCHEDULE_PAGE_SIZE) {
    scheduleToggleBtn.hidden = false;
    scheduleToggleBtn.textContent = `Show full schedule (${scheduleRows.length} months)`;
    scheduleToggleBtn.setAttribute('aria-expanded', 'false');
    setScheduleStatus(`Showing first ${SCHEDULE_PAGE_SIZE} of ${scheduleRows.length} months.`, 'info');
  } else {
    scheduleToggleBtn.hidden = true;
    scheduleToggleBtn.setAttribute('aria-expanded', 'false');
    setScheduleStatus(`Showing all ${scheduleRows.length} months.`, 'info');
  }
}

function startScheduleLoading() {
  scheduleRows = [];
  scheduleExpanded = false;
  if (scheduleTableBody) {
    scheduleTableBody.innerHTML = '';
  }
  scheduleTableContainer?.classList.add('is-loading');
  scheduleTableContainer?.classList.add('is-empty');
  updateAmortizationChart([]);
  if (scheduleToggleBtn) {
    scheduleToggleBtn.hidden = true;
    scheduleToggleBtn.setAttribute('aria-expanded', 'false');
  }
  setScheduleStatus('Loading amortization schedule…', 'loading');
}

function finishScheduleLoading() {
  scheduleTableContainer?.classList.remove('is-loading');
}

function showScheduleError(message) {
  scheduleRows = [];
  scheduleExpanded = false;
  if (scheduleTableBody) {
    scheduleTableBody.innerHTML = '';
  }
  scheduleTableContainer?.classList.remove('is-loading');
  scheduleTableContainer?.classList.add('is-empty');
  updateAmortizationChart([]);
  if (scheduleToggleBtn) {
    scheduleToggleBtn.hidden = true;
    scheduleToggleBtn.setAttribute('aria-expanded', 'false');
  }
  setScheduleStatus(message, 'error');
}

if (scheduleToggleBtn) {
  scheduleToggleBtn.addEventListener('click', () => {
    if (!scheduleRows.length) return;
    scheduleExpanded = !scheduleExpanded;
    renderSchedule();
    scheduleToggleBtn.setAttribute('aria-expanded', String(scheduleExpanded));
    if (scheduleExpanded) {
      scheduleToggleBtn.textContent = 'Collapse schedule';
      setScheduleStatus(`Showing all ${scheduleRows.length} months.`, 'info');
    } else {
      scheduleToggleBtn.textContent = scheduleRows.length > SCHEDULE_PAGE_SIZE
        ? `Show full schedule (${scheduleRows.length} months)`
        : 'Show full schedule';
      if (scheduleRows.length > SCHEDULE_PAGE_SIZE) {
        setScheduleStatus(`Showing first ${SCHEDULE_PAGE_SIZE} of ${scheduleRows.length} months.`, 'info');
      } else {
        setScheduleStatus(`Showing all ${scheduleRows.length} months.`, 'info');
      }
    }
  });
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

function destroyAmortizationChart() {
  if (amortizationChart) {
    amortizationChart.destroy();
    amortizationChart = null;
  }
  amortizationCanvas?.classList.add('is-empty');
}

function updateAmortizationChart(rows) {
  if (!amortizationCanvas) return;

  if (!rows || !rows.length) {
    destroyAmortizationChart();
    return;
  }

  const labels = rows.map((row) => `Month ${row.month}`);
  const balanceSeries = rows.map((row) => Number(row.balance));
  let cumulative = 0;
  const principalSeries = rows.map((row) => {
    cumulative += Number(row.principal);
    return Number(cumulative.toFixed(2));
  });

  if (!amortizationChart) {
    amortizationChart = new Chart(amortizationCanvas.getContext('2d'), {
      type: 'line',
      data: {
        labels,
        datasets: [
          {
            label: 'Remaining balance',
            data: balanceSeries,
            borderColor: '#1d4ed8',
            backgroundColor: 'rgba(29, 78, 216, 0.1)',
            tension: 0.3,
            fill: true,
            pointRadius: 0
          },
          {
            label: 'Cumulative principal paid',
            data: principalSeries,
            borderColor: '#10b981',
            backgroundColor: 'rgba(16, 185, 129, 0.1)',
            tension: 0.3,
            fill: true,
            pointRadius: 0
          }
        ]
      },
      options: {
        animation: false,
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              usePointStyle: true,
              boxWidth: 10
            }
          },
          tooltip: {
            mode: 'index',
            intersect: false,
            callbacks: {
              label: (ctx) => `${ctx.dataset.label}: ${fmt(ctx.parsed.y)}`
            }
          }
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'Month'
            },
            ticks: {
              maxTicksLimit: 12
            }
          },
          y: {
            title: {
              display: true,
              text: 'Amount (USD)'
            },
            ticks: {
              callback: (value) => fmt(value)
            }
          }
        }
      }
    });
  } else {
    amortizationChart.data.labels = labels;
    amortizationChart.data.datasets[0].data = balanceSeries;
    amortizationChart.data.datasets[1].data = principalSeries;
    amortizationChart.update('none');
  }

  amortizationCanvas.classList.remove('is-empty');
}

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
  const x = arc.x + Math.cos(angle) * (arc.outerRadius + offset);
  const y = arc.y + Math.sin(angle) * (arc.outerRadius + offset);
  // Return explicit alignment so the tooltip caret points back toward the slice
  const xAlign = Math.abs(x - arc.x) < 1 ? 'center' : (x > arc.x ? 'left' : 'right');
  const yAlign = Math.abs(y - arc.y) < 1 ? 'center' : (y > arc.y ? 'top' : 'bottom');
  return { x, y, xAlign, yAlign };
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
          // Give the canvas breathing room so our custom outside tooltip
          // isn't clipped by the chart area. Without enough padding the
          // caret ends up inside the pie and looks cut off.
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

async function calc(){
  const calcBtn = document.getElementById('calc');
  const calcStatus = document.getElementById('calc-status');
  if (!calcBtn || !calcStatus) return;

  const price = parseFloat(document.getElementById('price').value) || 0;
  const termValue = parseFloat(document.getElementById('term').value) || 0;
  const termUnitInput = document.querySelector('input[name="term-unit"]:checked');
  const termUnit = termUnitInput ? termUnitInput.value : 'years';
  const apr = parseFloat(document.getElementById('apr').value) || 0;
  const down = parseFloat(document.getElementById('down').value) || 0;
  const fees = parseFloat(document.getElementById('fees').value) || 0;

  const termMonthsRaw = termUnit === 'years' ? termValue * 12 : termValue;
  const termMonths = Math.max(Math.round(termMonthsRaw), 0);

  calcBtn.disabled = true;
  calcBtn.textContent = 'Calculating...';
  calcStatus.className = 'calculation-status';
  calcStatus.textContent = '';

  try {
    if (price <= 0) {
      throw new Error('Vehicle loan amount must be greater than 0');
    }
    if (apr < 0 || apr > 100) {
      throw new Error('Interest rate must be between 0 and 100');
    }
    if (termMonths <= 0) {
      throw new Error('Vehicle loan term must be greater than 0 months');
    }
    if (down < 0) {
      throw new Error('Down payment cannot be negative');
    }
    if (fees < 0) {
      throw new Error('Additional fees cannot be negative');
    }

    startScheduleLoading();

    const payload = {
      vehicle_price: price,
      down_payment: down,
      apr,
      term_months: termMonths,
      tax_rate: 0,
      fees,
      trade_in_value: 0
    };

    const response = await fetch('/api/quote', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      let message = 'Unable to compute loan details. Please try again.';
      try {
        const errBody = await response.json();
        if (Array.isArray(errBody?.detail) && errBody.detail.length) {
          message = errBody.detail[0]?.msg || message;
        }
      } catch (err) {
        console.error('Failed to parse error response', err);
      }
      throw new Error(message);
    }

    const data = await response.json();
    finishScheduleLoading();

    animateNumber(document.getElementById('fin'), data.amount_financed);
    animateNumber(document.getElementById('pay'), data.monthly_payment);
    animateNumber(document.getElementById('int'), data.total_interest);
    animateNumber(document.getElementById('tot'), data.total_cost);

    updateChart(data.amount_financed, data.total_interest);
    updateSchedule(data.schedule || []);

    calcStatus.className = 'calculation-status show success';
    calcStatus.textContent = 'Calculation completed successfully!';
  } catch (error) {
    finishScheduleLoading();
    showScheduleError(`Unable to compute schedule: ${error.message}`);
    calcStatus.className = 'calculation-status show error';
    calcStatus.textContent = error.message;
    animateNumber(document.getElementById('fin'), 0);
    animateNumber(document.getElementById('pay'), 0);
    animateNumber(document.getElementById('int'), 0);
    animateNumber(document.getElementById('tot'), 0);
  } finally {
    calcBtn.disabled = false;
    calcBtn.textContent = 'Calculate';
  }
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
