# UMKM AI Application for Deployment

A bundled UMKM AI application for deployment combining umkm-chatbot and umkm-website. Deployed App: [Obex Customlamp Web] (https://obexcustomlamp.biz.id) 

## Key Features
- RASA config management (datasets, intents, stories)
- One-click retraining
- Automated Docker deployment
- Modular architecture (backend + frontend separation)
- Production-ready with docker-compose

## Prerequisites
- Docker & docker-compose
- Node.js
- Git
- S3 Bucket for storage
- MySQL Server for data persistence

## Setup & Usage
```bash
git clone https://github.com/AisAif/umkm-ai.git
cd umkm-ai
./start.sh
./stop.sh