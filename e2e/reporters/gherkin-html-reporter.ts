import type {
  FullConfig,
  FullResult,
  Reporter,
  Suite,
  TestCase,
  TestResult,
} from '@playwright/test/reporter';
import * as fs from 'fs';
import * as path from 'path';

interface StepResult {
  title: string;
  status: 'passed' | 'failed' | 'skipped' | 'timedOut' | 'interrupted';
  duration: number;
  error?: string;
  screenshots: string[];
}

interface FeatureResult {
  name: string;
  steps: StepResult[];
}

class GherkinHtmlReporter implements Reporter {
  private features: Map<string, FeatureResult> = new Map();
  private outputDir: string;
  private startTime = 0;

  constructor(options?: { outputDir?: string }) {
    this.outputDir = options?.outputDir || 'gherkin-report';
  }

  onBegin(_config: FullConfig, _suite: Suite) {
    this.startTime = Date.now();
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }
    const screenshotsDir = path.join(this.outputDir, 'screenshots');
    if (!fs.existsSync(screenshotsDir)) {
      fs.mkdirSync(screenshotsDir, { recursive: true });
    }
  }

  onTestEnd(test: TestCase, result: TestResult) {
    const suiteName = test.parent?.title || 'Unnamed Feature';

    if (!this.features.has(suiteName)) {
      this.features.set(suiteName, { name: suiteName, steps: [] });
    }
    const feature = this.features.get(suiteName)!;

    const screenshots: string[] = [];
    for (const attachment of result.attachments) {
      if (attachment.contentType === 'image/png' && attachment.path) {
        const destName = `${test.title.replace(/[^a-z0-9]/gi, '-').substring(0, 60)}-${screenshots.length}.png`;
        const destPath = path.join(this.outputDir, 'screenshots', destName);
        try {
          fs.copyFileSync(attachment.path, destPath);
          screenshots.push(`screenshots/${destName}`);
        } catch { /* skip */ }
      }
    }

    feature.steps.push({
      title: test.title,
      status: result.status,
      duration: result.duration,
      error: result.errors?.[0]?.message?.substring(0, 500),
      screenshots,
    });
  }

  onEnd(result: FullResult) {
    const totalDuration = Date.now() - this.startTime;
    const html = this.generateHtml(result, totalDuration);
    const reportPath = path.join(this.outputDir, 'index.html');
    fs.writeFileSync(reportPath, html, 'utf-8');
    console.log(`\n  Gherkin HTML Report: ${path.resolve(reportPath)}\n`);
  }

  private generateHtml(result: FullResult, totalDuration: number): string {
    let totalPassed = 0;
    let totalFailed = 0;
    let totalSkipped = 0;

    for (const feature of this.features.values()) {
      for (const step of feature.steps) {
        if (step.status === 'passed') totalPassed++;
        else if (step.status === 'failed' || step.status === 'timedOut') totalFailed++;
        else totalSkipped++;
      }
    }

    const total = totalPassed + totalFailed + totalSkipped;
    const passRate = total > 0 ? Math.round((totalPassed / total) * 100) : 0;
    const overallStatus = result.status;

    let featuresHtml = '';
    for (const feature of this.features.values()) {
      const featurePassed = feature.steps.filter(s => s.status === 'passed').length;
      const featureTotal = feature.steps.length;
      const featureStatus = feature.steps.every(s => s.status === 'passed') ? 'passed' : 'failed';

      let stepsHtml = '';
      for (const step of feature.steps) {
        const icon = step.status === 'passed' ? '&#10004;' : step.status === 'failed' || step.status === 'timedOut' ? '&#10008;' : '&#9679;';
        const statusClass = step.status === 'passed' ? 'pass' : step.status === 'failed' || step.status === 'timedOut' ? 'fail' : 'skip';
        const dur = (step.duration / 1000).toFixed(1);

        let screenshotsHtml = '';
        if (step.screenshots.length > 0) {
          screenshotsHtml = '<div class="screenshots">';
          for (const src of step.screenshots) {
            screenshotsHtml += `<img src="${src}" alt="${step.title}" loading="lazy" onclick="openModal(this.src)" />`;
          }
          screenshotsHtml += '</div>';
        }

        let errorHtml = '';
        if (step.error) {
          errorHtml = `<div class="error-msg"><pre>${this.escapeHtml(step.error)}</pre></div>`;
        }

        // Detect Gherkin keyword
        const gherkinMatch = step.title.match(/^(Given|When|And|Then|But)\s/i);
        const keyword = gherkinMatch ? `<span class="keyword">${gherkinMatch[1]}</span> ` : '';
        const stepText = gherkinMatch ? step.title.substring(gherkinMatch[0].length) : step.title;

        stepsHtml += `
          <div class="step ${statusClass}">
            <div class="step-header">
              <span class="step-icon ${statusClass}">${icon}</span>
              <span class="step-text">${keyword}${this.escapeHtml(stepText)}</span>
              <span class="step-duration">${dur}s</span>
            </div>
            ${errorHtml}
            ${screenshotsHtml}
          </div>`;
      }

      featuresHtml += `
        <div class="feature ${featureStatus}">
          <div class="feature-header">
            <h2>
              <span class="feature-badge ${featureStatus}">${featureStatus === 'passed' ? 'PASSED' : 'FAILED'}</span>
              ${this.escapeHtml(feature.name)}
            </h2>
            <span class="feature-summary">${featurePassed}/${featureTotal} steps passed</span>
          </div>
          <div class="steps">${stepsHtml}</div>
        </div>`;
    }

    const durStr = this.formatDuration(totalDuration);
    const now = new Date().toLocaleString();

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>WabiCare E2E Test Report</title>
  <style>
    :root {
      --pass: #22c55e; --pass-bg: #f0fdf4; --pass-border: #86efac;
      --fail: #ef4444; --fail-bg: #fef2f2; --fail-border: #fca5a5;
      --skip: #f59e0b; --skip-bg: #fffbeb; --skip-border: #fcd34d;
      --bg: #f8fafc; --surface: #ffffff; --text: #1e293b;
      --muted: #64748b; --border: #e2e8f0;
      --primary: #7c3aed; --primary-light: #ede9fe;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: var(--bg); color: var(--text); line-height: 1.6; }

    .header { background: linear-gradient(135deg, #7c3aed 0%, #2563eb 100%); color: white; padding: 2rem 2rem 3rem; }
    .header h1 { font-size: 1.75rem; font-weight: 700; margin-bottom: 0.25rem; }
    .header .subtitle { opacity: 0.85; font-size: 0.95rem; }

    .summary-cards { display: flex; gap: 1rem; margin: -1.5rem 2rem 2rem; flex-wrap: wrap; }
    .card { flex: 1; min-width: 140px; background: var(--surface); border-radius: 12px; padding: 1.25rem; box-shadow: 0 4px 12px rgba(0,0,0,0.08); text-align: center; }
    .card .value { font-size: 2rem; font-weight: 800; }
    .card .label { font-size: 0.8rem; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; margin-top: 0.25rem; }
    .card.pass .value { color: var(--pass); }
    .card.fail .value { color: var(--fail); }
    .card.skip .value { color: var(--skip); }
    .card.total .value { color: var(--primary); }

    .progress-bar { margin: 0 2rem 2rem; background: var(--border); border-radius: 8px; height: 10px; overflow: hidden; }
    .progress-fill { height: 100%; border-radius: 8px; transition: width 0.5s; }
    .progress-fill.good { background: linear-gradient(90deg, #22c55e, #4ade80); }
    .progress-fill.warn { background: linear-gradient(90deg, #f59e0b, #fbbf24); }
    .progress-fill.bad { background: linear-gradient(90deg, #ef4444, #f87171); }

    .container { max-width: 1100px; margin: 0 auto; padding: 0 2rem 3rem; }

    .feature { background: var(--surface); border-radius: 12px; margin-bottom: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.05); overflow: hidden; border-left: 4px solid var(--pass); }
    .feature.failed { border-left-color: var(--fail); }
    .feature-header { display: flex; align-items: center; justify-content: space-between; padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border); }
    .feature-header h2 { font-size: 1.1rem; font-weight: 600; display: flex; align-items: center; gap: 0.75rem; }
    .feature-badge { font-size: 0.65rem; font-weight: 700; padding: 0.2rem 0.6rem; border-radius: 999px; text-transform: uppercase; letter-spacing: 0.05em; }
    .feature-badge.passed { background: var(--pass-bg); color: var(--pass); border: 1px solid var(--pass-border); }
    .feature-badge.failed { background: var(--fail-bg); color: var(--fail); border: 1px solid var(--fail-border); }
    .feature-summary { font-size: 0.85rem; color: var(--muted); }

    .steps { padding: 0.5rem 0; }
    .step { padding: 0.75rem 1.5rem; transition: background 0.15s; }
    .step:hover { background: #f8fafc; }
    .step-header { display: flex; align-items: center; gap: 0.75rem; }
    .step-icon { font-size: 1rem; font-weight: 700; width: 1.5rem; text-align: center; flex-shrink: 0; }
    .step-icon.pass { color: var(--pass); }
    .step-icon.fail { color: var(--fail); }
    .step-icon.skip { color: var(--skip); }
    .step-text { flex: 1; font-size: 0.95rem; }
    .keyword { color: var(--primary); font-weight: 700; }
    .step-duration { font-size: 0.8rem; color: var(--muted); min-width: 3.5rem; text-align: right; }

    .error-msg { margin: 0.5rem 0 0.5rem 2.25rem; background: var(--fail-bg); border: 1px solid var(--fail-border); border-radius: 8px; padding: 0.75rem 1rem; }
    .error-msg pre { font-size: 0.8rem; color: var(--fail); white-space: pre-wrap; word-break: break-word; font-family: 'Fira Code', monospace; }

    .screenshots { display: flex; gap: 0.5rem; margin: 0.75rem 0 0.5rem 2.25rem; flex-wrap: wrap; }
    .screenshots img { width: 180px; height: 110px; object-fit: cover; border-radius: 8px; border: 2px solid var(--border); cursor: pointer; transition: transform 0.2s, box-shadow 0.2s; }
    .screenshots img:hover { transform: scale(1.05); box-shadow: 0 4px 16px rgba(0,0,0,0.15); }

    .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); z-index: 1000; justify-content: center; align-items: center; cursor: pointer; }
    .modal.active { display: flex; }
    .modal img { max-width: 90vw; max-height: 90vh; border-radius: 8px; box-shadow: 0 8px 32px rgba(0,0,0,0.3); }

    .footer { text-align: center; padding: 2rem; color: var(--muted); font-size: 0.85rem; }
    .footer a { color: var(--primary); text-decoration: none; }

    @media (max-width: 640px) {
      .summary-cards { flex-direction: column; }
      .feature-header { flex-direction: column; align-items: flex-start; gap: 0.5rem; }
      .screenshots img { width: 140px; height: 85px; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>WabiCare E2E Test Report</h1>
    <div class="subtitle">Patient Intake Automation &mdash; ${now} &mdash; Duration: ${durStr}</div>
  </div>

  <div class="summary-cards">
    <div class="card total"><div class="value">${total}</div><div class="label">Total Steps</div></div>
    <div class="card pass"><div class="value">${totalPassed}</div><div class="label">Passed</div></div>
    <div class="card fail"><div class="value">${totalFailed}</div><div class="label">Failed</div></div>
    <div class="card skip"><div class="value">${totalSkipped}</div><div class="label">Skipped</div></div>
    <div class="card total"><div class="value">${passRate}%</div><div class="label">Pass Rate</div></div>
  </div>

  <div class="progress-bar">
    <div class="progress-fill ${passRate >= 80 ? 'good' : passRate >= 50 ? 'warn' : 'bad'}" style="width: ${passRate}%"></div>
  </div>

  <div class="container">
    ${featuresHtml}
  </div>

  <div class="footer">
    Generated by <a href="#">WabiCare E2E</a> &middot; Playwright ${overallStatus}
  </div>

  <div class="modal" id="modal" onclick="closeModal()">
    <img id="modal-img" src="" alt="Screenshot" />
  </div>

  <script>
    function openModal(src) { document.getElementById('modal').classList.add('active'); document.getElementById('modal-img').src = src; }
    function closeModal() { document.getElementById('modal').classList.remove('active'); }
    document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });
  </script>
</body>
</html>`;
  }

  private formatDuration(ms: number): string {
    const s = Math.floor(ms / 1000);
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return m > 0 ? `${m}m ${sec}s` : `${sec}s`;
  }

  private escapeHtml(text: string): string {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
}

export default GherkinHtmlReporter;
