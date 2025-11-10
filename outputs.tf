output "load_balancer_ip" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.https.ip_address
}

output "load_balancer_ipv6" {
  description = "IPv6 address of the load balancer (if enabled)"
  value       = try(google_compute_global_forwarding_rule.https.ipv6_address, null)
}

output "ssl_certificate_name" {
  description = "Name of the SSL certificate"
  value       = google_compute_managed_ssl_certificate.default.name
}

output "ssl_certificate_status" {
  description = "Status of the SSL certificate"
  value       = google_compute_managed_ssl_certificate.default.managed[0].status
}

output "url_map_name" {
  description = "Name of the URL map"
  value       = google_compute_url_map.default.name
}

