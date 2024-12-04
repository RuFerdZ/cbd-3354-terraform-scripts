gcloud projects add-iam-policy-binding myfirstapp-72240 \
    --member=serviceAccount:service-952988696368@gcp-sa-cloudbuild.iam.gserviceaccount.com \
    --role=roles/secretmanager.secretAccessor

gcloud projects add-iam-policy-binding myfirstapp-72240 \
  --member=serviceAccount:service-952988696368@gcp-sa-cloudbuild.iam.gserviceaccount.com \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding myfirstapp-72240 \
  --member=serviceAccount:service-952988696368@gcp-sa-cloudbuild.iam.gserviceaccount.com \
  --role="roles/source.reader"
