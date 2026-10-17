output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.server.public_ip
}

output "app_url" {
  description = "URL for the app on port 8080"
  value       = "http://${aws_instance.server.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH into the instance"
  value       = "ssh -i <your-private-key> ubuntu@${aws_instance.server.public_ip}"
}
