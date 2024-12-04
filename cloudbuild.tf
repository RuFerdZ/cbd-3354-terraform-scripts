# Create a connection to GitHub
resource "google_cloudbuildv2_connection" "github-connection" {
  location  = "northamerica-northeast2"
  name = "github-connection"

  github_config {
    app_installation_id = 57459811
    authorizer_credential {
      oauth_token_secret_version = "projects/952988696368/secrets/github-pat-token/versions/2"
    }
  }
}

# Link the backend repository to Cloud Build
resource "google_cloudbuildv2_repository" "backend-repository" {
  name = "cbd-3354-assignment-01-c0918066-backend"
  parent_connection = google_cloudbuildv2_connection.github-connection.id
  remote_uri = "https://github.com/RuFerdZ/cbd-3354-assignment-01-c0918066-backend.git"
}

# Cloud Build Trigger for Backend
resource "google_cloudbuild_trigger" "backend_trigger" {
  location = "northamerica-northeast2"
  name        = "backend-trigger"
  description = "Cloud Build pipeline for the backend application"
  
  repository_event_config {
    repository = google_cloudbuildv2_repository.backend-repository.id
    push {
      branch = "main"
    }
  }

  filename = "cloudbuild.yaml"
}


# Link the frontend repository to Cloud Build
resource "google_cloudbuildv2_repository" "frontend-repository" {
  name = "cbd-3354-assignment-01-c0918066-frontend"
  parent_connection = google_cloudbuildv2_connection.github-connection.id
  remote_uri = "https://github.com/RuFerdZ/cbd-3354-assignment-01-c0918066-frontend.git"
}


# Cloud Build Trigger for Frontend
resource "google_cloudbuild_trigger" "frontend_trigger" {
  location = "northamerica-northeast2"
  name        = "frontend-trigger"
  description = "Cloud Build pipeline for the frontend application"
  
  repository_event_config {
    repository = google_cloudbuildv2_repository.frontend-repository.id
    push {
      branch = "main"
    }
  }

  filename = "cloudbuild.yaml"
}