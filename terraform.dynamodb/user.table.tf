resource "aws_dynamodb_table" "user_table" {
  name           = "FastAPIData"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  tags = {
    Name = "fastapi-dynamodb-table"
  }
}