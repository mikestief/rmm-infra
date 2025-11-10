# Network Endpoint Group (NEG) for Cloud Run service
resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "${var.cloud_run_service_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.cloud_run_service_location
  cloud_run {
    service = var.cloud_run_service_name
  }
}

# Backend service pointing to Cloud Run NEG
resource "google_compute_backend_service" "default" {
  name                  = "${var.cloud_run_service_name}-backend"
  description           = "Backend service for ${var.cloud_run_service_name}"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  enable_cdn            = false
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  health_checks = [google_compute_health_check.default.id]
}

# Health check for backend service
resource "google_compute_health_check" "default" {
  name               = "${var.cloud_run_service_name}-health-check"
  description        = "Health check for ${var.cloud_run_service_name}"
  timeout_sec        = 5
  check_interval_sec = 10
  healthy_threshold  = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 8080
    request_path = "/health"
  }
}

# Google-managed SSL certificate
resource "google_compute_managed_ssl_certificate" "default" {
  name = "${var.domain}-ssl-cert"

  managed {
    domains = [var.domain]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# URL map routing all traffic to backend service
resource "google_compute_url_map" "default" {
  name            = "${var.cloud_run_service_name}-url-map"
  description     = "URL map for ${var.cloud_run_service_name}"
  default_service = google_compute_backend_service.default.id
}

# Target HTTPS proxy
resource "google_compute_target_https_proxy" "default" {
  name             = "${var.cloud_run_service_name}-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

# Target HTTP proxy (redirects to HTTPS)
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.cloud_run_service_name}-http-proxy"
  url_map = google_compute_url_map.default.id
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.cloud_run_service_name}-https-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  ip_version            = "IPV4"
}

# Global forwarding rule for HTTP (redirects to HTTPS)
resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.cloud_run_service_name}-http-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_version            = "IPV4"
}

