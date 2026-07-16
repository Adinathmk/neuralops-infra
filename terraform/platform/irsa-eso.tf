# ============================================================
# IRSA — External Secrets Operator role.
# Trusts the ServiceAccount "external-secrets" in namespace
# "external-secrets" (standard ESO Helm chart default).
# ============================================================

data "aws_iam_policy_document" "eso_assume_role" {
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
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eso" {
  name               = "${var.project_name}-eso-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.eso_assume_role.json

  tags = {
    Name = "${var.project_name}-eso-irsa-role"
  }
}

data "aws_iam_policy_document" "eso_secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/*"]
  }
}

resource "aws_iam_policy" "eso_secrets_access" {
  name   = "${var.project_name}-eso-secrets-access"
  policy = data.aws_iam_policy_document.eso_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "eso_secrets_access" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso_secrets_access.arn
}
