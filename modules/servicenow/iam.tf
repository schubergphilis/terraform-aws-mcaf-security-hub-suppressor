resource "aws_iam_user" "sync-user" {
  name = "SCSyncUser"
}

module "sync-user" {
  name          = "SCSyncUser"
  source        = "github.com/schubergphilis/terraform-aws-mcaf-user?ref=v0.1.13"
  create_policy = true
  policy        = aws_iam_policy.SQSPolicy.policy
  policy_arns   = data.aws_iam_policy.ManagedPolicies
  tags          = var.tags
}

resource "aws_iam_user" "end-user" {
  name = "SCEndUser"
}

//Create custom policies
resource "aws_iam_policy" "SQSPolicy" {
  name        = "SQSPolicy"
  description = "SQSPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:DeleteMessageBatch"
        ]
        Effect   = "Allow"
        Resource = "${aws_sqs_queue.servicenow-queue.arn}"
        Sid      = "SQSPolicy"
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "${var.kms_key_arn}"
        Sid      = "SQSKMSPolicy"
      }
    ]
  })
}

resource "aws_iam_policy" "SecurityHubPolicy" {
  name        = "SecurityHubPolicy"
  description = "SecurityHubPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "securityhub:BatchUpdateFindings"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "SecurityHubPolicy"
      }
    ]
  })
}

resource "aws_iam_policy" "SSMPolicy" {
  name        = "SSMPolicy"
  description = "SSMPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:DescribeAutomationExecutions",
          "ssm:DescribeDocument"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "SSMPolicy"
      }
    ]
  })
}


//Link custom policies
resource "aws_iam_user_policy_attachment" "SQSPolicy" {
  user       = aws_iam_user.sync-user.name
  policy_arn = aws_iam_policy.SQSPolicy.arn
}

resource "aws_iam_user_policy_attachment" "SecurityHubPolicy" {
  user       = aws_iam_user.sync-user.name
  policy_arn = aws_iam_policy.SecurityHubPolicy.arn
}

resource "aws_iam_user_policy_attachment" "SSMPolicy" {
  user       = aws_iam_user.end-user.name
  policy_arn = aws_iam_policy.SSMPolicy.arn
}

//Link managed policies
resource "aws_iam_user_policy_attachment" "managed-policies" {
  for_each   = data.aws_iam_policy.ManagedPolicies
  user       = aws_iam_user.sync-user.name
  policy_arn = each.value.arn
}

resource "aws_iam_user_policy_attachment" "managed-policies-end-user" {
  for_each   = data.aws_iam_policy.ManagedPolicies
  user       = aws_iam_user.end-user.name
  policy_arn = each.value.arn
}
