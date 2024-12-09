resource "kubernetes_deployment" "utility_container" {
  metadata {
    name = "utility-container"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "utility-container"
      }
    }
    template {
      metadata {
        labels = {
          app = "utility-container"
        }
      }
      spec {
        container {
          name  = "ubuntu"
          image = "ubuntu:latest"
          command = ["/bin/bash", "-c", "sleep infinity"]  # Keeps the container running
        }
      }
    }
  }
}
