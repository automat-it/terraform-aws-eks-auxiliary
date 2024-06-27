### EKS
# Common
eks_ami_type                              = "AL2_x86_64"
eks_instance_types                        = ["t3.medium"]
eks_attach_cluster_primary_security_group = false
eks_cluster_name                          = "TEST"
# System
eks_system_min_size       = 2
eks_system_max_size       = 2
eks_system_desired_size   = 2
eks_system_instance_types = ["t3.medium"]
#eks_system_capacity_type = "SPOT"
# Worker
eks_worker_min_size       = 2
eks_worker_max_size       = 2
eks_worker_desired_size   = 2
eks_worker_instance_types = ["t3.medium"]
eks_worker_capacity_type  = "SPOT"

