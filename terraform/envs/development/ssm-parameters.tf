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
                    ],
                    "metrics_collection_interval": 60
                }
            ]
        }
    }
}
EOS  
}

resource "aws_ssm_parameter" "cwa_config_linux" {
  name  = "AmazonCloudWatch-config-linux"
  type  = "String"
  value = <<EOS
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "metrics": {
        "append_dimensions": {
            "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
            "InstanceId": "$${aws:InstanceId}",
            "InstanceType": "$${aws:InstanceType}"
        },
        "aggregation_dimensions": [
            [
                "AutoScalingGroupName"
            ]
        ],
        "metrics_collected": {
            "collectd": {
                "metrics_aggregation_interval": 60
            },
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ],
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent",
                    "inodes_free"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time",
                    "write_bytes",
                    "read_bytes",
                    "writes",
                    "reads"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "statsd": {
                "metrics_aggregation_interval": 60,
                "metrics_collection_interval": 10,
                "service_address": ":8125"
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOS  
}
