# issue-207477241

This repository contains the terraform code required to reproduce issue 207477241.

## prerequisites
To deploy the reproduction you need the following:

- a google project id with a default network
- a Google DNS managed zone, which is publicly accessible
- a user you want to grant access

To configure your deployment, create a file `.auto.tfvars` with the following content:

```hcl
# project and region to deploy to
project = "my-project"
region = "europe-west4"

## DNS managed zone accessible from the public internet
dns_managed_zone = "my-managed-zone"

## users you want to grant access via IAP
accessors = [
    "user:markvanholsteijn@binx.io",
]

# support email address for the IAP brand.
# if there is an IAP brand in your project, make this empty string: ""
# To check whether you already have a brand, type `gcloud alpha iap oauth-brands list`
iap_support_email = "markvanholsteijn@binx.io"
```

## deploying
To deploy httpbin via IAP proxy, type:

```sh
git clone git@github.com:mvanholsteijn/issue-207477241.git
cp .auto.tfvars issue-207477241
terraform init
terraform apply
```

The output will show the commands to call your httpbin via the IAP:

```
httpbin_command = <<EOT
ID_TOKEN=$(
   gcloud auth print-identity-token \
   --audiences  123123123123-6qd767qse6d2hvo276jm4adpruguf5ut.apps.googleusercontent.com \
   --include-email \
   --impersonate-service-account httpbin-accessor@my-project.iam.gserviceaccount.com
)
curl --header "Authorization: Bearer $ID_TOKEN"  https://httpbin.example.com/anything
curl --header "Proxy-Authorization: Bearer $ID_TOKEN"  https://httpbin.example.com/anything

curl --user username:password --header "Proxy-Authorization: Bearer $ID_TOKEN"  https://httpbin.example.com/anything

# command with issue-207477241
curl --header "Authorization: Bearer $(gcloud auth print-identity-token)" \
     --header "Proxy-Authorization: Bearer $ID_TOKEN"  https://httpbin.example.com/anything

EOT

