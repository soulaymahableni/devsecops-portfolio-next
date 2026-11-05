import pulumi
import pulumi_aws as aws

# Provider AWS configuré pour parler à Floci (AWS émulé en local)
floci = aws.Provider(
    "floci",
    region="us-east-1",
    access_key="test",
    secret_key="test",
    skip_credentials_validation=True,
    skip_metadata_api_check=True,
    skip_requesting_account_id=True,
    s3_use_path_style=True,
    endpoints=[aws.ProviderEndpointArgs(s3="http://localhost:4566")],
)

bucket = aws.s3.Bucket(
    "assets",
    bucket="portfolio-pulumi-assets",
    opts=pulumi.ResourceOptions(provider=floci),
)

pulumi.export("bucket_name", bucket.bucket)
