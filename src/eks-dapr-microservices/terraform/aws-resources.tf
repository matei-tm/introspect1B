# SNS Topic for pub/sub
resource "aws_sns_topic" "orders" {
  name = var.sns_topic_name

  # No tags to avoid conflicts with Dapr's entity management
}

# SQS Queue for order service (managed by Dapr with disableEntityManagement)
# Queue name must match Dapr's expectation: just the app-id
resource "aws_sqs_queue" "orders_subscriber" {
  name                       = "order"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 1

  # No tags to avoid conflicts with Dapr
}

# SQS Queue Policy to allow SNS to send messages
resource "aws_sqs_queue_policy" "orders_subscriber" {
  queue_url = aws_sqs_queue.orders_subscriber.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.orders_subscriber.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.orders.arn
          }
        }
      }
    ]
  })
}

# SNS Subscription - Subscribe SQS to SNS
resource "aws_sns_topic_subscription" "orders_subscriber" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.orders_subscriber.arn
}

# DynamoDB Table for Dapr state store
resource "aws_dynamodb_table" "dapr_state" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "key"

  attribute {
    name = "key"
    type = "S"
  }

  tags = {
    Name = var.dynamodb_table_name
  }
}
