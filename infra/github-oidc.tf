data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

   
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:jaybrain2015/cloudflow:*"]
    }
  }
}

resource "aws_iam_role" "github_ci" {
  name               = "cloudflow-github-ci"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

data "aws_iam_policy_document" "ecr_push" {
  # get the temporary ECR login token
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [
      aws_ecr_repository.snipeit.arn,
      aws_ecr_repository.guestbook.arn,
    ]
  }
}

resource "aws_iam_role_policy" "ci_ecr" {
  name   = "ecr-push"
  role   = aws_iam_role.github_ci.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
