# Migration: Docker Blue/Green → Google Cloud Run "Lightweight" Deployment

This guide documents the end-to-end plan for moving the Vehicle Loan Calculator
from a single VM running Docker blue/green deployments (with Cloudflare DNS)
to Google Cloud's fully managed, lightweight Cloud Run platform. The objective
is to retain all existing functionality (API + SPA + persistence) while
removing the need to manage servers directly.

______________________________________________________________________

## Target architecture overview

| Concern     | Old world                                   | New world                                                     |
| ----------- | ------------------------------------------- | ------------------------------------------------------------- |
| Compute     | Self-managed VM + docker compose blue/green | Cloud Run service (`loan-calculator`)                         |
| Routing     | Caddy (edge) + Cloudflare                   | Cloud Run HTTPS endpoint + Cloudflare CNAME (proxied)         |
| Static SPA  | Caddy serving `web/dist`                    | FastAPI serves SPA directly (baked into image)                |
| API         | FastAPI container (`api` service)           | Same FastAPI app in Cloud Run image                           |
| Persistence | `/data` Docker volume shared between colors | Cloud Storage bucket mounted via Cloud Run volumes at `/data` |
| TLS         | Caddy + Cloudflare Full (strict)            | Cloud Run managed cert, Cloudflare still in front             |

Key repo changes enabling this migration:

1. `Dockerfile.cloudrun` builds a single container containing the API and SPA
   assets, listening on port 8080 per Cloud Run conventions.
1. `STATIC_ROOT` handling in `api/app.py` allows the FastAPI app to serve the
   compiled SPA and assets without Caddy.
1. New tests (`tests/test_static.py`) cover SPA + API compatibility.

______________________________________________________________________

## Migration plan

The migration is broken into four phases to minimise risk.

### Phase 0 – Preparation

- [ ] Select or create a Google Cloud project.
- [ ] Enable APIs: `run.googleapis.com`, `artifactregistry.googleapis.com`,
  `cloudbuild.googleapis.com`.
- [ ] Install/upgrade the `gcloud` CLI (>= 468.0.0 for Cloud Run volumes).
- [ ] Create a dedicated service account (e.g. `loan-calculator-deployer`) with
  roles: `roles/run.admin`, `roles/artifactregistry.writer`,
  `roles/iam.serviceAccountUser`.
- [ ] Create an Artifact Registry repo (e.g. `us-docker.pkg.dev/<PROJECT>/loan-calculator/app`).

### Phase 1 – Build + publish container

1. Check out the repository and ensure `web/dist` contains the latest build.

1. Build and push the Cloud Run image:

   ```bash
   gcloud auth login
   gcloud auth configure-docker us-docker.pkg.dev

   IMAGE=us-docker.pkg.dev/$PROJECT/loan-calculator/app:$(git rev-parse --short HEAD)
   gcloud builds submit --tag "$IMAGE" --config <(cat <<'YAML'
   steps:
     - name: 'gcr.io/cloud-builders/docker'
       args: ['build', '-t', '$IMAGE', '-f', 'Dockerfile.cloudrun', '.']
   images:
     - '$IMAGE'
   YAML
   )
   ```

1. Record the image digest; it will be used for canary + rollback.

### Phase 2 – Provision persistence + deploy canary

1. Create a regional (same region as Cloud Run) Cloud Storage bucket for lead
   data, e.g. `gs://loan-calculator-prod-data`.

1. Grant the Cloud Run runtime service account `roles/storage.objectAdmin` on
   the bucket.

1. Deploy a staging Cloud Run service to validate the container and bucket
   mount:

   ```bash
   REGION=us-central1
   SERVICE_ACCOUNT=loan-calculator-runtime@${PROJECT}.iam.gserviceaccount.com

   gcloud beta run deploy loan-calculator-staging \
     --project "$PROJECT" \
     --region "$REGION" \
     --image "$IMAGE" \
     --service-account "$SERVICE_ACCOUNT" \
     --port 8080 \
     --allow-unauthenticated \
     --set-env-vars "PERSIST_DIR=/data" \
     --set-env-vars "STATIC_ROOT=/app/static" \
     --volume name=lead-data,type=cloud-storage,bucket=loan-calculator-prod-data \
     --volume-mount volume=lead-data,mount-path=/data
   ```

1. Validate staging: `/api/health`, SPA load, lead + track submissions (confirm
   JSON files appear in the bucket).

### Phase 3 – Production cutover

1. Deploy `loan-calculator` production service with the same command as above
   (change service name, optionally use min instances = 1).
1. Update Cloudflare DNS:
   - Set `A`/`AAAA` records to "DNS only" temporarily.
   - Create proxied CNAMEs (`@`, `www`) pointing to the Cloud Run hostname
     (`https://loan-calculator-<hash>-<region>.a.run.app`).
   - After propagation, re-enable the orange cloud.
1. Smoke tests:
   - `curl -sS https://<domain>/api/health`
   - Load SPA via browser.
   - Submit test lead/track and confirm Cloud Storage entries.

### Phase 4 – Decommission legacy infra

- Shut down docker compose services on the VM and remove persistent volumes
  once data is confirmed in Cloud Storage.
- Archive or repurpose the server after a cooling-off period.
- Update runbooks to point to this document.

______________________________________________________________________

## Rollback strategy

- **Cloud Run revision rollback:** `gcloud run services update-traffic` can send
  100% traffic back to the previous revision instantly.
- **DNS rollback:** restore previous Cloudflare origin IP (from before the
  CNAME change) and disable the Cloud Run service.
- **Data:** Cloud Storage retains JSON history; restoring to the VM just
  requires syncing the bucket contents to `/data`.

______________________________________________________________________

## Validation checklist

- [ ] `/api/health` returns 200 via Cloud Run URL and custom domain.
- [ ] SPA loads and fetches quotes successfully.
- [ ] Leads and tracks persist in Cloud Storage bucket.
- [ ] Cloudflare proxy remains in "Full (strict)" TLS mode.
- [ ] Old docker blue/green jobs are stopped.

Keep this document with release notes for auditability.
