env          = "sandbox"
env_prefix   = "sbx"

service_name = "fastapi-app"
github_repo  = "abohatyrov/logwise-test"

image        = "us-central1-docker.pkg.dev/logwise-devops-sandbox/fastapi-app-repo/fastapi-app:latest"
repo_id      = "fastapi-app-repo"

wif_pool_id     = "github-pool"
wif_provider_id = "github-provider"

tfstate_bucket = "logwise-test-tfstate"
