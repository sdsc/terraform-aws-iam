data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${var.trusted_role_arns}"]
    }
  }
}

data "aws_iam_policy_document" "assume_role_with_mfa" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${var.trusted_role_arns}"]
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "aws:MultiFactorAuthAge"
      values   = ["${var.mfa_age}"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = "${var.create_role ? 1 : 0}"

  name                 = "${var.role_name}"
  path                 = "${var.role_path}"
  description          = "${var.role_description}"
  max_session_duration = "${var.max_session_duration}"

  permissions_boundary = "${var.role_permissions_boundary_arn}"

  assume_role_policy = "${var.role_requires_mfa ? data.aws_iam_policy_document.assume_role_with_mfa.json : data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "custom" {
  count = "${var.create_role && length(var.custom_role_policy_arns) > 0 ? length(var.custom_role_policy_arns) : 0}"

  role       = "${aws_iam_role.this.name}"
  policy_arn = "${element(var.custom_role_policy_arns, count.index)}"
}

resource "aws_iam_role_policy_attachment" "admin" {
  count = "${var.create_role && var.attach_admin_policy ? 1 : 0}"

  role       = "${aws_iam_role.this.name}"
  policy_arn = "${var.admin_role_policy_arn}"
}

resource "aws_iam_role_policy_attachment" "poweruser" {
  count = "${var.create_role && var.attach_poweruser_policy ? 1 : 0}"

  role       = "${aws_iam_role.this.name}"
  policy_arn = "${var.poweruser_role_policy_arn}"
}

resource "aws_iam_role_policy_attachment" "readonly" {
  count = "${var.create_role && var.attach_readonly_policy ? 1 : 0}"

  role       = "${aws_iam_role.this.name}"
  policy_arn = "${var.readonly_role_policy_arn}"
}
