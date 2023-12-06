# cf-vector-buildpack

Buildpack to deploy Vector configuration as a CloudFoundry application.

Will bind to any provisioned, bound service. To bind:
1) Ensure the service is bound with a binding name. 
2) List the binding name of the service in the environment variable PROVISIONED_SERVICE_BINDING_NAMES. This is a comma 
separated value, to support multiple bound services.
3) In your toml or yml configurations, insert a reference to the value that you want to substitute. The reference
will be surrounded by `${}`. The first part of the reference will be the binding name, followed by the json path to the 
value. For example, to get the bucket name of an S3 bucket bound with the binding name "my_s3_bucket" use
`${my_s3_bucket.credentials.bucket_name}`

# License

MIT License