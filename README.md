# Cloud Native Architecture Course - Introspect 1B: EKS Dapr Microservices

[![1. Start Lab](https://github.com/matei-tm/introspect1B/actions/workflows/start-lab.yml/badge.svg?branch=develop)](https://github.com/matei-tm/introspect1B/actions/workflows/start-lab.yml)
[![2. Deploy Terraform](https://github.com/matei-tm/introspect1B/actions/workflows/terraform-deploy.yml/badge.svg?branch=develop)](https://github.com/matei-tm/introspect1B/actions/workflows/terraform-deploy.yml)
[![3. Deploy Services](https://github.com/matei-tm/introspect1B/actions/workflows/deploy-services.yml/badge.svg?branch=develop)](https://github.com/matei-tm/introspect1B/actions/workflows/deploy-services.yml)
[![4. Test and Logs](https://github.com/matei-tm/introspect1B/actions/workflows/test-and-logs.yml/badge.svg?branch=develop)](https://github.com/matei-tm/introspect1B/actions/workflows/test-and-logs.yml)

- [Cloud Native Architecture Course - Introspect 1B: EKS Dapr Microservices](#cloud-native-architecture-course---introspect-1b-eks-dapr-microservices)
  - [⚡ TL;DR - Quick Start](#-tldr---quick-start)
  - [📚 Wiki](#-wiki)
  - [📝 License](#-license)
  - [🤝 Contributing](#-contributing)


A complete demonstration of containerized microservices deployed on Amazon EKS with Dapr sidecars implementing pub/sub messaging patterns using AWS SNS/SQS for real-time event-driven interactions.

This project is part of the [CTS - Architecting for Performance CNA Level 2 – Intermediate (GGM)](https://www.niit.com/) course.

## ⚡ TL;DR - Quick Start

**Get up and running in minutes using GitHub Actions automation!**

1. **Fork this repository** to your GitHub account

2. **Configure GitHub Secrets** (Settings → Secrets and variables → Actions → New repository secret):
   ```
   AWS_ACCESS_KEY_ID       = <your-aws-access-key>
   AWS_SECRET_ACCESS_KEY   = <your-aws-secret-key>
   ECR_REGISTRY            = <mandatory: your-account-id.dkr.ecr.region.amazonaws.com>
   SITE_USER               = <your-lab-username>
   SITE_PASSWORD           = <your-lab-password>
   ```

3. **Run the workflows** (Actions tab):
   **Available GitHub Actions workflows:**

   <img src="docs/media/workflow-list.png" alt="GitHub Actions Workflows" width="200" />

   - **Step**: `1. Start Lab` - Initialize lab environment with Playwright automation (~2 min)
   - **Step**: `2. Deploy Terraform Infrastructure` - Provisions EKS, VPC, ECR, SNS/SQS, DynamoDB (~15 min)
   - **Step**: `3. Build and Deploy Microservices` - Builds and deploys services (~5 min)
   - **Step**: `4. Test and Collect Logs` - Comprehensive testing and log collection (~2 min)
   - **Verify**: Downloads logs as artifact (30-day retention) with detailed test results and service logs

That's it! Your microservices are now running on EKS with Dapr pub/sub messaging. 🚀

   <img src="docs/media/workflows-runs.png" alt="GitHub Actions Runs" width="600" />

## 📚 Wiki

For detailed setup, local development, and troubleshooting, continue reading the [wiki](https://github.com/matei-tm/introspect1B/wiki).

   <img src="docs/media/wiki.png" alt="Wiki page" width="600" />

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

This project is for educational purposes as part of the [CTS - Architecting for Performance CNA Level 2 – Intermediate (GGM)](https://www.niit.com/) course.

## 🤝 Contributing

Feel free to submit issues or pull requests for improvements!