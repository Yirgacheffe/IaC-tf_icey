# ------------------------------------------------------------
# Create AWS Instance for DB instance
# ------------------------------------------------------------
resource "aws_db_subnet_group" "db_subnet_grp" {
    name       = "db-subnet-grp"
    subnet_ids = [for value in aws_subnet.database: value.id]
    tags       = local.tags
}

resource "aws_db_instance" "db_inst_mysql" {

    identifier      = "mysql-icey-1"
    engine          = "mysql"
    engine_version  = "8.0.23"
    instance_class  = "db.t3.small"

    name            = "${var.db_name}"
    username        = "${var.db_username}"
    password        = "${var.db_password}"
    port            = 3306
    storage_type    = "gp2"

    # set multi_za to true enabled standby mode
    # multi_az        = true

    db_subnet_group_name    = "${aws_db_subnet_group.db_subnet_grp.name}"

    maintenance_window      = "Mon:01:00-Mon:03:00"
    allocated_storage       = 10    # Gigabytes
    max_allocated_storage   = 50
    
    # StorageEncrypted set to 'true', KMS key identifier for encrypted
    storage_encrypted       = true
 #  kms_key_id              = aws_kms_key.rds.arn
    backup_retention_period = 7

    skip_final_snapshot     = true
    vpc_security_group_ids  = ["${aws_security_group.db_inst_sg.id}"]

    iam_database_authentication_enabled = true

    # monitoring_interval   = 30
    tags                    = local.tags
}

# ------------------------------------------------------------
# Create AWS Instance for Elasticache
# ------------------------------------------------------------

resource "aws_elasticache_subnet_group" "cache_subnet_grp" {
    name       = "cache-subnet-grp"
    subnet_ids = [for value in aws_subnet.database: value.id]
    tags       = local.tags
}

resource "aws_elasticache_cluster" "cache_cluster" {
    cluster_id           = "redis-cluster"
    engine               = "redis"

    node_type            = "cache.t2.micro"
    engine_version       = "6.x"
    num_cache_nodes      = 1
    port                 = 6379
    parameter_group_name = "default.redis6.x"

    subnet_group_name    = "${aws_elasticache_subnet_group.cache_subnet_grp.name}"
    security_group_ids   = ["${aws_security_group.cache_inst_sg.id}"]

    tags = local.tags
}

# ------------------------------------------------------------