resource "aws_ssm_parameter" "cwa_config_web" {
  name  = "AmazonCloudWatch-config-web"
  type  = "String"
  value = <<EOS
{
    "metrics": {
        "metrics_collected": {
            "procstat": [
                {
                    "exe": "httpd",
                    "measurement": [
                        "pid_count"
                    ]
                }
            ]
        }
    }
}
EOS  
}

resource "aws_ssm_parameter" "cwa_config_linux" {
  name  = "AmazonCloudWatch-config-common"
  type  = "String"
  value = <<EOS
{
    "agent": {
        "metrics_collection_interval": 300,
        "run_as_user": "root"
    },
    "metrics": {
        "append_dimensions": {
            "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
            "InstanceId": "$${aws:InstanceId}",
            "InstanceType": "$${aws:InstanceType}"
        },
        "aggregation_dimensions": [
            ["AutoScalingGroupName"],
            ["AutoScalingGroupName","InstanceId"],
            ["InstanceId"]
        ],
        "metrics_collected": {
            "collectd": {
                "collectd_security_level":"encrypt",
                "collectd_auth_file":"/etc/collectd.d/auth_file",
                "metrics_aggregation_interval": 60
            },
            "cpu": {
                "measurement": [
                    "cpu_usage_user",
                    "cpu_usage_nice",
                    "cpu_usage_system",
                    "cpu_usage_iowait",
                    "cpu_usage_irq",
                    "cpu_usage_softirq",
                    "cpu_usage_steal"
                ],
                "resources": [
                    "*"
                ]
            },
            "disk": {
                "measurement": [
                    "disk_free",
                    "disk_inodes_free",
                    "disk_inodes_total",
                    "disk_inodes_used",
                    "disk_total",
                    "disk_used",
                    "disk_used_percent"
                ],
                "resources": [
                    "/",
                    "/run"
                ]
            },
            "diskio": {
                "measurement": [
                    "diskio_iops_in_progress",
                    "diskio_io_time",
                    "diskio_reads",
                    "diskio_read_bytes",
                    "diskio_read_time",
                    "diskio_writes",
                    "diskio_write_bytes",
                    "diskio_write_time"
                ],
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_active",
                    "mem_available",
                    "mem_available_percent",
                    "mem_buffered",
                    "mem_cached",
                    "mem_free",
                    "mem_inactive",
                    "mem_total",
                    "mem_used",
                    "mem_used_percent"
                ],
                "resources": [
                    "*"
                ]
            },
            "net": {
                "measurement": [
                    "net_bytes_recv",
                    "net_bytes_sent"
                ]
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/kern.log",
                        "log_group_name": "kern_log",
                        "log_stream_name": "{instanceId}"
                    }
                ]
            }
        }
    }
}
EOS  
}
