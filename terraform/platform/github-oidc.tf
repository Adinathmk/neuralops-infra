# ============================================================
# GitHub Actions OIDC — CI/CD roles (Phase C)
# Trusts GitHub's OIDC token issuer so Actions workflows can
# assume AWS roles without long-lived credentials.
# ============================================================

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]

  tags = {
    Name = "${var.project_name}-github-actions-oidc"
  }
}

# ------------------------------------------------------------
# Role 1: github-actions-ecr-push
# Used by Adinathmk/NeuralOps (django + fastapi) workflows to
# build and push images to the 4 real ECR repos, main branch only.
# ------------------------------------------------------------
data "aws_iam_policy_document" "github_ecr_push_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Adinathmk/NeuralOps:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_ecr_push" {
  name               = "github-actions-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.github_ecr_push_assume_role.json
  tags = {
    Name = "github-actions-ecr-push"
  }
}

data "aws_iam_policy_document" "github_ecr_push_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [
      aws_ecr_repository.main["neuralops-django"].arn,
      aws_ecr_repository.main["neuralops-django-worker"].arn,
      aws_ecr_repository.main["neuralops-django-kafka-consumer"].arn,
      aws_ecr_repository.main["neuralops-fastapi"].arn,
    ]
  }
}

resource "aws_iam_policy" "github_ecr_push" {
  name   = "github-actions-ecr-push-policy"
  policy = data.aws_iam_policy_document.github_ecr_push_policy.json
}

resource "aws_iam_role_policy_attachment" "github_ecr_push" {
  role       = aws_iam_role.github_actions_ecr_push.name
  policy_arn = aws_iam_policy.github_ecr_push.arn
}

# ------------------------------------------------------------
# Role 2: github-actions-infra-plan
# Used by Adinathmk/neuralops-infra workflow for `terraform plan`
# only — read-only, no apply. Main branch only.
# ------------------------------------------------------------
data "aws_iam_policy_document" "github_infra_plan_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Adinathmk/neuralops-infra:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_infra_plan" {
  name               = "github-actions-infra-plan"
  assume_role_policy = data.aws_iam_policy_document.github_infra_plan_assume_role.json
  tags = {
    Name = "github-actions-infra-plan"
  }
}

# NOTE: terraform plan needs broad read access to refresh state and
# compute a diff. ReadOnlyAccess is used here deliberately instead of
# hand-scoping resource types (fragile, breaks silently as repo grows).
# This role can NEVER apply -- no write/delete permissions anywhere.
resource "aws_iam_role_policy_attachment" "github_infra_plan_readonly" {
  role       = aws_iam_role.github_actions_infra_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
