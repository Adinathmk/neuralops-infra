# ============================================================
# IRSA — FastAPI S3 access role.
# Trusts the ServiceAccount "fastapi" in namespace "app", shared
# by both the fastapi deployment and celery-worker-fastapi
# (code indexing writes to S3 under the code/ prefix).
# ============================================================
data "aws_iam_policy_document" "fastapi_s3_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:app:fastapi"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fastapi_s3" {
  name               = "${var.project_name}-fastapi-s3-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.fastapi_s3_assume_role.json
  tags = {
    Name = "${var.project_name}-fastapi-s3-irsa-role"
  }
}

data "aws_iam_policy_document" "fastapi_s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:HeadBucket",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.artifacts.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.artifacts.arn}/*"]
  }
}

resource "aws_iam_policy" "fastapi_s3_access" {
  name   = "${var.project_name}-fastapi-s3-access"
  policy = data.aws_iam_policy_document.fastapi_s3_access.json
}

resource "aws_iam_role_policy_attachment" "fastapi_s3_access" {
  role       = aws_iam_role.fastapi_s3.name
  policy_arn = aws_iam_policy.fastapi_s3_access.arn
}

output "fastapi_s3_role_arn" {
  value = aws_iam_role.fastapi_s3.arn
}
