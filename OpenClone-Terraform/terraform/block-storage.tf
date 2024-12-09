resource "kubernetes_persistent_volume" "openclone_fs_pv" {
  metadata {
    name = "openclone-fs-pv"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }

    access_modes = ["ReadWriteOnce"]

    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      host_path {
        path = "/Kind_PV"
        type = "DirectoryOrCreate" 
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "openclone_fs_pvc" {
  metadata {
    name = "openclone-fs-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}


# because this takes so long i would prefer to do it manually....
######resource "null_resource" "init_fs" {
######  provisioner "local-exec" {
######    command = "/scripts/openclone-fs.sh --push_openclone_fs"
######  }
######}

################################################################################
######## FTP ###################################################################
################################################################################

resource "kubernetes_deployment" "openclone_sftp" {
  depends_on = [ kubernetes_persistent_volume_claim.openclone_fs_pvc ]

  metadata {
    name = "openclone-sftp-deployment"
  }

  spec {
    replicas = 1
    selector { match_labels = { pod_id = "openclone-sftp-pod" } }
    template {
      metadata { labels = { pod_id = "openclone-sftp-pod" } }
      spec {
        
        # Init container to set ownership
        init_container {
          name  = "init-permissions"
          image = "busybox"
          command = ["sh", "-c", "chown -R 1001:1001 /home/openclone-ftp/OpenCloneFS"]

          volume_mount {
            name       = "openclone-fs"
            mount_path = "/home/openclone-ftp/OpenCloneFS"
          }
        }

        container {
          name  = "openclone-sftp"
          image = "atmoz/sftp"

          args = ["openclone-ftp:abc123:1001"]

          port {
            container_port = 22
          }

          volume_mount {
            name       = "openclone-fs"
            mount_path = "/home/openclone-ftp/OpenCloneFS"
          }
        }

        volume {
          name = "openclone-fs"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.openclone_fs_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "openclone_sftp_nodeport" {
  metadata {
    name = "openclone-sftp-nodeport"
  }
  spec {
    selector = {
      app = "openclone-sftp-pod"
    }
    port {
      protocol    = "TCP"
      port        = 22
      target_port = 22
      node_port   = 30222 # Optional: Specify a NodePort range (30000-32767)
    }
    type = "NodePort"
  }
}