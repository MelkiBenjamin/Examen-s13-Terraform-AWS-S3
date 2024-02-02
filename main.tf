resource "aws_s3_bucket" "monbucketbenjamin" {
  bucket = var.s3nom
}

resource "aws_s3_object" "index" {
  depends_on = [
    aws_s3_bucket_acl.aclpermission
  ]
  bucket = var.s3nom
  key    = "index.html"
  source = "./index.html"
  acl = "public-read"
  content_type = "text/html"
}

resource "aws_s3_bucket_website_configuration" "monsitebenjamin" {
  bucket = var.s3nom

  index_document {
    suffix = "index.html"
  }
}

output "url" {
  value = aws_s3_bucket_website_configuration.monsitebenjamin.website_endpoint
}

resource "aws_s3_bucket_public_access_block" "sitepublic" {
  bucket = var.s3nom

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "control" {
  bucket = var.s3nom
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "aclpermission" {
  depends_on = [
    aws_s3_bucket_ownership_controls.control,
    aws_s3_bucket_public_access_block.sitepublic,
  ]

  bucket = var.s3nom
  acl    = "public-read"
}

//data "aws_route53_zone" "zone_dns" {
//  name         = "devops.oclock.school."
//}

resource "aws_route53_record" "dns" {
  zone_id = "Z0344813387X7MTU9QASM"
  name    = "www.melkibenjamin-test"
  type    = "CNAME"
  ttl     = 300
  records = [aws_s3_bucket_website_configuration.monsitebenjamin.website_endpoint]
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "controle-acces-cloudfrontorigine"
  description                       = "cela va faire un controle d'acces"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution-b" {
  origin {
    domain_name              = aws_s3_bucket.monbucketbenjamin.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "id-original"
  }

  enabled             = true
//  is_ipv6_enabled     = true
  comment             = "commentaire pour cloudfront a tester"
  default_root_object = "index.html"

//  logging_config {
//    include_cookies = true
//    bucket          = "www.melkibenjamin-test.devops.oclock.school.s3.amazonaws.com"
//    prefix          = "myprefixe"
//  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "id-original"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 1800
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "production-benjamin"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
//    minimum_protocol_version = SSLv3
//    acm_certificate_arn = ...
//    ssl_support_method = static-ip

  }
}
