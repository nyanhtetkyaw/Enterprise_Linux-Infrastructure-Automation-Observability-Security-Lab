# Enterprise Linux Infrastructure Automation, Observability & Security Lab

A hands-on enterprise-style infrastructure lab built on **RHEL 9.8** using **Terraform, Ansible, Podman, Vault, Checkov, Jenkins HAProxy, Caddy, Prometheus, Grafana, Loki, Grafana Alloy, k6, and OpenSCAP**.

The project demonstrates how I design, provision, operate, monitor, test, and validate a production-style Linux infrastructure environment using Infrastructure as Code, configuration automation, observability, security controls, and compliance validation.

# Terraform + Podman + Ansible + Checkov DevSecOps Lab

## Project Overview

This project is a local enterprise-style infrastructure and DevSecOps laboratory built on **RHEL 9** using **Terraform, Podman, Ansible, and Checkov**.

The goal is to simulate a production-like Linux platform where infrastructure, application services, monitoring, CI/CD, security tooling, and configuration management are deployed through Infrastructure as Code and automation.

Terraform is used to provision and manage the Podman infrastructure, including isolated networks, application containers, management services, monitoring components, and database services.

Ansible is used for supporting operating-system and infrastructure automation, while **Checkov** is integrated as a security and Infrastructure-as-Code scanning tool to identify potential security and compliance issues in Terraform and Ansible configurations before deployment.

---

# Project Goals

The primary goals of this project are:

* Build an enterprise-style container platform using Podman on RHEL 9.
* Manage Podman infrastructure using Terraform.
* Separate workloads using multiple Podman bridge networks.
* Automate Linux configuration and supporting tasks using Ansible.
* Implement monitoring, logging, metrics, and alerting.
* Deploy CI/CD and code-quality tooling.
* Demonstrate infrastructure-as-code practices.
* Introduce security scanning into the infrastructure deployment workflow.
* Use Checkov to scan Terraform and Ansible configuration before deployment.
* Practice DevSecOps principles by identifying security issues early in the development lifecycle.
* Create a reusable platform that can be extended with additional applications and services.

---

# Architecture

The platform is divided into several logical layers.

```text
                         ┌─────────────────────────┐
                         │       Developer/User    │
                         │        / Internet       │
                         └────────────┬────────────┘
                                      │
                                      ▼
                         ┌─────────────────────────┐
                         │       DMZ Network       │
                         │                         │
                         │       HAProxy           │
                         │     Load Balancer       │
                         └────────────┬────────────┘
                                      │
                         ┌────────────┴────────────┐
                         │                         │
                         ▼                         ▼
              ┌──────────────────┐      ┌──────────────────┐
              │ Application Net  │      │ Application Net  │
              │                  │      │                  │
              │   HTTPD App 1    │      │   HTTPD App 2    │
              │   Port 8081      │      │   Port 8082      │
              └─────────┬────────┘      └─────────┬────────┘
                        │                         │
                        └────────────┬────────────┘
                                     │
                                     ▼
                         ┌─────────────────────────┐
                         │     Database Network    │
                         │                         │
                         │      PostgreSQL         │
                         │        Database         │
                         └─────────────────────────┘


       ┌─────────────────────────────────────────────────────────┐
       │                  Management Network                     │
       │                                                         │
       │  Vault       Jenkins       SonarQube       Prometheus   │
       │                                                         │
       │  Grafana     Loki          Alloy            Alertmanager│
       │                                                         │
       │  Node Exporter             Blackbox Exporter            │
       └─────────────────────────────────────────────────────────┘


                         ┌─────────────────────────┐
                         │      Podman Engine      │
                         │   RHEL 9 Host System    │
                         └─────────────────────────┘
```
---

# Workflow diagram

<img width="1312" height="1199" alt="62AFCE61-B6D2-4B9B-B5B3-0153B48EB6E3" src="https://github.com/user-attachments/assets/66ba419a-39fc-48fc-bfce-2fc6cf368c05" />


---

# Demostration Video

https://youtu.be/yvEcMKfHfC8

---

# Network Segmentation

The project uses separate Podman bridge networks to provide logical segmentation between workloads.

| Network           | Purpose                                              |
| ----------------- | ---------------------------------------------------- |
| `lab-dmz`         | External-facing/load-balancer services               |
| `lab-application` | Application workloads                                |
| `lab-database`    | Database workloads                                   |
| `lab-management`  | Management, monitoring, CI/CD, and security services |

Terraform defines these networks as separate Podman bridge networks.

This approach allows services to communicate only through the networks they are attached to instead of placing every container on a single flat network.

---

# Container Services

## HAProxy

HAProxy acts as the load-balancing layer between the DMZ and application containers.

```text
HAProxy
 ├── DMZ Network
 └── Application Network
```

It exposes:

```text
8080 → HTTP
8404 → HAProxy statistics
```

The HAProxy configuration is mounted from the Ansible files directory.

---

## HTTPD Application Servers

Two Apache HTTPD application containers are deployed:

```text
httpd-app-1
httpd-app-2
```

Terraform uses:

```hcl
count = 2
```

to create the two application instances. Each instance receives its own external port:

```text
httpd-app-1 → 8081
httpd-app-2 → 8082
```

Both application containers are attached to the application and database networks.

---

# Management Platform

The management network contains several operational services.

## HashiCorp Vault

Vault provides a centralized secrets-management component for the lab.

```text
Vault
Port: 8200
```

Persistent data and configuration are mounted from the host.

---

## Jenkins

Jenkins provides the CI/CD component of the platform.

```text
Jenkins
 ├── Port 8088 → 8080
 └── Port 50000 → 50000
```

The Jenkins home directory is persisted on the host.

The container also has access to the Podman socket, allowing Jenkins to interact with the Podman engine.

> **Security consideration:** Access to the Podman socket can provide significant control over the host's containers. In a production environment, this should be carefully restricted and evaluated.

---

## SonarQube

SonarQube provides code-quality analysis.

```text
SonarQube
Port: 9000
```

Persistent directories are used for:

```text
data
extensions
logs
```

---

# Monitoring and Observability

The platform includes a complete monitoring and observability stack.

```text
                    ┌───────────────┐
                    │   Prometheus  │
                    └───────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
        Node Exporter   cAdvisor     Blackbox
              │             │             │
              └─────────────┼─────────────┘
                            │
                            ▼
                       Prometheus
                            │
                            ▼
                         Grafana
```

Additional logging components include:

```text
Grafana Alloy
      │
      ▼
     Loki
```

Alerting is provided through:

```text
Alertmanager
```

## The Terraform configuration defines Prometheus, Grafana, cAdvisor, Blackbox Exporter, Loki, Node Exporter, Alloy, and Alertmanager containers.

# Load Testing

The project includes **k6** for application and performance testing.

The k6 container is connected to the application network and mounts test scripts from:

```text
ansible/files/k6
```

The container remains running with:

```text
sleep infinity
```

so tests can be executed interactively or through automation.

---

# Terraform

Terraform is responsible for provisioning the Podman infrastructure.

The Terraform configuration uses:

```text
Terraform
    │
    ▼
Podman Provider
    │
    ├── Networks
    ├── Containers
    ├── Volumes
    ├── Port mappings
    └── Dependencies
```

The project uses:

```text
blechschmidt/podman
hashicorp/null
```

providers.

The Podman provider communicates with:

```text
unix:///run/podman/podman.sock
```

---

# Ansible Integration

Ansible is used for supporting configuration and operational automation.

The project includes Ansible-managed configuration files for services such as:

```text
HAProxy
Caddy
Prometheus
Vault
Loki
Alloy
Alertmanager
Blackbox Exporter
k6
```

Terraform also invokes an Ansible playbook for Loki storage preparation:

```text
ansible/files/loki_storage.yml
```

through a Terraform `null_resource`.

This demonstrates a hybrid automation workflow:

```text
Terraform
   │
   ├── Infrastructure provisioning
   │
   └── invokes
          │
          ▼
       Ansible
          │
          ▼
 Configuration / OS automation
```

---

# Checkov Security Scanning

## Overview

**Checkov** is installed on the RHEL 9 host and is used to scan Infrastructure-as-Code configurations before deployment.

The objective is to identify potential security, compliance, and configuration issues early in the development lifecycle.

The scanning workflow is:

```text
Developer
    │
    ▼
Terraform / Ansible Files
    │
    ▼
   Checkov
    │
    ├── Terraform Scan
    │
    └── Ansible Scan
    │
    ▼
Security Findings
    │
    ├── Fix
    ├── Document exception
    └── Re-scan
    │
    ▼
Terraform / Ansible Deployment
```

---

# Scan Terraform

From the project root:

```bash
checkov -d .
```

To specifically scan Terraform:

```bash
checkov -d . --framework terraform
```

For a Terraform directory:

```bash
checkov -d terraform/
```

The objective is to detect issues before:

```bash
terraform plan
terraform apply
```

---

# Scan Ansible

Ansible configuration can also be scanned with Checkov:

```bash
checkov -d ansible/ --framework ansible
```

You can also scan the complete repository:

```bash
checkov -d .
```

This allows the security scan to cover both Infrastructure-as-Code and configuration-management files.

---

# Example DevSecOps Workflow

A recommended workflow for this project is:

```text
                    Git Repository
                          │
                          ▼
                 ┌─────────────────┐
                 │     Checkov     │
                 │                 │
                 │ Terraform Scan  │
                 │ Ansible Scan    │
                 └────────┬────────┘
                          │
                    PASS / FAIL
                          │
              ┌───────────┴───────────┐
              │                       │
             FAIL                   PASS
              │                       │
              ▼                       ▼
        Fix Configuration       Terraform Plan
                                      │
                                      ▼
                               Review Changes
                                      │
                                      ▼
                               Terraform Apply
                                      │
                                      ▼
                               Podman Platform
```

---

# Security Considerations

This project is a laboratory environment, but several areas should be addressed before using the configuration in production.

## Secrets

The current Terraform configuration contains a PostgreSQL password directly in the container environment configuration:

```text
POSTGRES_PASSWORD=ChangeMe-LabOnly-2026
```

For production, this should be replaced with a secure secrets-management approach, such as Vault or another approved enterprise secrets platform.

## Container Images

Several services use `latest` image tags.

For production deployments, image versions should preferably be pinned to known versions or immutable image references and regularly updated through a controlled process.

## Privileged Containers

The cAdvisor container is configured with:

```text
privileged = true
```

and has several host filesystem mounts.

This should be carefully reviewed because privileged containers and host filesystem access increase the security impact of a container compromise.

## Podman Socket

Jenkins mounts:

```text
/run/podman/podman.sock
```

into the container.

Access to the Podman socket should be treated as highly privileged and controlled appropriately.

---

# Project Directory

A simplified project structure is:

```text
terraform-local/
│
├── main.tf
├── networks.tf
├── variables.tf
│
├── ansible/
│   └── files/
│       ├── haproxy.cfg
│       ├── Caddyfile
│       ├── index.html
│       ├── index1.html
│       ├── vault/
│       ├── prometheus/
│       ├── blackbox/
│       ├── loki/
│       ├── alloy/
│       ├── alertmanager/
│       ├── k6/
│       └── loki_storage.yml
│
├── vault/
│   └── data/
│
├── jenkins/
│   └── data/
│
├── sonarqube/
│   ├── data/
│   ├── extensions/
│   └── logs/
│
└── postgresql/
    └── data/
```

---

# Deployment

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Format Terraform files:

```bash
terraform fmt -recursive
```

Run Checkov:

```bash
checkov -d .
```

Review the Terraform plan:

```bash
terraform plan
```

Deploy:

```bash
terraform apply
```

---

# Verification

Verify the Podman containers:

```bash
podman ps
```

Verify networks:

```bash
podman network ls
```

Inspect a network:

```bash
podman network inspect lab-management
```

Verify Terraform state:

```bash
terraform show
```

Verify the Terraform configuration:

```bash
terraform validate
```

---

# Skills Demonstrated

This project demonstrates practical experience with:

* RHEL 9
* Linux system administration
* Podman
* Container networking
* Terraform
* Infrastructure as Code
* Ansible
* Configuration management
* DevSecOps
* Checkov
* CI/CD
* Jenkins
* SonarQube
* HashiCorp Vault
* HAProxy
* PostgreSQL
* Prometheus
* Grafana
* Loki
* Grafana Alloy
* Alertmanager
* Node Exporter
* cAdvisor
* Blackbox Exporter
* k6
* Security hardening
* Infrastructure monitoring
* Logging and observability
* Secrets management concepts
* Automated security validation

---

# DevSecOps Lifecycle

The overall architecture can be summarized as:

```text
┌─────────────────────────────────────────────────────────────┐
│                    SOURCE CONTROL                           │
│                                                             │
│       Terraform + Ansible + Configuration Files             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     SECURITY SCAN                           │
│                                                             │
│               Checkov - Terraform + Ansible                 │
└───────────────────────────┬─────────────────────────────────┘
                            │
                       Security Pass
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  INFRASTRUCTURE AS CODE                     │
│                                                             │
│                       Terraform                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       PODMAN                                │
│                                                             │
│       DMZ │ Application │ Database │ Management             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION PLATFORM                     │
│                                                             │
│ HAProxy │ HTTPD │ PostgreSQL │ Jenkins │ Vault │ SonarQube  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  OBSERVABILITY                              │
│                                                             │
│ Prometheus │ Grafana │ Loki │ Alloy │ Alertmanager          │
│ Node Exporter │ cAdvisor │ Blackbox Exporter                │
└─────────────────────────────────────────────────────────────┘
```

## Summary

This project demonstrates how **Terraform, Podman, Ansible, and Checkov can work together to build a repeatable and security-conscious Linux platform**.

Terraform provides infrastructure provisioning, Podman provides the container runtime, Ansible provides configuration and operational automation, and Checkov provides Infrastructure-as-Code security validation.

The resulting workflow follows a DevSecOps model:

**Code → Scan → Validate → Plan → Deploy → Monitor → Remediate → Repeat**



Happy learning! :)
