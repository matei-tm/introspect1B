# vlabs-action-test

- Add GitHub secrets:
  - `SITE_USER` : username
  - `SITE_PASSWORD` : password


- Run locally (PowerShell):
  $env:SITE_USER = "youruser"
  $env:SITE_PASSWORD = "yourpass"
  npm ci
  npx playwright install --with-deps
  npm test

- CI:
  - The workflow ` .github/workflows/ci.yml` uses the repository secrets above.
 
<img width="658" height="304" alt="image" src="https://github.com/user-attachments/assets/62fc55e1-74b0-4791-9c49-4bbb93a41f89" />

