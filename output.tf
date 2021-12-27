resource "google_secret_manager_secret" "httpbin" {
  for_each  = local.exports
  secret_id = format("httpbin-%s", each.key)

  replication {
    automatic = true
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "httpbin" {
  for_each    = local.exports
  secret      = google_secret_manager_secret.httpbin[each.key].id
  secret_data = each.value
}

data "google_iam_policy" "httpbin" {
  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = local.iap_accessors
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  for_each    = local.exports
  project     = google_secret_manager_secret.httpbin[each.key].project
  secret_id   = google_secret_manager_secret.httpbin[each.key].secret_id
  policy_data = data.google_iam_policy.httpbin.policy_data
}

locals {
  exports = {
    target-url      = format("https://%s", trimsuffix(google_dns_record_set.httpbin.name, "."))
    audience        = google_iap_client.httpbin.client_id
    service-account = google_service_account.httpbin_accessor.email
  }
}

output "httpbin_command" {
  value = <<EOF
ID_TOKEN=$(
   gcloud auth print-identity-token \
   --audiences  ${local.exports.audience} \
   --include-email \
   --impersonate-service-account ${local.exports.service-account}
)
curl --header "Authorization: Bearer $ID_TOKEN"  ${local.exports.target-url}/anything
curl --header "Proxy-Authorization: Bearer $ID_TOKEN"  ${local.exports.target-url}/anything
curl --user username:password --header "Proxy-Authorization: Bearer $ID_TOKEN"  ${local.exports.target-url}/anything
curl --header "Authorization: Bearer $(gcloud auth print-identity-token) \
     --header "Proxy-Authorization: Bearer $ID_TOKEN"  ${local.exports.target-url}/anything
EOF
}

resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}
