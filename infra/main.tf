provider "aws" { region = "us-east-1" }

# 1. THE BUCKET - Versioned, encrypted, bulletproof
resource "aws_s3_bucket" "site" {
  bucket = "4kjax.com-prod-site" # Use unique name, not 4kjax.com
  lifecycle { prevent_destroy = false } # Set to true after first apply
}
resource "aws_s3_bucket_versioning" "site" { bucket = aws_s3_bucket.site.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

# 2. NO PUBLIC ACCESS - Block everything
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# 3. CLOUDFRONT OAC - The secure way (OAI is deprecated)
resource "aws_cloudfront_origin_access_control" "site" {
  name = "4kjax-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled = true
  aliases = ["4kjax.com", "www.4kjax.com"]

  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
  }

  # YOUR WILDCARD CERT - Must be in us-east-1
  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:YOUR_ACCOUNT:certificate/YOUR_CERT_ID"
    ssl_support_method = "sni-only"
  }
}

# 4. ALLOW CLOUDFRONT TO READ BUCKET
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "AllowCloudFront"
      Effect = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action = "s3:GetObject"
      Resource = "${aws_s3_bucket.site.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.site.arn }
      }
    }]
  })
}

output "bucket_name" { value = aws_s3_bucket.site.id }
output "distribution_id" { value = aws_cloudfront_distribution.site.id }