# ============================================================
# IRSA — Django S3 access role.
# Trusts the ServiceAccount "django" in namespace "app".
# Grants access to the artifacts bucket only (profile pictures,
# uploads, etc.) — scoped to this bucket, not account-wide S3.
# ============================================================
data "aws_iam_policy_document" "django_s3_assume_role" {
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
      values   = ["system:serviceaccount:app:django"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "django_s3" {
  name               = "${var.project_name}-django-s3-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.django_s3_assume_role.json
  tags = {
    Name = "${var.project_name}-django-s3-irsa-role"
  }
}

data "aws_iam_policy_document" "django_s3_access" {
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

resource "aws_iam_policy" "django_s3_access" {
  name   = "${var.project_name}-django-s3-access"
  policy = data.aws_iam_policy_document.django_s3_access.json
}

resource "aws_iam_role_policy_attachment" "django_s3_access" {
  role       = aws_iam_role.django_s3.name
  policy_arn = aws_iam_policy.django_s3_access.arn
}

output "django_s3_role_arn" {
  value = aws_iam_role.django_s3.arn
}
