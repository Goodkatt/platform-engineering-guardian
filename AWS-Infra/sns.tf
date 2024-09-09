resource "aws_sns_topic" "container_insights" {
  name = "container_insights_topic"
}
output "topic_arn" {
    value = aws_sns_topic.container_insights.arn
}
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.container_insights.arn
  protocol  = "email"
  endpoint = "gorkem.altunay@gmail.com"
}

resource "aws_cloudwatch_metric_alarm" "foobar" {
  alarm_name                = "get-requests-greater-than"

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "rest_client_requests_total"
  namespace                 = "ContainerInsights"
  period                    = 30
  statistic                 = "Average"
  threshold                 = 10
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []


  dimensions = {
    ClusterName = "guardian-cluster",
    code        = 200,
    method      = "GET"
  }
  alarm_actions = [ aws_sns_topic.container_insights.arn ]
}