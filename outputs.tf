output "load_balancer_ip" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.https.ip_address
}

output "load_balancer_ipv6" {
  description = "IPv6 address of the load balancer (if enabled)"
  value       = null
}

output "ssl_certificate_name" {
  description = "Name of the SSL certificate"
  value       = google_compute_managed_ssl_certificate.default.name
}

output "url_map_name" {
  description = "Name of the URL map"
  value       = google_compute_url_map.default.name
}

