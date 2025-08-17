# Azure Playwright Workspaces Portal: Limitations & Workarounds

This document explains the known limitation of the Azure Playwright Workspaces portal (preview) where the portal shows only test run metadata and does not expose per-test artifacts (traces, screenshots, per-test logs) by default. It also provides concrete, actionable workarounds to collect and share full test results programmatically.

## Summary of the Limitation

- The Azure Playwright Workspaces portal currently stores and displays only high-level test run metadata: start/end timestamps, overall status, who ran the test, and similar summary information.
- The portal does NOT show per-test results, trace files, screenshots, or detailed artifacts in the preview release.
- This is a service-side/portal limitation and is documented in Microsoft Playwright Testing preview documentation.

## Why this matters

- When presenting or debugging tests run in Playwright Workspaces, you often need access to full artifacts (HTML reports, JSON result files, traces, screenshots). The portal's metadata-only view means you must collect artifacts yourself if you want deeper visibility.

## Recommended Workarounds

1) Use Playwright reporters to generate local artifacts

   - Configure Playwright reporters in your `playwright.config.ts` or service config. Example reporter block:

```ts
reporter: [
  ['list'],
  ['html', { outputFolder: 'playwright-report' }],
  ['json', { outputFile: 'results.json' }]
]
```

   - After a run, you'll have:
     - `playwright-report/index.html` — openable in a browser for a full HTML report
     - `results.json` — a machine-readable file containing all test results and timings

2) Collect artifacts programmatically after the test run

   - Add a post-run step in your CI or demo script that copies `playwright-report` and `results.json` to a shared location:
     - Upload to Azure Storage (Blob container)
     - Attach as CI artifacts (GitHub Actions, Azure Pipelines)
     - Push to an internal web server or artifact store

   - Example (PowerShell snippet for Azure Blob upload):

```powershell
# after tests run locally in CI
$container = 'playwright-reports'
$storageAccount = 'mystorageaccount'
az storage blob upload-batch -d $container -s ./playwright-report --account-name $storageAccount
az storage blob upload --account-name $storageAccount -c $container -f results.json -n results.json
```

3) Hybrid/demo-friendly approach

   - Run API tests in Playwright Workspaces (these work reliably because they use the `request` fixture and do not require browsers).
   - Run UI/browser tests locally or in a container you control; collect reports and share them alongside portal run metadata. This gives you both cloud execution metadata and full artifacts.

4) Troubleshooting browser connectivity errors

- If browser tests fail to connect to the Playwright Workspaces endpoint (common error: `Unexpected status 500 when connecting to Azure service`):
  - Verify `playwright.service.config.ts` service endpoint and credentials
  - Reduce running artifacts (disable tracing/nightly heavy logging), increase timeouts and try a single worker
  - Ensure no tests reference localhost-only endpoints (use public APIs or cloud-accessible mocks)
  - Check Azure role assignments and workspace permissions for your account

## Example: Post-run automated flow (CI friendly)

1. Run Playwright tests against the Playwright Workspaces service
2. Download or copy `playwright-report` and `results.json` from the runner environment
3. Upload these artifacts to a Blob storage container or attach them as CI artifacts
4. Share the portal run link (metadata) and the artifact link for full details

## References

- Microsoft Docs: Manage workspaces in Microsoft Playwright Testing Preview
  https://learn.microsoft.com/en-us/azure/playwright-testing/how-to-manage-playwright-workspace#display-the-workspace-activity-log
- Microsoft Docs: Quickstart - Generate rich reports for tests
  https://learn.microsoft.com/en-us/azure/playwright-testing/quickstart-generate-rich-reports-for-tests#run-your-tests-and-publish-results-on-microsoft-playwright-testing

## Notes

- This file is intended to be a companion to the primary demo README. Keep it under `demo/` and link to it from `demo/README.md` so presenters can quickly open the detailed explanation during demos.
