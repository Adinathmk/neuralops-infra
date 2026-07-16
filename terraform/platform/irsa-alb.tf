# ============================================================
# IRSA — AWS Load Balancer Controller role.
# Trusts the ServiceAccount "aws-load-balancer-controller" in
# namespace "kube-system" (standard Helm chart default).
# Permission policy sourced verbatim from AWS's official release:
# https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/v2.9.0/docs/install/iam_policy.json
# ============================================================

data "aws_iam_policy_document" "alb_assume_role" {
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
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.project_name}-alb-controller-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json

  tags = {
    Name = "${var.project_name}-alb-controller-irsa-role"
  }
}

resource "aws_iam_policy" "alb_controller" {
  name   = "${var.project_name}-alb-controller-policy"
  policy = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
