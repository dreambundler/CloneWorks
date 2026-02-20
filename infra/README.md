# Infrastructure

CloneWorks infrastructure configuration and deployment layout.

## Structure

infra/
├── docker/        # Dockerfiles for API and workers
├── runpod/        # RunPod templates and GPU configs
├── scripts/       # Deployment & helper scripts
├── env/           # Environment templates (no secrets)
└── README.md

## Purpose

This folder defines how CloneWorks services are:

- Containerized
- Deployed
- Scaled
- Configured across environments

No secrets should be stored here.
