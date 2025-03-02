---
layout: post
title: "Weekend Project: Dynamic DNS with AWS Lambda & Jenkins"
category: blog
tags: dns aws lambda minecraft dynamic-dns dynamic
---

A few months back, in December, I purchased a Unifi Ubiquity Dream Machine (UDM). This was a significant upgrade from my
previous router, and enabled me to segment my home network into multiple VLANs. I typically do not like to expose services 
from my home network, but with a completely segmented network, I felt comfortable exposing a few services. The first service 
I wanted to expose publicly was a vanilla Java Minecraft server. I already had a domain name (johnsosoka.com) and wanted to
set up dynamic DNS for minecraft.johnsosoka.com.

## The Game Plan

My personal website is hosted on AWS, and I already have a bit of infrastructure in place, including API Gateway and a
few Lambda functions. Furthermore, I have a server running Jenkins in my home network. Here's a diagram for the project 
planned for today:

![dynamic-dns-diagram](https://media.johnsosoka.com/blog/2025-03-02/jscom-dyn-dns.png)

_The Diagram above demonstrates the flow of the dynamic DNS service, the home network diagram is simplified_

The plan is to create two Lambda functions, one to check/return the IP address of the caller, and another to update the
DNS record in Route53. The Jenkins server will have a job that runs periodically to fetch the IP address of the home network,
and if it has changed, it will call the update DNS Lambda function.

## The Lambda Functions

First, we'll create the lambda function to return the IP address of the caller. This function will be a simple Python
script that returns the IP address of the caller. Here's the code:

**Check IP Lambda Function:**

```python
import json


def lambda_handler(event, context):
    """
    AWS Lambda function to return the requesting client's IP address.

    This function serves as a lightweight service similar to whatismyip.com,
    retrieving the client's IP from the API Gateway request context. It is
    designed for invocation via API Gateway with Lambda Proxy Integration.

    Args:
        event (dict): Contains the request details including the client's IP.
        context (LambdaContext): Provides runtime information.

    Returns:
        dict: An HTTP response with a JSON body containing the client's IP address.
    """
    ip_address = event.get("requestContext", {}).get("http", {}).get("sourceIp", "IP not found")

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"ip": ip_address})
    }
```

The above lambda function is incredibly simple, and it will be invoked via API Gateway. I'll be skipping over the Terraform
code, but it's available in the GitHub repository for this blog post.

Next up is to create the lambda function for updating the DNS record in Route53. Since this is performing a write operation,
I'll be securing the function with an API key. Here's the code for the update DNS Lambda function:

**Update DNS Lambda Function:**

```python
import os
import json
import boto3

def lambda_handler(event, context):
    """
    Update a DNS A record in Route53.

    This function supports dynamic DNS updates (for example, updating a Minecraft server's external IP).
    It expects a JSON payload with:
      - domain: the DNS record name (e.g. "minecraft.example.com.")
      - ip: the new A record value (e.g. "1.2.3.4")

    The authorization token is expected in the request headers (key "x-auth-token"). The token is verified against
    the AUTH_TOKEN environment variable.

    Returns:
        dict: HTTP response containing a status message.
    """
    expected_token = os.environ.get("AUTH_TOKEN")
    hosted_zone_id = os.environ.get("HOSTED_ZONE_ID")

    # Retrieve auth token from headers
    headers = event.get("headers", {})
    auth_token = headers.get("x-auth-token")

    if auth_token != expected_token:
        return {
            "statusCode": 403,
            "body": json.dumps({"error": "Unauthorized"})
        }

    body = event.get("body")
    if body:
        try:
            data = json.loads(body)
        except Exception:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Invalid JSON payload"})
            }
    else:
        data = {}

    domain = data.get("domain")
    new_ip = data.get("ip")
    if not domain or not new_ip:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing 'domain' or 'ip' parameter"})
        }

    if not hosted_zone_id:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Hosted zone ID not configured"})
        }

    route53 = boto3.client("route53")
    try:
        response = route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                "Comment": "Auto-updated by update_dns_lambda",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": domain,
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{"Value": new_ip}]
                        }
                    }
                ]
            }
        )
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Failed to update DNS record",
                "message": str(e)
            }, default=str)
        }

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "DNS record updated",
            "change_info": response
        }, default=str)
    }
```

There is a bit more going on with the above Lambda function, but it should still be relatively straightforward. The function
will accept a JSON payload with the domain and IP address to update. The function will then update the DNS record in Route53.

I've secured this with a simple API key which is expected in the `x-auth-token` header and is verified against an environment
variable. In the future, I may revisit this and use a more secure method of authentication. I've also considered limiting the
DNS record that can be updated to a specific subdomain, but for now, I'm keeping it simple and allowing any record in the
hosted zone. In the future, there may be other DNS records for self-hosted services that I want to update dynamically.

## Jenkins Jobs

My Jenkins server is running in a Docker container on my home network. It already has a job for posting notifications to 
my family's Discord server--I won't be covering that job in this post, but it is referenced in the jobs we'll be building 
today.

We'll be creating two Jenkins jobs. One to check the current public IP address of the home network and another to update. 
Logically, we'll build the jobs "backwards" as the Update job is called last. We'll implement this first, so that we can
reference it when checking the current IP address & name record.

The job is parameterized to accept a `DNS_DOMAIN` and `DNS_IP` parameter, for updating the DNS record. A secret, `DNS_AUTH_TOKEN`,
has been configured in the Jenkins credentials manager. Here's the code for the Update DNS job:

**Update DNS Job:**

```groovy
pipeline {
    agent any

    parameters {
        string(name: 'DNS_DOMAIN', defaultValue: 'minecraft.johnsosoka.com', description: 'The DNS record to update')
        string(name: 'DNS_IP', defaultValue: 'AUTO', description: 'IP to set (AUTO uses current public IP)')
    }

    stages {
        stage('Install Dependencies') {
            steps {
                script {
                    sh '''
                        if ! command -v jq &> /dev/null; then
                            echo "🔧 Installing jq..."
                            apt-get update && apt-get install -y jq
                        fi
                    '''
                }
            }
        }

        stage('Update DNS') {
            steps {
                withCredentials([string(credentialsId: 'DNS_AUTH_TOKEN', variable: 'AUTH_TOKEN')]) {
                    script {
                        // Ensure AUTH_TOKEN is passed safely
                        env.AUTH_TOKEN = AUTH_TOKEN

                        def response = sh(script: '''
                            JSON_PAYLOAD=$(printf '{
                                "domain": "%s",
                                "ip": "%s"
                            }' "$DNS_DOMAIN" "$DNS_IP")

                            curl -s -X POST "https://api.johnsosoka.com/v1/dns/update" \
                            -H "Content-Type: application/json" \
                            -H "x-auth-token: $AUTH_TOKEN" \
                            -d "$JSON_PAYLOAD"
                        ''', returnStdout: true).trim()

                        def httpStatus = sh(script: "echo '${response}' | jq -r '.change_info.ResponseMetadata.HTTPStatusCode'", returnStdout: true).trim()
                        def changeStatus = sh(script: "echo '${response}' | jq -r '.change_info.ChangeInfo.Status'", returnStdout: true).trim()

                        if (httpStatus == "200" && (changeStatus == "PENDING" || changeStatus == "INSYNC")) {
                            echo "✅ DNS updated successfully! Status: ${changeStatus}"
                            currentBuild.description = "DNS updated: ${changeStatus}"
                            notifyDiscord("✅ DNS updated for ${DNS_DOMAIN} to ${DNS_IP}. Status: ${changeStatus}")
                        } else {
                            error "❌ DNS update failed: ${response}"
                        }
                    }
                }
            }
        }
    }
}

def notifyDiscord(message) {
    build job: 'notify-discord', parameters: [
            string(name: 'DISCORD_MESSAGE', value: message)
    ]
}
```

_Note the `notifyDiscord` function at the end of the script. This is a common job that is used to post messages to Discord._

Next up is to create the Check IP Job. This job will check the current public IP address of the home network and compare it
to the existing minecraft.johnsosoka.com DNS record. If the IP address has changed, the job will trigger the Update DNS job.

**Check IP Job:**

```groovy
pipeline {
    agent any

    environment {
        DNS_DOMAIN = 'minecraft.johnsosoka.com'
        PUBLIC_IP_API = 'https://api.johnsosoka.com/v1/ip/my'
    }

    stages {
        stage('Install Dependencies') {
            steps {
                script {
                    sh '''
                        if ! command -v jq &> /dev/null || ! command -v dig &> /dev/null; then
                            echo "🔧 Installing dependencies..."
                            apt-get update && apt-get install -y jq dnsutils
                        fi
                    '''
                }
            }
        }

        stage('Check Current DNS') {
            steps {
                script {
                    echo "🔹 Checking DNS record for ${DNS_DOMAIN}..."

                    // Get the current IP from DNS
                    def dnsIp = sh(script: "dig +short ${DNS_DOMAIN} | head -n 1", returnStdout: true).trim()

                    // Get the public IP from API
                    def publicIp = sh(script: "curl -s ${PUBLIC_IP_API} | jq -r '.ip'", returnStdout: true).trim()

                    // Output results
                    echo "🔹 Current DNS IP: ${dnsIp}"
                    echo "🔹 Public IP from API: ${publicIp}"

                    // Check if DNS is outdated
                    if (dnsIp == publicIp) {
                        echo "✅ The DNS record is up to date. No action needed."
                    } else {
                        echo "⚠️ DNS record is outdated. Updating to ${publicIp}..."

                        // Trigger the update-jscom-dns job
                        build job: 'update-jscom-dns', parameters: [
                            string(name: 'DNS_DOMAIN', value: DNS_DOMAIN),
                            string(name: 'DNS_IP', value: publicIp)
                        ]

                        // Notify Discord about the update
                        notifyDiscord("⚠️ DNS Record Change Detected: ${DNS_DOMAIN} being routed to ${publicIp}")
                    }
                }
            }
        }
    }
}

// Function to notify Discord
def notifyDiscord(message) {
    build job: 'notify-discord', parameters: [
        string(name: 'DISCORD_MESSAGE', value: message)
    ]
}
```

I've configured the above job to run every hour on the hour with a cron schedule `0 * * * *`. To test this out, I've set 
the DNS record to `127.0.0.1` and then executed the job. Here's the truncated output from the Jenkins console:

```text
🔹 Checking DNS record for minecraft.johnsosoka.com...
[Pipeline] sh
+ dig +short minecraft.johnsosoka.com
+ head -n 1
[Pipeline] sh
+ curl -s https://api.johnsosoka.com/v1/ip/my
+ jq -r .ip
[Pipeline] echo
🔹 Current DNS IP: 127.0.0.1
[Pipeline] echo
🔹 Public IP from API: 24.117.184.224
[Pipeline] echo
⚠️ DNS record is outdated. Updating to 24.117.184.224...
[Pipeline] build (Building update-jscom-dns)
Scheduling project: update-jscom-dns
Starting building: update-jscom-dns #15
Build update-jscom-dns #15 completed: SUCCESS
[Pipeline] build (Building notify-discord)
Scheduling project: notify-discord
Starting building: notify-discord #24
Build notify-discord #24 completed: SUCCESS
```

The job successfully detected that the DNS record was outdated and triggered the Update DNS job. The Update DNS job then
successfully updated the DNS record in Route53 and posted a message to my Discord server!

## Conclusion

This was a fun weekend project that I've been wanting to do for a while, and I'm glad I finally got around to it. I'll 
be able to re-use much of this infrastructure for other self-hosted services in the future. I may eventually restrict
which domains can be updated by the Lambda function, but for now, I'm keeping it simple as nothing I host is mission-critical. 
Another future improvement will be to host the pipeline DSL in a Jenkinsfile in the GitHub repository for this project, 
instead of directly in the Jenkins job configuration.

Hopefully this post has been helpful to you, and if you have any questions or suggestions, feel free to reach out via the
[contact form](https://www.johnsosoka.com/contact/).

The full code for this project, including the Terraform, can be found on [GitHub](https://github.com/johnsosoka/jscom-mini-services/tree/main)