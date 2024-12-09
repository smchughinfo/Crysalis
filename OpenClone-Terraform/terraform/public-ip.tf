################################################################################
######## DOMAIN ################################################################
################################################################################

resource "vultr_dns_domain" "openclone_ai" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = "openclone.ai" # Register the whole domain here
}

################################################################################
######## LOAD BALANCERS ########################################################
################################################################################

resource "kubernetes_service" "openclone_dev_lb" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  depends_on = [kubernetes_deployment.openclone-website]
  
  metadata {
    name = "openclone-dev-lb"
  }

  spec {
    selector = {
      pod_id = "openclone-website-pod"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  timeouts {
    create = "30m"
  }
}

resource "kubernetes_service" "openclone_sftp_lb" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  depends_on = [kubernetes_deployment.openclone_sftp]

  metadata {
    name = "openclone-sftp-lb"
  }

  spec {
    selector = {
      pod_id = "openclone-sftp-pod"
    }
    port {
      name        = "sftp"
      port        = 22
      target_port = 22
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  timeouts {
    create = "30m"
  }
}

resource "kubernetes_service" "openclone_database_lb" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  depends_on = [kubernetes_deployment.openclone-database]

  metadata {
    name = "openclone-database-lb"
  }

  spec {
    selector = {
      pod_id = "openclone-database-pod"
    }
    port {
      name        = "database"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  timeouts {
    create = "30m"
  }
}

################################################################################
######## PUBLIC IP ADDRESS RESOLUTION ##########################################
################################################################################

data "kubernetes_service" "openclone_dev_lb_external_ip" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  metadata {
    name = kubernetes_service.openclone_dev_lb[0].metadata[0].name
  }
}

data "kubernetes_service" "openclone_sftp_lb_external_ip" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  metadata {
    name = kubernetes_service.openclone_sftp_lb[0].metadata[0].name
  }
}

data "kubernetes_service" "openclone_database_lb_external_ip" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  metadata {
    name = kubernetes_service.openclone_database_lb[0].metadata[0].name
  }
}

################################################################################
######## DOMAIN BINDING ########################################################
################################################################################

resource "vultr_dns_record" "openclone_ai_a_record" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = vultr_dns_domain.openclone_ai[0].domain
  name   = "dev"
  type   = "A"
  data   = data.kubernetes_service.openclone_dev_lb_external_ip[0].status[0].load_balancer[0].ingress[0].ip

  depends_on = [kubernetes_service.openclone_dev_lb]
}

resource "vultr_dns_record" "openclone_ai_sftp_record" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = vultr_dns_domain.openclone_ai[0].domain
  name   = "dev.sftp"
  type   = "A"
  data   = data.kubernetes_service.openclone_sftp_lb_external_ip[0].status[0].load_balancer[0].ingress[0].ip

  depends_on = [kubernetes_service.openclone_sftp_lb]
}

resource "vultr_dns_record" "openclone_ai_database_record" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = vultr_dns_domain.openclone_ai[0].domain
  name   = "dev.database"
  type   = "A"
  data   = data.kubernetes_service.openclone_database_lb_external_ip[0].status[0].load_balancer[0].ingress[0].ip

  depends_on = [kubernetes_service.openclone_database_lb]
}

################################################################################
######## EMAIL #################################################################
################################################################################

resource "vultr_dns_record" "openclone_mx_1" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = vultr_dns_domain.openclone_ai[0].domain
  name   = "@"
  type   = "MX"
  data   = "mx.zoho.com"
  priority = 10
}

resource "vultr_dns_record" "openclone_mx_2" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = vultr_dns_domain.openclone_ai[0].domain
  name   = "@"
  type   = "MX"
  data   = "mx2.zoho.com"
  priority = 20
}

resource "vultr_dns_record" "openclone_mx_3" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = vultr_dns_domain.openclone_ai[0].domain
  name   = "@"
  type   = "MX"
  data   = "mx3.zoho.com"
  priority = 50
}

resource "vultr_dns_record" "openclone_spf" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = vultr_dns_domain.openclone_ai[0].domain
  name   = "@"
  type   = "TXT"
  data   = "v=spf1 include:zohomail.com ~all"
}

resource "vultr_dns_record" "openclone_dkim" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = vultr_dns_domain.openclone_ai[0].domain
  name   = "zoho._domainkey"
  type   = "TXT"
  data   = var.openclone_email_dkim
}

resource "vultr_dns_record" "openclone_dmarc" {
  count = (var.environment == "vultr-dev" || var.environment == "vultr-prod") ? 1 : 0
  domain = vultr_dns_domain.openclone_ai[0].domain
  name   = "_dmarc"
  type   = "TXT"
  data   = "v=DMARC1; p=quarantine; rua=mailto:admin@openclone.com; ruf=mailto:admin@openclone.com; sp=quarantine; adkim=r; aspf=r; pct=100"
}
